class OverlayChannel < ApplicationCable::Channel
  def subscribed
    # The external HUD app (OBS browser sources) subscribes for live
    # now_playing_changed + new_alert pushes. No authentication — public.
    Rails.logger.info "=== OverlayChannel: Overlay client subscribed ==="
    stream_from "overlay_updates"
  end

  def unsubscribed
    Rails.logger.info "=== OverlayChannel: Overlay client disconnected ==="
  end

  def receive(data)
    # Read-only channel — HUD never sends.
  end
end
