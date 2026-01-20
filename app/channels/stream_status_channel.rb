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
    current_stream = HackrStream.current_live

    transmit({
      type: "stream_status",
      is_live: current_stream.present?,
      stream: current_stream ? stream_json(current_stream) : nil
    })
  end

  def stream_json(stream)
    {
      id: stream.id,
      title: stream.title,
      artist: stream.artist&.name,
      started_at: stream.started_at&.iso8601
    }
  end
end
