class Admin::ZonePlaylistsController < Admin::ApplicationController
  before_action :set_zone_playlist, only: [:show, :edit, :update, :destroy, :add_track, :remove_track, :reorder_tracks]

  def index
    @zone_playlists = ZonePlaylist.includes(:zone_playlist_tracks, :tracks).order(:name)
  end

  def show
    @tracks = @zone_playlist.ordered_tracks.includes(:artist, :album)
    @available_tracks = Track.includes(:artist, :album).order("artists.name, tracks.title").joins(:artist)
  end

  def new
    @zone_playlist = ZonePlaylist.new
  end

  def create
    @zone_playlist = ZonePlaylist.new(zone_playlist_params)

    if @zone_playlist.save
      set_flash_success("Zone playlist '#{@zone_playlist.name}' created successfully!")
      redirect_to admin_zone_playlist_path(@zone_playlist)
    else
      flash.now[:error] = "Failed to create zone playlist: #{@zone_playlist.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @zone_playlist.update(zone_playlist_params)
      set_flash_success("Zone playlist '#{@zone_playlist.name}' updated successfully!")
      redirect_to admin_zone_playlist_path(@zone_playlist)
    else
      flash.now[:error] = "Failed to update zone playlist: #{@zone_playlist.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @zone_playlist.name
    @zone_playlist.destroy
    set_flash_success("Zone playlist '#{name}' deleted successfully!")
    redirect_to admin_zone_playlists_path
  end

  # POST /admin/zone_playlists/:id/add_track
  def add_track
    track = Track.find(params[:track_id])

    # Check if track already in playlist
    if @zone_playlist.tracks.exists?(track.id)
      flash[:error] = "Track '#{track.title}' is already in this playlist."
    else
      ZonePlaylistTrack.create!(
        zone_playlist: @zone_playlist,
        track: track,
        position: @zone_playlist.next_position
      )
      flash[:success] = "Track '#{track.title}' added to playlist."
    end

    redirect_to admin_zone_playlist_path(@zone_playlist)
  end

  # DELETE /admin/zone_playlists/:id/remove_track/:track_id
  def remove_track
    zone_playlist_track = @zone_playlist.zone_playlist_tracks.find_by!(track_id: params[:track_id])
    track_title = zone_playlist_track.track.title
    zone_playlist_track.destroy
    flash[:success] = "Track '#{track_title}' removed from playlist."
    redirect_to admin_zone_playlist_path(@zone_playlist)
  end

  # PATCH /admin/zone_playlists/:id/reorder_tracks
  def reorder_tracks
    positions = params[:positions] # Expected format: {track_id => position}

    positions.each do |track_id, position|
      zone_playlist_track = @zone_playlist.zone_playlist_tracks.find_by(track_id: track_id)
      zone_playlist_track&.update(position: position.to_i)
    end

    respond_to do |format|
      format.json { render json: {success: true, message: "Track order updated"} }
      format.html do
        flash[:success] = "Track order updated."
        redirect_to admin_zone_playlist_path(@zone_playlist)
      end
    end
  end

  private

  def set_zone_playlist
    @zone_playlist = ZonePlaylist.find(params[:id])
  end

  def zone_playlist_params
    params.require(:zone_playlist).permit(:name, :description, :crossfade_duration_ms, :default_volume)
  end
end
