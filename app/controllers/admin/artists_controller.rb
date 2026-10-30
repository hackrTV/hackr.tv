# /root/artists — the artists ledger and the artist record as console
# screens (2026-10-30; admin/music/*, root_console.css). The record
# screen is the edit screen: show redirects there.
class Admin::ArtistsController < Admin::ApplicationController
  include Admin::Versionable

  versionable Artist, find_by: :slug

  before_action :set_artist, only: %i[show edit update destroy]

  def index
    @artists = Artist.order(:name).includes(:tracks, :releases)
    @type_counts = @artists.group_by(&:artist_type).transform_values(&:size)
    @release_count = Release.count
    @incoming_count = Release.where(coming_soon: true).count
    @track_count = Track.count
  end

  def show
    redirect_to edit_admin_artist_path(@artist)
  end

  def new
    @artist = Artist.new(artist_type: "band")
  end

  def create
    @artist = Artist.new(artist_params)
    if @artist.save
      set_flash_success("Artist '#{@artist.name}' created.")
      redirect_to edit_admin_artist_path(@artist)
    else
      flash.now[:error] = @artist.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_releases
  end

  def update
    if @artist.update(artist_params)
      set_flash_success("Artist '#{@artist.name}' updated.")
      redirect_to edit_admin_artist_path(@artist)
    else
      load_releases
      flash.now[:error] = @artist.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @artist.name
    if @artist.releases.any? || @artist.tracks.any?
      set_flash_error("Can't delete '#{name}' — releases or tracks still reference it.")
      redirect_to edit_admin_artist_path(@artist)
    else
      @artist.destroy!
      set_flash_success("Artist '#{name}' deleted.")
      redirect_to admin_artists_path
    end
  end

  private

  def set_artist
    @artist = Artist.find_by!(slug: params[:id])
  end

  # The record screen's // RELEASES // ledger: incoming first, then
  # newest; covers and tracks loaded for the rows.
  def load_releases
    @releases = @artist.releases.includes(:tracks, cover_image_attachment: :blob)
      .order(Arel.sql("coming_soon DESC, release_date DESC NULLS LAST, name"))
  end

  def artist_params
    params.require(:artist).permit(:name, :slug, :genre, :artist_type)
  end
end
