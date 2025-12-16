# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Handlers::GridHandler do
  let(:hackr) { create(:grid_hackr, :online) }
  let(:room) { hackr.current_room }
  let(:other_room) { create(:grid_room) }

  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:session) { Terminal::Session.new(input, output) }

  before do
    session.authenticate(hackr)
  end

  after do
    session.realtime.clear_callbacks
  end

  subject(:handler) { described_class.new(session) }

  describe "#broadcast_event" do
    context "with say event" do
      let(:event) do
        {
          type: "say",
          hackr_id: hackr.id,
          hackr_alias: hackr.hackr_alias,
          message: "Hello Grid!"
        }
      end

      it "broadcasts to current room" do
        expect(GridChannel).to receive(:broadcast_to).with(room, event)

        handler.send(:broadcast_event, event)
      end

      it "does not broadcast if hackr has no current room" do
        hackr.update!(current_room: nil)

        expect(GridChannel).not_to receive(:broadcast_to)

        handler.send(:broadcast_event, event)
      end
    end

    context "with take event" do
      let(:event) do
        {
          type: "take",
          hackr_id: hackr.id,
          hackr_alias: hackr.hackr_alias,
          item_name: "data chip"
        }
      end

      it "broadcasts to current room" do
        expect(GridChannel).to receive(:broadcast_to).with(room, event)

        handler.send(:broadcast_event, event)
      end
    end

    context "with drop event" do
      let(:event) do
        {
          type: "drop",
          hackr_id: hackr.id,
          hackr_alias: hackr.hackr_alias,
          item_name: "keycard"
        }
      end

      it "broadcasts to current room" do
        expect(GridChannel).to receive(:broadcast_to).with(room, event)

        handler.send(:broadcast_event, event)
      end
    end

    context "with movement event" do
      let(:event) do
        {
          type: "movement",
          hackr_id: hackr.id,
          hackr_alias: hackr.hackr_alias,
          direction: "north",
          from_room_id: room.id,
          to_room_id: other_room.id
        }
      end

      it "broadcasts to both rooms" do
        expect(GridChannel).to receive(:broadcast_to).with(room, event)
        expect(GridChannel).to receive(:broadcast_to).with(other_room, event)

        handler.send(:broadcast_event, event)
      end

      it "broadcasts only to from_room if to_room_id is nil" do
        event[:to_room_id] = nil

        expect(GridChannel).to receive(:broadcast_to).with(room, event)
        expect(GridChannel).not_to receive(:broadcast_to).with(other_room, anything)

        handler.send(:broadcast_event, event)
      end

      it "broadcasts only to to_room if from_room_id is nil" do
        event[:from_room_id] = nil

        expect(GridChannel).not_to receive(:broadcast_to).with(room, anything)
        expect(GridChannel).to receive(:broadcast_to).with(other_room, event)

        handler.send(:broadcast_event, event)
      end
    end

    context "with nil event" do
      it "does not broadcast" do
        expect(GridChannel).not_to receive(:broadcast_to)

        handler.send(:broadcast_event, nil)
      end
    end

    context "with unknown event type" do
      let(:event) do
        {
          type: "unknown",
          hackr_id: hackr.id
        }
      end

      it "does not broadcast" do
        expect(GridChannel).not_to receive(:broadcast_to)

        handler.send(:broadcast_event, event)
      end
    end
  end

  describe "#execute_command" do
    it "broadcasts say events" do
      expect(GridChannel).to receive(:broadcast_to).with(room, hash_including(type: "say"))

      handler.send(:execute_command, "say Hello!")
    end

    it "broadcasts movement events to both rooms" do
      # Create an exit to another room
      create(:grid_exit, from_room: room, to_room: other_room, direction: "north")

      expect(GridChannel).to receive(:broadcast_to).twice

      handler.send(:execute_command, "north")
    end
  end

  describe "#setup_realtime" do
    it "registers grid callback" do
      expect(session.realtime).to receive(:on_grid)

      handler.send(:setup_realtime)
    end

    it "monitors current room" do
      expect(session.realtime).to receive(:monitor_room).with(room.id)

      handler.send(:setup_realtime)
    end
  end

  describe "#on_leave" do
    it "clears realtime callbacks" do
      handler.on_enter

      expect(session.realtime).to receive(:clear_callbacks).at_least(:once)

      handler.on_leave
    end
  end

  describe "#display_realtime_event" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    it "displays say events" do
      handler.send(:display_realtime_event, {
        type: "say",
        hackr_alias: "TestHackr",
        content: "Hello world!"
      })

      expect(output.string).to include("TestHackr says:")
      expect(output.string).to include("Hello world!")
    end

    it "displays arrival events" do
      handler.send(:display_realtime_event, {
        type: "arrival",
        hackr_alias: "NewPlayer",
        direction: "south"
      })

      expect(output.string).to include("NewPlayer")
      expect(output.string).to include("arrives from the south")
    end

    it "displays departure events" do
      handler.send(:display_realtime_event, {
        type: "departure",
        hackr_alias: "LeavingPlayer",
        direction: "north"
      })

      expect(output.string).to include("LeavingPlayer")
      expect(output.string).to include("leaves to the north")
    end

    it "displays take events" do
      handler.send(:display_realtime_event, {
        type: "take",
        hackr_alias: "Collector",
        item: "ancient artifact"
      })

      expect(output.string).to include("Collector")
      expect(output.string).to include("picks up ancient artifact")
    end

    it "displays drop events" do
      handler.send(:display_realtime_event, {
        type: "drop",
        hackr_alias: "Dropper",
        item: "rusty key"
      })

      expect(output.string).to include("Dropper")
      expect(output.string).to include("drops rusty key")
    end

    it "handles nil events gracefully" do
      expect { handler.send(:display_realtime_event, nil) }.not_to raise_error
    end
  end
end
