# Read-only controller - Artists are managed via YAML files
# Edit data/catalog/{artist_slug}.yml and run: rails data:catalog
class Admin::ArtistsController < Admin::ApplicationController
  def index
    @artists = Artist.order(:name).includes(:tracks)
  end
end
