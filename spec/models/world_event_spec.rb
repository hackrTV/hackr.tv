# == Schema Information
#
# Table name: world_events
# Database name: primary
#
#  id          :integer          not null, primary key
#  data        :json             not null
#  event_type  :string           not null
#  hackr_alias :string           not null
#  simulated   :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_world_events_on_created_at  (created_at)
#  index_world_events_on_event_type  (event_type)
#  index_world_events_on_simulated   (simulated)
#
require "rails_helper"

RSpec.describe WorldEvent do
  describe "validations" do
    it "requires event_type" do
      event = WorldEvent.new(hackr_alias: "Test", event_type: nil)
      expect(event).not_to be_valid
      expect(event.errors[:event_type]).to be_present
    end

    it "requires hackr_alias" do
      event = WorldEvent.new(event_type: "clearance_up", hackr_alias: nil)
      expect(event).not_to be_valid
      expect(event.errors[:hackr_alias]).to be_present
    end

    it "rejects unknown event types" do
      event = WorldEvent.new(event_type: "bogus", hackr_alias: "Test")
      expect(event).not_to be_valid
    end

    it "accepts all defined event types" do
      WorldEvent::EVENT_TYPES.each do |type|
        event = WorldEvent.new(event_type: type, hackr_alias: "Test")
        expect(event).to be_valid, "expected #{type} to be valid"
      end
    end
  end

  describe "scopes" do
    before do
      WorldEvent.create!(event_type: "clearance_up", hackr_alias: "A", simulated: false)
      WorldEvent.create!(event_type: "breach_completed", hackr_alias: "B", simulated: true)
      WorldEvent.create!(event_type: "wire_post", hackr_alias: "C", simulated: false, created_at: 2.hours.ago)
    end

    it ".organic returns non-simulated events" do
      expect(WorldEvent.organic.count).to eq(2)
    end

    it ".simulated returns simulated events" do
      expect(WorldEvent.simulated.count).to eq(1)
    end

    it ".recent orders by created_at desc" do
      aliases = WorldEvent.recent.pluck(:hackr_alias)
      expect(aliases.first).not_to eq("C") # oldest last
    end

    it ".since filters by time" do
      expect(WorldEvent.since(1.hour.ago).count).to eq(2)
    end
  end

  describe ".organic_rate_per_minute" do
    it "returns 0 with no events" do
      expect(WorldEvent.organic_rate_per_minute).to eq(0.0)
    end

    it "counts only organic events in the window" do
      3.times { WorldEvent.create!(event_type: "clearance_up", hackr_alias: "A", simulated: false) }
      2.times { WorldEvent.create!(event_type: "clearance_up", hackr_alias: "B", simulated: true) }

      rate = WorldEvent.organic_rate_per_minute(window_seconds: 60)
      expect(rate).to eq(3.0)
    end
  end
end
