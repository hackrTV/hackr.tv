# Read-only controller - HackrLogs are managed via YAML files
# Edit data/content/hackr_logs.yml and run: rails data:hackr_logs
class Admin::HackrLogsController < Admin::ApplicationController
  def index
    @hackr_logs = HackrLog.includes(:grid_hackr).ordered
  end
end
