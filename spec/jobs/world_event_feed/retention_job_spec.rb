require "rails_helper"

RSpec.describe WorldEventFeed::RetentionJob do
  describe "#perform" do
    it "deletes events older than 7 days" do
      old = WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Old", created_at: 8.days.ago)
      recent = WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Recent")

      described_class.new.perform

      expect(WorldEvent.exists?(old.id)).to be false
      expect(WorldEvent.exists?(recent.id)).to be true
    end

    it "preserves events within 7 days" do
      edge = WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Edge", created_at: 6.days.ago)

      described_class.new.perform

      expect(WorldEvent.exists?(edge.id)).to be true
    end
  end
end
