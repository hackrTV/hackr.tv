# frozen_string_literal: true

class Admin::ErrorGroupsController < Admin::ApplicationController
  PER_PAGE = 50

  before_action :set_error_group, only: %i[show resolve ignore reopen]

  # GET /root/error_groups
  def index
    @error_groups = ErrorGroup.newest_first

    # Filters
    @status = params[:status].to_s.presence_in(ErrorGroup::STATUSES).to_s
    @component = params[:component].to_s.presence_in(ErrorGroup::COMPONENTS).to_s
    @severity = params[:severity].to_s.presence_in(ErrorGroup::SEVERITIES).to_s
    @error_groups = @error_groups.where(status: @status) if @status.present?
    @error_groups = @error_groups.for_component(@component)
    @error_groups = @error_groups.for_severity(@severity)

    @search = params[:search].is_a?(String) ? params[:search] : ""
    if @search.present?
      escaped = ActiveRecord::Base.sanitize_sql_like(@search)
      @error_groups = @error_groups.where("title LIKE ?", "%#{escaped}%")
    end

    # Pagination (the offset clamped to the last page: an action's redirect_back keeps the page it was pressed on)
    @per_page = PER_PAGE
    @total_count = @error_groups.count
    @offset = params[:offset].to_i.clamp(0, [@total_count - 1, 0].max / @per_page * @per_page)
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
    @occurrences = @occurrences.offset(@offset).limit(@per_page).load
  end

  # POST /root/error_groups/:id/resolve
  def resolve
    @error_group.resolve!(current_hackr)
    set_flash_success "Error group resolved."
    redirect_back_or_to admin_error_groups_path
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
    redirect_back_or_to admin_error_groups_path
  end

  # POST /root/error_groups/:id/reopen
  def reopen
    @error_group.reopen!
    set_flash_success "Error group reopened."
    redirect_back_or_to admin_error_groups_path
  end

  private

  def set_error_group
    @error_group = ErrorGroup.find(params[:id])
  end
end
