# /root/tracks — the tracks ledger (grouped by release, filterable) and
# the track record as a console screen (2026-10-30; admin/music/*,
# root_console.css): the fields as status rows, the audio file with a
# preview, // DECODED LYRICS // as one tall textarea, // FREQUENCIES //,
# then the release's other tracks for the hop. Saving stays on the track
# (it used to bounce to the release). show redirects to edit; new takes
# ?release_id to prefill the release and the next track number.
class Admin::TracksController < Admin::ApplicationController
  include Admin::Versionable
  include Admin::MusicParams

  versionable Track, find_by: :slug

  before_action :set_track, only: %i[show edit update destroy purge_audio]

  def index
    @tracks = Track.includes(:artist, release: {cover_image_attachment: :blob}, audio_file_attachment: :blob)
      .joins(:artist, :release)
      .order(Arel.sql("artists.name, releases.release_date DESC NULLS LAST, releases.name, tracks.track_number, tracks.title"))
    @groups = @tracks.group_by(&:release)
    @with_audio = @tracks.count { |t| t.audio_file.attached? }
    @in_vault = @tracks.count(&:show_in_pulse_vault)
    @featured = @tracks.count(&:featured)
  end

  def show
    redirect_to edit_admin_track_path(@track)
  end

  def new
    @track = Track.new(release_id: params[:release_id].presence)
    if @track.release
      @track.artist = @track.release.artist
      @track.track_number = (@track.release.tracks.maximum(:track_number) || 0) + 1
    end
    load_releases
  end

  def create
    @track = Track.new(normalize_streaming_links!(track_params))
    @track.artist = @track.release.artist if @track.release
    if @track.save
      set_flash_success("Track '#{@track.title}' created.")
      redirect_to edit_admin_track_path(@track)
    else
      load_releases
      flash.now[:error] = @track.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_releases
    load_siblings
  end

  def update
    @track.assign_attributes(normalize_streaming_links!(track_params))
    @track.artist = @track.release.artist if @track.release # the artist follows the release
    if @track.save
      set_flash_success("Track '#{@track.title}' updated.")
      redirect_to edit_admin_track_path(@track)
    else
      load_releases
      load_siblings
      flash.now[:error] = "Failed to update track: #{@track.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def purge_audio
    @track.audio_file.purge
    set_flash_success("Audio file removed from '#{@track.title}'.")
    redirect_to edit_admin_track_path(@track)
  end

  def destroy
    release = @track.release
    title = @track.title
    @track.audio_file.purge if @track.audio_file.attached?
    @track.destroy!
    set_flash_success("Track '#{title}' deleted.")
    redirect_to edit_admin_release_path(release)
  end

  private

  def set_track
    @track = Track.find_by(slug: params[:id]) || Track.find(params[:id])
  end

  # The RELEASE select, grouped by artist.
  def load_releases
    @releases = Release.includes(:artist).joins(:artist).order("artists.name", :name)
  end

  # // ALSO ON <RELEASE> //: the release in disc order, as saved.
  def load_siblings
    @release = Release.find(@track.release_id_in_database)
    @siblings = @release.tracks.reject { |t| t.id == @track.id }
  end

  def track_params
    params.require(:track).permit(
      :title, :slug, :release_id, :track_number, :duration, :featured,
      :show_in_pulse_vault, :lyrics, :release_date, :audio_file,
      streaming_links: STREAMING_PLATFORMS
    )
  end
end
