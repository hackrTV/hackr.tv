# Read-only controller - Zone playlists are managed via YAML files
# Edit data/system/zone_playlists.yml and run: rails data:zone_playlists
class Admin::ZonePlaylistsController < Admin::ApplicationController
  def index
    @zone_playlists = ZonePlaylist.includes(:zone_playlist_tracks, :tracks).order(:name)
  end

  def show
    @zone_playlist = ZonePlaylist.find(params[:id])
    @tracks = @zone_playlist.ordered_tracks.includes(:artist, :release)
  end
end
