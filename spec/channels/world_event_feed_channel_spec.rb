require "rails_helper"

RSpec.describe WorldEventFeedChannel, type: :channel do
  before do
    stub_connection
  end

  describe "#subscribed" do
    it "streams from world_event_feed" do
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("world_event_feed")
    end

    it "transmits initial events on subscribe" do
      WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Test", data: {new_clearance: 5})

      subscribe

      transmission = transmissions.last
      expect(transmission["type"]).to eq("initial_events")
      expect(transmission["events"].length).to eq(1)
    end

    it "transmits events in chronological order" do
      WorldEvent.create!(event_type: "clearance_up", hackr_alias: "First", created_at: 2.minutes.ago)
      WorldEvent.create!(event_type: "breach_completed", hackr_alias: "Second")

      subscribe

      events = transmissions.last["events"]
      expect(events.first["hackr_alias"]).to eq("First")
      expect(events.last["hackr_alias"]).to eq("Second")
    end

    it "limits initial events to 50" do
      60.times { |i| WorldEvent.create!(event_type: "clearance_up", hackr_alias: "H#{i}") }

      subscribe

      events = transmissions.last["events"]
      expect(events.length).to eq(50)
    end
  end
end
