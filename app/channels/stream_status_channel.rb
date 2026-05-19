class StreamStatusChannel < ApplicationCable::Channel
  def subscribed
    Rails.logger.info "=== StreamStatusChannel: #{current_hackr&.hackr_alias || "Anonymous"} subscribed to stream status ==="
    stream_from "stream_status"

    # Send current stream status on subscribe
    transmit_current_status
  end

  def unsubscribed
    Rails.logger.info "=== StreamStatusChannel: #{current_hackr&.hackr_alias || "Anonymous"} disconnected from stream status ==="
  end

  private

  def transmit_current_status
    current_stream = HackrStream.includes(:artist).current_live
    next_stream = HackrStream.includes(:artist).next_scheduled

    transmit({
      type: "stream_status",
      is_live: current_stream.present?,
      stream: current_stream&.stream_json,
      next_scheduled: next_stream&.scheduled_json
    })
  end
end
