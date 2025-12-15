# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::RealtimeSubscriber do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }
  let(:room) { create(:grid_room) }

  let(:session) do
    instance_double("Terminal::Session", hackr: hackr)
  end

  subject(:subscriber) { described_class.new(session) }

  after do
    subscriber.clear_callbacks
  end

  describe "#on_wire" do
    it "subscribes to pulse_wire stream" do
      expect(ActionCable.server.pubsub).to receive(:subscribe).with("pulse_wire", anything)

      subscriber.on_wire { |event| }
    end

    it "receives new pulse events" do
      received_events = []

      subscriber.on_wire { |event| received_events << event }

      # Broadcast a pulse from another user
      ActionCable.server.broadcast("pulse_wire", {
        type: "new_pulse",
        pulse: {
          id: 123,
          content: "Test pulse content",
          grid_hackr: {id: other_hackr.id, hackr_alias: other_hackr.hackr_alias},
          pulsed_at: Time.current
        }
      })

      # Allow async processing
      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("new_pulse")
      expect(received_events.first[:hackr_alias]).to eq(other_hackr.hackr_alias)
      expect(received_events.first[:content]).to eq("Test pulse content")
    end

    it "ignores own pulses" do
      received_events = []

      subscriber.on_wire { |event| received_events << event }

      # Broadcast a pulse from the same user
      ActionCable.server.broadcast("pulse_wire", {
        type: "new_pulse",
        pulse: {
          id: 123,
          content: "My own pulse",
          grid_hackr: {id: hackr.id, hackr_alias: hackr.hackr_alias},
          pulsed_at: Time.current
        }
      })

      sleep 0.1

      expect(received_events).to be_empty
    end

    it "ignores non-new_pulse events" do
      received_events = []

      subscriber.on_wire { |event| received_events << event }

      ActionCable.server.broadcast("pulse_wire", {
        type: "pulse_deleted",
        pulse_id: 123
      })

      sleep 0.1

      expect(received_events).to be_empty
    end
  end

  describe "#on_grid" do
    it "registers a callback for grid events" do
      callback_registered = false

      subscriber.on_grid { callback_registered = true }

      expect(callback_registered).to be false # Callback not invoked yet, just registered
    end
  end

  describe "#monitor_room" do
    before do
      hackr.update!(current_room: room)
      allow(session).to receive(:hackr).and_return(hackr)
    end

    it "subscribes to the room's stream" do
      stream_name = GridChannel.broadcasting_for(room)

      subscriber.on_grid { |event| }

      expect(ActionCable.server.pubsub).to receive(:subscribe).with(stream_name, anything)

      subscriber.monitor_room(room.id)
    end

    it "receives say events from other players" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "say",
        hackr_id: other_hackr.id,
        hackr_alias: other_hackr.hackr_alias,
        message: "Hello everyone!"
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("say")
      expect(received_events.first[:hackr_alias]).to eq(other_hackr.hackr_alias)
      expect(received_events.first[:content]).to eq("Hello everyone!")
    end

    it "ignores own say events" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "say",
        hackr_id: hackr.id,
        hackr_alias: hackr.hackr_alias,
        message: "My own message"
      })

      sleep 0.1

      expect(received_events).to be_empty
    end

    it "receives arrival events" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "movement",
        hackr_id: other_hackr.id,
        hackr_alias: other_hackr.hackr_alias,
        direction: "north",
        to_room_id: room.id
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("arrival")
      expect(received_events.first[:hackr_alias]).to eq(other_hackr.hackr_alias)
      expect(received_events.first[:direction]).to eq("south") # Opposite direction
    end

    it "receives departure events" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "movement",
        hackr_id: other_hackr.id,
        hackr_alias: other_hackr.hackr_alias,
        direction: "east",
        from_room_id: room.id
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("departure")
      expect(received_events.first[:direction]).to eq("east")
    end

    it "receives take events" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "take",
        hackr_id: other_hackr.id,
        hackr_alias: other_hackr.hackr_alias,
        item_name: "data chip"
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("take")
      expect(received_events.first[:item]).to eq("data chip")
    end

    it "receives drop events" do
      received_events = []

      subscriber.on_grid { |event| received_events << event }
      subscriber.monitor_room(room.id)

      GridChannel.broadcast_to(room, {
        type: "drop",
        hackr_id: other_hackr.id,
        hackr_alias: other_hackr.hackr_alias,
        item_name: "keycard"
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:type]).to eq("drop")
      expect(received_events.first[:item]).to eq("keycard")
    end

    it "unsubscribes from old room when switching" do
      other_room = create(:grid_room)

      subscriber.on_grid { |event| }
      subscriber.monitor_room(room.id)

      # Get the stream name that was subscribed to
      old_stream = GridChannel.broadcasting_for(room)

      # Allow any unsubscribe calls (including from after block cleanup)
      allow(ActionCable.server.pubsub).to receive(:unsubscribe).and_call_original
      # Expect at least one unsubscribe for the old room stream
      expect(ActionCable.server.pubsub).to receive(:unsubscribe).with(old_stream, anything).at_least(:once)

      subscriber.monitor_room(other_room.id)
    end
  end

  describe "#clear_callbacks" do
    it "unsubscribes from pulse_wire" do
      subscriber.on_wire { |event| }

      expect(ActionCable.server.pubsub).to receive(:unsubscribe).with("pulse_wire", anything)

      subscriber.clear_callbacks
    end

    it "unsubscribes from grid room" do
      subscriber.on_grid { |event| }
      subscriber.monitor_room(room.id)

      stream_name = GridChannel.broadcasting_for(room)

      expect(ActionCable.server.pubsub).to receive(:unsubscribe).with(stream_name, anything)

      subscriber.clear_callbacks
    end
  end

  describe "#running?" do
    it "returns false when no subscriptions" do
      expect(subscriber.running?).to be false
    end

    it "returns true when subscribed to wire" do
      subscriber.on_wire { |event| }

      expect(subscriber.running?).to be true
    end

    it "returns true when subscribed to grid" do
      subscriber.on_grid { |event| }
      subscriber.monitor_room(room.id)

      expect(subscriber.running?).to be true
    end
  end
end
