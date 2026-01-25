# Read-only controller - Artists are managed via YAML files
# Edit data/catalog/artists.yml and run: rails data:artists
class Admin::ArtistsController < Admin::ApplicationController
  def index
    @artists = Artist.order(:name).includes(:tracks)
  end
end
