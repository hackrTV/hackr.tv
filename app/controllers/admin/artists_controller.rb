class Admin::ArtistsController < Admin::ApplicationController
  before_action :set_artist, only: [:edit, :update, :destroy]

  def index
    @artists = Artist.order(:name).includes(:tracks)
  end

  def new
    @artist = Artist.new
  end

  def create
    @artist = Artist.new(artist_params)

    if @artist.save
      set_flash_success("Artist '#{@artist.name}' created successfully!")
      redirect_to admin_artists_path
    else
      flash.now[:error] = "Failed to create artist: #{@artist.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @artist.update(artist_params)
      set_flash_success("Artist '#{@artist.name}' updated successfully!")
      redirect_to admin_artists_path
    else
      flash.now[:error] = "Failed to update artist: #{@artist.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @artist.tracks.any?
      set_flash_error("Cannot delete artist '#{@artist.name}' - it has #{@artist.tracks.count} track(s). Delete tracks first.")
    else
      name = @artist.name
      @artist.destroy
      set_flash_success("Artist '#{name}' deleted successfully!")
    end
    redirect_to admin_artists_path
  end

  private

  def set_artist
    @artist = Artist.find_by!(slug: params[:id])
  end

  def artist_params
    params.require(:artist).permit(:name, :slug)
  end
end
