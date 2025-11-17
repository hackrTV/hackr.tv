class Admin::DashboardController < Admin::ApplicationController
  def index
    @stats = {
      artists_count: Artist.count,
      tracks_count: Track.count,
      hackr_logs_count: HackrLog.count,
      radio_stations_count: RadioStation.count,
      online_hackrs_count: GridHackr.online.count
    }

    @recent_tracks = Track.includes(:artist).ordered.limit(5)
    @recent_logs = HackrLog.includes(:author).ordered.limit(5)
    @online_hackrs = GridHackr.online.includes(:current_room).limit(10)
    @recent_messages = GridMessage.order(created_at: :desc).includes(:grid_hackr).limit(10)
  end
end
