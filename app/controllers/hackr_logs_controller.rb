class HackrLogsController < ApplicationController
  def index
    @hackr_logs = HackrLog.published.ordered.includes(:author)
  end

  def show
    @hackr_log = HackrLog.published.find_by!(slug: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to hackr_logs_path, alert: "Log not found or not yet published."
  end
end
