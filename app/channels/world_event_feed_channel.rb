# frozen_string_literal: true

class WorldEventFeedChannel < ApplicationCable::Channel
  def subscribed
    unless WorldEventSetting.visible? || current_hackr&.admin?
      reject
      return
    end

    stream_from WorldEventFeed::Publisher::STREAM_NAME

    # Send recent events on subscribe so clients have initial state
    transmit_recent_events
  end

  def unsubscribed
    # No cleanup needed — global stream
  end

  private

  def transmit_recent_events
    events = WorldEvent.recent.limit(50).to_a.reverse
    transmit({
      type: "initial_events",
      events: events.map { |e| WorldEventFeed::Publisher.serialize(e) }
    })
  end
end
