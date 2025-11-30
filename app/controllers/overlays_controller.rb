class OverlaysController < ApplicationController
  layout "overlay"

  # Skip domain redirects for overlay pages
  skip_before_action :check_for_redirect, if: -> { defined?(check_for_redirect) }
  skip_before_action :check_for_domain_redirect, if: -> { defined?(check_for_domain_redirect) }

  # GET /overlays/now-playing
  def now_playing
    @now_playing = OverlayNowPlaying.current
  end

  # GET /overlays/pulsewire
  def pulsewire
    @pulses = Pulse.where(signal_dropped: false)
      .where(parent_pulse_id: nil)
      .includes(:grid_hackr)
      .order(pulsed_at: :desc)
      .limit(params[:limit] || 5)
  end

  # GET /overlays/grid-activity
  def grid_activity
    @online_hackrs = GridHackr.where("last_activity_at > ?", 15.minutes.ago)
      .includes(:current_room)
      .order(last_activity_at: :desc)
      .limit(10)

    @recent_messages = GridMessage.includes(:grid_hackr)
      .order(created_at: :desc)
      .limit(params[:limit] || 5)
  end

  # GET /overlays/alerts
  def alerts
    @alert = OverlayAlert.pending.order(created_at: :asc).first
  end

  # GET /overlays/lower-third/:slug
  def lower_third
    @lower_third = OverlayLowerThird.active.find_by!(slug: params[:slug])
  end

  # GET /overlays/codex/:slug
  def codex
    @entry = CodexEntry.published.find_by!(slug: params[:slug])
  end

  # GET /overlays/ticker/:position
  def ticker
    @ticker = OverlayTicker.active.find_by!(slug: params[:position])
  end

  # GET /overlays/scenes/:slug
  def scene
    @scene = OverlayScene.active.find_by!(slug: params[:slug])
    @elements = @scene.overlay_scene_elements
      .includes(:overlay_element)
      .order(z_index: :asc)

    # Use fullscreen layout for fullscreen scenes
    if @scene.fullscreen?
      render layout: "overlay_fullscreen"
    end
  end
end
