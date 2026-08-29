# Public shared playlist page (Hotwire, Phase 4) — replaces
# SharedPlaylistPage.tsx. Same visibility rule as the API: token match AND
# is_public.
class SharedPlaylistsController < ApplicationController
  layout "hotwire"

  def show
    @playlist = Playlist.find_by(share_token: params[:token], is_public: true)
    return render :not_found, status: :not_found unless @playlist

    @tracks = @playlist.playlist_tracks.includes(track: [:artist, :release]).order(position: :asc)
  end
end
