class Admin::AlbumsController < Admin::ApplicationController
  before_action :set_album, only: [:edit, :update, :destroy]
  before_action :load_artists, only: [:new, :create, :edit, :update]

  def index
    @albums = Album.includes(:artist, :tracks, cover_image_attachment: :blob)
      .order("artists.name", :release_date)
  end

  def new
    @album = Album.new
  end

  def create
    @album = Album.new(album_params)

    if @album.save
      set_flash_success("Album '#{@album.name}' created successfully!")
      redirect_to admin_albums_path
    else
      flash.now[:error] = "Failed to create album: #{@album.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Handle cover image removal
    if params[:album][:remove_cover_image] == "1" && @album.cover_image.attached?
      @album.cover_image.purge
    end

    if @album.update(album_params)
      set_flash_success("Album '#{@album.name}' updated successfully!")
      redirect_to admin_albums_path
    else
      flash.now[:error] = "Failed to update album: #{@album.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @album.tracks.any?
      set_flash_error("Cannot delete album '#{@album.name}' - it has #{@album.tracks.count} track(s). Delete or reassign tracks first.")
    else
      name = @album.name
      @album.destroy
      set_flash_success("Album '#{name}' deleted successfully!")
    end
    redirect_to admin_albums_path
  end

  private

  def set_album
    @album = Album.find(params[:id])
  end

  def load_artists
    @artists = Artist.order(:name)
  end

  def album_params
    params.require(:album).permit(:name, :slug, :artist_id, :album_type, :release_date, :description, :cover_image)
  end
end
