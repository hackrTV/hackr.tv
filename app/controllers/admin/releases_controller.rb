# /root/releases — the releases ledger (grouped by artist) and the
# release record as console screens (2026-10-30; admin/music/*,
# root_console.css). The record screen is the edit screen — the fields
# as status rows, the prose as textareas, the // FREQUENCIES // links,
# then the // TRACKS // ledger; show redirects there. purge_cover and
# destroy are hidden forms the screen's ghost buttons submit.
class Admin::ReleasesController < Admin::ApplicationController
  include Admin::Versionable
  include Admin::MusicParams

  versionable Release, find_by: :slug

  before_action :set_release, only: %i[show edit update destroy purge_cover]

  def index
    @releases = Release.includes(:artist, :tracks, cover_image_attachment: :blob).joins(:artist)
      .order(Arel.sql("artists.name, releases.coming_soon DESC, releases.release_date DESC NULLS LAST, releases.name"))
    @groups = @releases.group_by(&:artist)
    @incoming = @releases.select(&:coming_soon)
    @latest = @releases.reject(&:coming_soon).select(&:release_date).max_by(&:release_date)
    @track_count = Track.count
  end

  def show
    redirect_to edit_admin_release_path(@release)
  end

  def new
    @release = Release.new(artist_id: params[:artist_id].presence)
    load_artists
  end

  def create
    @release = Release.new(normalize_streaming_links!(release_params))
    if @release.save
      set_flash_success("Release '#{@release.name}' created.")
      redirect_to edit_admin_release_path(@release)
    else
      load_artists
      flash.now[:error] = @release.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_artists
    load_tracks
  end

  def update
    if @release.update(normalize_streaming_links!(release_params))
      set_flash_success("Release '#{@release.name}' updated.")
      redirect_to edit_admin_release_path(@release)
    else
      load_artists
      load_tracks
      flash.now[:error] = "Failed to update release: #{@release.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @release.name
    ActiveRecord::Base.transaction do
      @release.tracks.destroy_all
      @release.destroy!
    end
    set_flash_success("Release '#{name}' and all its tracks deleted.")
    redirect_to admin_releases_path
  end

  def purge_cover
    @release.cover_image.purge
    set_flash_success("Cover image removed from '#{@release.name}'.")
    redirect_to edit_admin_release_path(@release)
  end

  private

  def set_release
    @release = Release.find_by(slug: params[:id]) || Release.find(params[:id])
  end

  def load_artists
    @artists = Artist.order(:name)
  end

  # The record screen's // TRACKS // ledger in disc order.
  def load_tracks
    @tracks = @release.tracks.includes(audio_file_attachment: :blob).to_a
  end

  def release_params
    params.require(:release).permit(
      :name, :slug, :artist_id, :release_type, :release_date,
      :description, :catalog_number, :media_format, :classification,
      :label, :credits, :notes, :coming_soon, :cover_image,
      streaming_links: STREAMING_PLATFORMS
    )
  end
end
