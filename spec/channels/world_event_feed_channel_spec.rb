require "rails_helper"

RSpec.describe WorldEventFeedChannel, type: :channel do
  before do
    WorldEventSetting.create!(target_events_per_minute: 12, simulator_enabled: true, visible: true)
  end

  describe "#subscribed when visible" do
    before { stub_connection }

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

  describe "#subscribed when hidden" do
    before do
      WorldEventSetting.current.update!(visible: false)
    end

    it "rejects anonymous subscriptions" do
      stub_connection(current_hackr: nil)
      subscribe
      expect(subscription).to be_rejected
    end

    it "rejects non-admin subscriptions" do
      hackr = create(:grid_hackr, role: "operative")
      stub_connection(current_hackr: hackr)
      subscribe
      expect(subscription).to be_rejected
    end

    it "allows admin subscriptions" do
      admin = create(:grid_hackr, role: "admin")
      stub_connection(current_hackr: admin)
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("world_event_feed")
    end
  end
end
