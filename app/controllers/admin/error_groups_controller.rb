# frozen_string_literal: true

class Admin::ErrorGroupsController < Admin::ApplicationController
  PER_PAGE = 50

  before_action :set_error_group, only: %i[show resolve ignore reopen]

  # GET /root/error_groups
  def index
    @error_groups = ErrorGroup.newest_first

    # Filters
    if params[:status].present? && ErrorGroup::STATUSES.include?(params[:status])
      @error_groups = @error_groups.where(status: params[:status])
    end
    @error_groups = @error_groups.for_component(params[:component])
    @error_groups = @error_groups.for_severity(params[:severity])

    if params[:search].present?
      escaped = ActiveRecord::Base.sanitize_sql_like(params[:search])
      @error_groups = @error_groups.where("title LIKE ?", "%#{escaped}%")
    end

    # Pagination
    @per_page = PER_PAGE
    @offset = [params[:offset].to_i, 0].max
    @total_count = @error_groups.count
    @error_groups = @error_groups.offset(@offset).limit(@per_page)

    # Trend data: occurrence counts in last 24h for displayed groups
    group_ids = @error_groups.map(&:id)
    @trends_24h = ErrorOccurrence
      .where(error_group_id: group_ids)
      .where("occurred_at >= ?", 24.hours.ago)
      .group(:error_group_id)
      .count
  end

  # GET /root/error_groups/:id
  def show
    @per_page = 50
    @offset = [params[:offset].to_i, 0].max
    @occurrences = @error_group.error_occurrences.newest_first
    @total_occurrences = @occurrences.count
    @occurrences = @occurrences.offset(@offset).limit(@per_page)
  end

  # POST /root/error_groups/:id/resolve
  def resolve
    @error_group.resolve!(current_hackr)
    set_flash_success "Error group resolved."
    redirect_to admin_error_groups_path
  end

  # POST /root/error_groups/:id/ignore
  def ignore
    duration = params[:duration].to_s
    until_time = case duration
    when "1h" then 1.hour.from_now
    when "24h" then 24.hours.from_now
    when "7d" then 7.days.from_now
    when "30d" then 30.days.from_now
    when "forever" then nil
    else 24.hours.from_now
    end

    @error_group.ignore!(until_time)
    label = until_time ? "until #{until_time.strftime("%Y-%m-%d %H:%M")}" : "permanently"
    set_flash_success "Error group ignored #{label}."
    redirect_to admin_error_groups_path
  end

  # POST /root/error_groups/:id/reopen
  def reopen
    @error_group.reopen!
    set_flash_success "Error group reopened."
    redirect_to admin_error_groups_path
  end

  private

  def set_error_group
    @error_group = ErrorGroup.find(params[:id])
  end
end
