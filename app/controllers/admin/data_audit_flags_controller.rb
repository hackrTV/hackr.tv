# frozen_string_literal: true

class Admin::DataAuditFlagsController < Admin::ApplicationController
  PER_PAGE = 50

  before_action :set_flag, only: %i[acknowledge reopen]

  # GET /root/data_audit_flags
  def index
    @flags = DataAuditFlag.newest_first

    # Filters
    if params[:status].present? && DataAuditFlag::STATUSES.include?(params[:status])
      @flags = @flags.where(status: params[:status])
    end
    @flags = @flags.for_severity(params[:severity])
    @flags = @flags.for_domain(params[:domain])
    @flags = @flags.for_check(params[:check_name])

    if params[:search].present?
      escaped = ActiveRecord::Base.sanitize_sql_like(params[:search])
      @flags = @flags.where("title LIKE ?", "%#{escaped}%")
    end

    # Summary counts (before pagination)
    @by_severity = DataAuditFlag.effective_open.group(:severity).count
    @by_domain = DataAuditFlag.effective_open.group(:domain).count
    @check_names = DataAuditFlag.distinct.pluck(:check_name).sort

    # Pagination
    @per_page = PER_PAGE
    @offset = [params[:offset].to_i, 0].max
    @total_count = @flags.count
    @flags = @flags.offset(@offset).limit(@per_page)

    # Batch-preload slugs for models that use slug-based to_param (avoids N+1)
    @subject_slugs = preload_subject_slugs(@flags)

    @last_scan_at = DataAudit::FlagCache.last_scan_at
  end

  # POST /root/data_audit_flags/:id/acknowledge
  def acknowledge
    duration = params[:duration].to_s
    until_time = case duration
    when "24h" then 24.hours.from_now
    when "7d" then 7.days.from_now
    when "30d" then 30.days.from_now
    when "forever" then nil
    else 24.hours.from_now
    end

    @flag.acknowledge!(until_time)
    DataAudit::FlagCache.invalidate!
    label = until_time ? "until #{until_time.strftime("%Y-%m-%d %H:%M")}" : "permanently"
    set_flash_success "Flag acknowledged #{label}."
    redirect_to admin_data_audit_flags_path
  end

  # POST /root/data_audit_flags/:id/reopen
  def reopen
    @flag.reopen!
    DataAudit::FlagCache.invalidate!
    set_flash_success "Flag reopened."
    redirect_to admin_data_audit_flags_path
  end

  # POST /root/data_audit_flags/scan
  def scan
    DataAudit::ScanJob.perform_later
    set_flash_success "Audit scan enqueued. Results will appear shortly."
    redirect_to admin_data_audit_flags_path
  end

  private

  def set_flag
    @flag = DataAuditFlag.find(params[:id])
  end

  # Build an admin edit path for the flagged subject record.
  # Some models override to_param to return slug instead of ID,
  # so we batch-preload slugs to avoid N+1 queries.
  SUBJECT_ROUTE_MAP = {
    "GridRoom" => :edit_admin_grid_room_path,
    "GridZone" => :edit_admin_grid_zone_path,
    "GridRegion" => :edit_admin_grid_region_path,
    "GridMission" => :edit_admin_grid_mission_path,
    "GridMob" => :edit_admin_grid_mob_path,
    "GridSchematic" => :edit_admin_grid_schematic_path,
    "GridBreachTemplate" => :edit_admin_grid_breach_template_path,
    "GridBreachEncounter" => :edit_admin_grid_breach_encounter_path,
    "Release" => :edit_admin_release_path,
    "Track" => :edit_admin_track_path
  }.freeze

  # Models that use slug-based to_param — need slug lookup instead of raw ID.
  SLUG_PARAM_TYPES = %w[GridMission GridSchematic GridBreachTemplate Release Track].to_set.freeze

  helper_method :admin_subject_path

  def admin_subject_path(subject_type, subject_id)
    route = SUBJECT_ROUTE_MAP[subject_type]
    return nil unless route

    param = if SLUG_PARAM_TYPES.include?(subject_type)
      @subject_slugs&.dig(subject_type, subject_id)
    else
      subject_id
    end

    param ? send(route, param) : nil
  rescue ActionController::UrlGenerationError
    nil
  end

  # Batch-load slugs for all slug-based subject types on the current page.
  # One query per type that appears, instead of one per flag row.
  def preload_subject_slugs(flags)
    slugs = {}
    flags.select { |f| SLUG_PARAM_TYPES.include?(f.subject_type) }
      .group_by(&:subject_type)
      .each do |type, type_flags|
        ids = type_flags.map(&:subject_id).compact
        next if ids.empty?
        klass = type.constantize
        slugs[type] = klass.where(id: ids).pluck(:id, :slug).to_h
      rescue NameError
        # Model class not found — skip
      end
    slugs
  end
end
