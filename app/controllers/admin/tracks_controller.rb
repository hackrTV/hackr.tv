class Admin::TracksController < Admin::ApplicationController
  include Admin::Versionable

  versionable Track, find_by: :slug

  before_action :set_track, only: [:edit, :update, :destroy, :purge_audio]

  def index
    @tracks = Track.includes(:artist, :release).ordered
  end

  def new
    @track = Track.new
    @releases = Release.includes(:artist).order("artists.name", :name)
  end

  def create
    @track = Track.new(track_params)
    @track.artist = @track.release.artist if @track.release
    if @track.save
      set_flash_success("Track '#{@track.title}' created.")
      redirect_to edit_admin_release_path(@track.release)
    else
      @releases = Release.includes(:artist).order("artists.name", :name)
      flash.now[:error] = @track.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @release = @track.release
  end

  def update
    if @track.update(track_params)
      set_flash_success("Track '#{@track.title}' updated successfully!")
      redirect_to edit_admin_release_path(@track.release)
    else
      @release = @track.release
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

  def track_params
    params.require(:track).permit(
      :title, :slug, :release_id, :track_number, :duration, :featured,
      :show_in_pulse_vault, :lyrics, :release_date, :audio_file
    )
  end
end
