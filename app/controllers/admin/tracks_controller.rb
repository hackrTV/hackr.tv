# Read-only controller - Tracks are managed via YAML files
# Edit data/catalog/{artist_slug}.yml and run: rails data:catalog
class Admin::TracksController < Admin::ApplicationController
  def index
    @tracks = Track.includes(:artist, :release).ordered
  end
end
