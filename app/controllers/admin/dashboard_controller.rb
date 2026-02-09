class Admin::DashboardController < Admin::ApplicationController
  def index
    @stats = {
      artists_count: Artist.count,
      total_emails_sent: SentEmail.count,
      tracks_count: Track.count,
      hackr_logs_count: HackrLog.count,
      codex_entries_count: CodexEntry.count,
      online_hackrs_count: GridHackr.online.count,
      emails_sent_24h: emails_sent_last_24_hours,
      emails_sent_30d: emails_sent_last_30_days
    }

    @recent_tracks = Track.includes(:artist).ordered.limit(5)
    @recent_logs = HackrLog.includes(:grid_hackr).ordered.limit(5)
    @online_hackrs = GridHackr.online.includes(:current_room).limit(10)
    @recent_messages = GridMessage.order(created_at: :desc).includes(:grid_hackr).limit(10)
  end

  private

  def emails_sent_last_24_hours
    SentEmail.where("created_at >= ?", 24.hours.ago).count
  end

  def emails_sent_last_30_days
    SentEmail.where("created_at >= ?", 30.days.ago).count
  end
end
