class PulseWireChannel < ApplicationCable::Channel
  def subscribed
    # All hackrs can subscribe to the global PulseWire feed
    # No authentication required to view, but needed to post (handled in controller)
    Rails.logger.info "=== PulseWireChannel: #{current_hackr&.hackr_alias || "Anonymous"} subscribed to the Wire ==="
    stream_from "pulse_wire"
  end

  def unsubscribed
    Rails.logger.info "=== PulseWireChannel: #{current_hackr&.hackr_alias || "Anonymous"} disconnected from the Wire ==="
  end

  def receive(data)
    # Handle incoming WebSocket messages (future use for optimistic updates, typing indicators, etc.)
  end
end
