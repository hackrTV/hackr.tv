# frozen_string_literal: true

# Tracks how long a logged-in hackr watches the live stream. Modeled on
# LiveChatChannel's server-side `periodically` heartbeat — the client
# subscribes while the stream is live and the tab is visible, and the
# channel accrues watch time with no client-side timer. Anonymous
# viewers are rejected (no per-hackr accounting possible). The iframe
# player is opaque, so "subscribed + tab visible" is the watch signal.
class StreamWatchChannel < ApplicationCable::Channel
  TICK_SECONDS = 60

  # Credit watch time while the socket is alive and the stream is live.
  periodically every: TICK_SECONDS.seconds do
    credit_tick if @session_id
  end

  def subscribed
    return reject unless current_hackr

    stream = HackrStream.current_live
    return reject unless stream

    # Free the unique slot if a prior socket died without unsubscribing,
    # then claim it. The partial unique index (one open session per hackr)
    # makes this atomic — a concurrent subscribe loses the race and is
    # rejected, so watch time is never double-counted.
    current_hackr.watch_sessions.stale.update_all(
      "disconnected_at = last_heartbeat_at, updated_at = CURRENT_TIMESTAMP"
    )

    @session_id = HackrWatchSession.create!(
      grid_hackr: current_hackr,
      hackr_stream: stream,
      connected_at: Time.current,
      last_heartbeat_at: Time.current,
      accumulated_seconds: 0
    ).id
    # No stream_from — this channel is write-only telemetry.
  rescue ActiveRecord::RecordNotUnique
    reject
  end

  def unsubscribed
    HackrWatchSession.find_by(id: @session_id)&.close! if @session_id
  end

  private

  def credit_tick
    return unless HackrStream.current_live # stream ended — stop crediting

    HackrWatchSession.find_by(id: @session_id)&.heartbeat!(TICK_SECONDS)
    current_hackr&.touch_activity!
  rescue => e
    Rails.logger.error "=== StreamWatchChannel: tick error: #{e.message} ==="
  end
end
