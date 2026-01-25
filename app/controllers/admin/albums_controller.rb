# Read-only controller - Albums are managed via YAML files
# Edit data/catalog/albums.yml and run: rails data:albums
class Admin::AlbumsController < Admin::ApplicationController
  def index
    @albums = Album.includes(:artist, :tracks, cover_image_attachment: :blob)
      .order("artists.name", :release_date)
  end
end
