# Read-only controller - Releases are managed via YAML files
# Edit data/catalog/{artist_slug}.yml and run: rails data:catalog
class Admin::ReleasesController < Admin::ApplicationController
  def index
    @releases = Release.includes(:artist, :tracks, cover_image_attachment: :blob)
      .order("artists.name", :release_date)
  end
end
