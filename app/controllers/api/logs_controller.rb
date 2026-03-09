class Api::LogsController < ApplicationController
  def index
    timeline = params[:timeline].presence || "2120s"
    timelines = HackrLog.published.timelines_summary

    logs = HackrLog.published.for_timeline(timeline).includes(:grid_hackr)

    sort_dir = (params[:sort] == "asc") ? :asc : :desc
    logs = logs.order(published_at: sort_dir, created_at: sort_dir)

    # Pagination
    page = [params[:page].to_i, 1].max
    per_page = params[:per_page].to_i.clamp(5, 50)

    total = logs.count
    @hackr_logs = logs.limit(per_page).offset((page - 1) * per_page)

    render json: {
      logs: @hackr_logs.map { |log|
        {
          id: log.id,
          title: log.title,
          slug: log.slug,
          body: log.body,
          timeline: log.timeline,
          published_at: log.published_at,
          created_at: log.created_at,
          author: {
            id: log.grid_hackr.id,
            hackr_alias: log.grid_hackr.hackr_alias
          }
        }
      },
      meta: {
        timelines: timelines,
        timeline: timeline,
        total: total,
        page: page,
        per_page: per_page,
        total_pages: (total.to_f / per_page).ceil
      }
    }
  end

  def show
    @hackr_log = HackrLog.published.find_by!(slug: params[:id])

    render json: {
      id: @hackr_log.id,
      title: @hackr_log.title,
      slug: @hackr_log.slug,
      body: @hackr_log.body,
      timeline: @hackr_log.timeline,
      published_at: @hackr_log.published_at,
      created_at: @hackr_log.created_at,
      author: {
        id: @hackr_log.grid_hackr.id,
        hackr_alias: @hackr_log.grid_hackr.hackr_alias
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Log not found or not yet published."}, status: :not_found
  end
end
