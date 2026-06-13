class Admin::OverlaysController < Admin::ApplicationController
  # GET /root/overlays
  def index
    @scene_groups = OverlaySceneGroup.ordered.includes(overlay_scene_group_scenes: :overlay_scene)
    @scenes = OverlayScene.ordered
    @elements = OverlayElement.order(:element_type, :name)
    @lower_thirds = OverlayLowerThird.order(:name)
    @tickers = OverlayTicker.ordered
    @now_playing = OverlayNowPlaying.current
    @pending_alerts = OverlayAlert.pending.count
  end

  # GET /root/overlays/now-playing/edit
  def edit_now_playing
    @now_playing = OverlayNowPlaying.current
    @tracks = Track.includes(:artist).order("artists.name, tracks.title")
  end

  # PATCH /root/overlays/now-playing
  def update_now_playing
    @now_playing = OverlayNowPlaying.current

    if params[:clear].present?
      OverlayNowPlaying.clear!
      set_flash_success("Now playing cleared and broadcast.")
      redirect_to admin_edit_overlay_now_playing_path
      return
    end

    np = now_playing_params
    if np[:track_id].present?
      track = Track.find_by(id: np[:track_id])
      if track
        OverlayNowPlaying.set_track!(track, paused: np[:paused] == "1")
        set_flash_success("Now playing set to '#{track.title}' and broadcast.")
      else
        set_flash_error("Track not found.")
      end
    elsif np[:custom_title].present?
      OverlayNowPlaying.set_custom!(title: np[:custom_title], artist: np[:custom_artist])
      set_flash_success("Now playing set to custom track and broadcast.")
    else
      OverlayNowPlaying.set_paused!(np[:paused] == "1")
      set_flash_success("Now playing pause state updated and broadcast.")
    end

    redirect_to admin_edit_overlay_now_playing_path
  end

  private

  def now_playing_params
    params.require(:overlay_now_playing).permit(:track_id, :custom_title, :custom_artist, :paused)
  end
end
