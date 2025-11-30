class OverlayChannel < ApplicationCable::Channel
  def subscribed
    # OBS browser sources subscribe to receive real-time overlay updates
    # No authentication required - overlays are public
    Rails.logger.info "=== OverlayChannel: Overlay client subscribed ==="
    stream_from "overlay_updates"
  end

  def unsubscribed
    Rails.logger.info "=== OverlayChannel: Overlay client disconnected ==="
  end

  def receive(data)
    # Handle incoming WebSocket messages if needed
    # Currently overlays are read-only, but could support future features
    # like marking alerts as displayed
  end
end
