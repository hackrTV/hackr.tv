class PulseWireChannel < ApplicationCable::Channel
  def subscribed
    # Admin preview (controlled rollout): the WIRE is admin-only for now
    # — restore the open subscribe when it reopens (it was public: no
    # auth to view, login only to post). /terminal's server-side
    # subscriber (lib/terminal/realtime_subscriber.rb) reads the
    # pulse_wire stream at the pubsub layer, not through this channel,
    # so it is unaffected.
    unless current_hackr&.admin?
      Rails.logger.warn "=== PulseWireChannel: Rejected non-admin subscribe (admin preview) ==="
      reject
      return
    end

    Rails.logger.info "=== PulseWireChannel: #{current_hackr.hackr_alias} subscribed to the Wire ==="
    stream_from "pulse_wire"
  end

  def unsubscribed
    Rails.logger.info "=== PulseWireChannel: #{current_hackr&.hackr_alias || "Anonymous"} disconnected from the Wire ==="
  end

  def receive(data)
    # Handle incoming WebSocket messages (future use for optimistic updates, typing indicators, etc.)
  end
end
