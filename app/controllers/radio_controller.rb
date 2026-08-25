# hackr.fm Radio (Hotwire, Phase 4) — replaces RadioPage.tsx.
class RadioController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  def show
    @stations = RadioStation.visible.ordered.includes(playlists: :playlist_tracks)
    @live_stream = HackrStream.includes(:artist).current_live
  end
end
