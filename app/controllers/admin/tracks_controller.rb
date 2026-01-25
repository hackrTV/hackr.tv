# Read-only controller - Tracks are managed via YAML files
# Edit data/catalog/tracks.yml and run: rails data:tracks
class Admin::TracksController < Admin::ApplicationController
  def index
    @tracks = Track.includes(:artist, :album).ordered
  end
end
