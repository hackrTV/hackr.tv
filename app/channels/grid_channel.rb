class GridChannel < ApplicationCable::Channel
  def subscribed
    # Reload hackr to get fresh current_room data from database
    current_hackr.reload

    # Subscribe to the room the hackr is currently in
    if current_hackr&.current_room
      Rails.logger.info "=== GridChannel: #{current_hackr.hackr_alias} subscribed to room #{current_hackr.current_room.id} (#{current_hackr.current_room.name}) ==="
      stream_for current_hackr.current_room
    else
      Rails.logger.warn "=== GridChannel: Subscription rejected - no current room ==="
      reject
    end
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed
    Rails.logger.info "=== GridChannel: #{current_hackr&.hackr_alias} unsubscribed ==="
  end

  def receive(data)
    # Handle incoming messages from the client (future use for chat, etc.)
  end
end
