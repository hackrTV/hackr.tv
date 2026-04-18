class Admin::ArtistsController < Admin::ApplicationController
  include Admin::Versionable

  versionable Artist, find_by: :slug

  before_action :set_artist, only: %i[edit update destroy]

  def index
    @artists = Artist.order(:name).includes(:tracks)
  end

  def new
    @artist = Artist.new(artist_type: "band")
  end

  def create
    @artist = Artist.new(artist_params)
    if @artist.save
      set_flash_success("Artist '#{@artist.name}' created.")
      redirect_to admin_artists_path
    else
      flash.now[:error] = @artist.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @artist.update(artist_params)
      set_flash_success("Artist '#{@artist.name}' updated.")
      redirect_to admin_artists_path
    else
      flash.now[:error] = @artist.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @artist.name
    if @artist.releases.any? || @artist.tracks.any?
      set_flash_error("Can't delete '#{name}' — releases or tracks still reference it.")
    else
      @artist.destroy!
      set_flash_success("Artist '#{name}' deleted.")
    end
    redirect_to admin_artists_path
  end

  private

  def set_artist
    @artist = Artist.find_by!(slug: params[:id])
  end

  def artist_params
    params.require(:artist).permit(:name, :slug, :genre, :artist_type)
  end
end
