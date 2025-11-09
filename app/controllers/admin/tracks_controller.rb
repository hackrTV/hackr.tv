class Admin::TracksController < Admin::ApplicationController
  before_action :set_track, only: [:edit, :update, :destroy]

  def index
    @tracks = Track.includes(:artist).ordered
  end

  def new
    @track = Track.new
    @artists = Artist.order(:name)
  end

  def create
    @track = Track.new(track_params)
    process_json_fields

    if @track.save
      set_flash_success("Track '#{@track.title}' created successfully!")
      redirect_to admin_tracks_path
    else
      @artists = Artist.order(:name)
      flash.now[:error] = "Failed to create track: #{@track.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @artists = Artist.order(:name)
  end

  def update
    process_json_fields

    if @track.update(track_params)
      set_flash_success("Track '#{@track.title}' updated successfully!")
      redirect_to admin_tracks_path
    else
      @artists = Artist.order(:name)
      flash.now[:error] = "Failed to update track: #{@track.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @track.title
    @track.destroy
    set_flash_success("Track '#{title}' deleted successfully!")
    redirect_to admin_tracks_path
  end

  def import
    begin
      # Run the import:tracks rake task
      require "rake"
      Rails.application.load_tasks unless Rake::Task.task_defined?("import:tracks")
      Rake::Task["import:tracks"].reenable
      Rake::Task["import:tracks"].invoke

      set_flash_success("Track import completed successfully! Check logs for details.")
    rescue => e
      set_flash_error("Import failed: #{e.message}")
    end

    redirect_to admin_tracks_path
  end

  private

  def set_track
    @track = Track.find_by!(slug: params[:id])
  end

  def track_params
    params.require(:track).permit(
      :title,
      :slug,
      :artist_id,
      :album,
      :album_type,
      :release_date,
      :featured,
      :duration,
      :cover_image,
      :lyrics,
      :audio_file,
      :remove_audio_file
    )
  end

  def process_json_fields
    # Process streaming_links JSON
    if params[:track][:streaming_links_json].present?
      begin
        links = {}
        params[:track][:streaming_links_json].each do |key, value|
          links[key] = value if value.present?
        end
        @track.streaming_links = links.presence
      rescue => e
        Rails.logger.error "Failed to process streaming_links: #{e.message}"
      end
    end

    # Process videos JSON
    if params[:track][:videos_json].present?
      begin
        vids = {}
        params[:track][:videos_json].each do |key, value|
          vids[key] = value if value.present?
        end
        @track.videos = vids.presence
      rescue => e
        Rails.logger.error "Failed to process videos: #{e.message}"
      end
    end

    # Handle audio file removal
    if params[:track][:remove_audio_file] == "1" && @track.audio_file.attached?
      @track.audio_file.purge
    end
  end
end
