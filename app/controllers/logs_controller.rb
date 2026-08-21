# Server-rendered Hackr Logs (Hotwire migration Phase 1) — ports
# LogsIndexPage.tsx + LogDetailPage.tsx. The JSON API (Api::LogsController)
# stays untouched for any remaining consumers until Phase 7.
class LogsController < ApplicationController
  layout "hotwire"

  TIMELINE_ORDER = %w[2120s pre_fracture govcorp_files 2020s].freeze
  TIMELINE_CONFIG = {
    "2120s" => {name: "THE FRACTURE NETWORK", subtitle: "Transmissions from the Fracture Network"},
    "pre_fracture" => {name: "PRE-FRACTURE", subtitle: "Before the Chronology Fracture"},
    "govcorp_files" => {name: "GOVCORP FILES", subtitle: "Intercepted GovCorp communications"},
    "2020s" => {name: "THE LISTENERS", subtitle: "Signals received in the present day"}
  }.freeze

  def index
    @timeline = params[:timeline].presence || "2120s"
    @timelines = HackrLog.published.timelines_summary
    @sort = (params[:sort] == "asc") ? "asc" : "desc"
    @config = TIMELINE_CONFIG[@timeline] || TIMELINE_CONFIG["2120s"]

    logs = HackrLog.published.for_timeline(@timeline).includes(:grid_hackr)
      .order(published_at: @sort.to_sym, created_at: @sort.to_sym)

    # Same pagination defaults as the API (per_page 0.clamp(5,50) → 5)
    @page = [params[:page].to_i, 1].max
    @per_page = params[:per_page].to_i.clamp(5, 50)
    total = logs.count
    @total_pages = (total.to_f / @per_page).ceil
    @logs = logs.limit(@per_page).offset((@page - 1) * @per_page)
  end

  def show
    @log = HackrLog.published.includes(:grid_hackr).find_by(slug: params[:id])
    @sort = (params[:sort] == "asc") ? "asc" : "desc"

    unless @log
      render :not_found, status: :not_found
      return
    end

    @timelines = HackrLog.published.timelines_summary

    # Read credit inline (the SPA fired POST /api/logs/:id/read after mount)
    if current_hackr
      HackrLogRead.record!(current_hackr, @log)
      checker = Grid::AchievementChecker.new(current_hackr)
      checker.check("hackr_logs_read")
      checker.check("hackr_logs_read_all")
    end
  end
end
