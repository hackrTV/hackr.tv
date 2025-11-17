class Api::LogsController < ApplicationController
  def index
    @hackr_logs = HackrLog.published.ordered.includes(:author)

    render json: @hackr_logs.map { |log|
      {
        id: log.id,
        title: log.title,
        slug: log.slug,
        body: log.body,
        published_at: log.published_at,
        created_at: log.created_at,
        author: {
          id: log.author.id,
          hackr_alias: log.author.hackr_alias
        }
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
      published_at: @hackr_log.published_at,
      created_at: @hackr_log.created_at,
      author: {
        id: @hackr_log.author.id,
        hackr_alias: @hackr_log.author.hackr_alias
      }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {error: "Log not found or not yet published."}, status: :not_found
  end
end
