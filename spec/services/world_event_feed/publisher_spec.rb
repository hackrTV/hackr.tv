require "rails_helper"

RSpec.describe WorldEventFeed::Publisher do
  describe ".publish" do
    it "creates a WorldEvent record" do
      expect {
        described_class.publish(event_type: "clearance_up", hackr_alias: "TestHackr", data: {new_clearance: 5})
      }.to change { WorldEvent.count }.by(1)
    end

    it "returns the created event" do
      event = described_class.publish(event_type: "breach_completed", hackr_alias: "TestHackr", data: {})
      expect(event).to be_a(WorldEvent)
      expect(event).to be_persisted
    end

    it "broadcasts to ActionCable" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "world_event_feed",
        hash_including(type: "world_event")
      )
      described_class.publish(event_type: "clearance_up", hackr_alias: "TestHackr", data: {})
    end

    it "marks simulated events" do
      event = described_class.publish(event_type: "clearance_up", hackr_alias: "Sim", data: {}, simulated: true)
      expect(event.simulated?).to be true
    end

    it "never raises — returns nil on error" do
      allow(WorldEvent).to receive(:create!).and_raise(StandardError, "DB down")
      result = described_class.publish(event_type: "clearance_up", hackr_alias: "Test", data: {})
      expect(result).to be_nil
    end

    it "tracks organic rate for non-simulated events" do
      expect(described_class).to receive(:track_organic_rate)
      described_class.publish(event_type: "clearance_up", hackr_alias: "Test", data: {})
    end

    it "skips rate tracking for simulated events" do
      expect(described_class).not_to receive(:track_organic_rate)
      described_class.publish(event_type: "clearance_up", hackr_alias: "Test", data: {}, simulated: true)
    end
  end

  describe ".publish_level_up" do
    it "publishes clearance_up when leveled_up is true" do
      expect {
        described_class.publish_level_up(hackr_alias: "Test", xp_result: {leveled_up: true, new_clearance: 10})
      }.to change { WorldEvent.where(event_type: "clearance_up").count }.by(1)
    end

    it "does nothing when leveled_up is false" do
      expect {
        described_class.publish_level_up(hackr_alias: "Test", xp_result: {leveled_up: false})
      }.not_to change { WorldEvent.count }
    end

    it "does nothing when xp_result is nil" do
      expect {
        described_class.publish_level_up(hackr_alias: "Test", xp_result: nil)
      }.not_to change { WorldEvent.count }
    end
  end

  describe ".serialize" do
    it "returns canonical hash shape" do
      event = WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Test", data: {new_clearance: 5})
      result = described_class.serialize(event)

      expect(result).to include(:id, :event_type, :hackr_alias, :data, :message, :created_at)
      expect(result[:event_type]).to eq("clearance_up")
      expect(result[:hackr_alias]).to eq("Test")
      expect(result[:message]).to include("CLEARANCE 5")
    end
  end

  describe ".render_message" do
    it "formats clearance_up" do
      event = WorldEvent.new(event_type: "clearance_up", hackr_alias: "Neo", data: {"new_clearance" => 15})
      expect(described_class.render_message(event)).to eq("Neo reached CLEARANCE 15")
    end

    it "formats mission_accepted" do
      event = WorldEvent.new(event_type: "mission_accepted", hackr_alias: "Neo", data: {"mission_name" => "Signal Recovery"})
      expect(described_class.render_message(event)).to eq("Neo accepted mission: Signal Recovery")
    end

    it "formats mission_completed" do
      event = WorldEvent.new(event_type: "mission_completed", hackr_alias: "Neo", data: {"mission_name" => "Signal Recovery"})
      expect(described_class.render_message(event)).to eq("Neo completed mission: Signal Recovery")
    end

    it "formats breach_completed" do
      event = WorldEvent.new(event_type: "breach_completed", hackr_alias: "Neo", data: {"template_name" => "Deep Net", "tier" => "advanced"})
      expect(described_class.render_message(event)).to eq("Neo completed advanced-tier BREACH: Deep Net")
    end

    it "formats rep_tier_changed up" do
      event = WorldEvent.new(event_type: "rep_tier_changed", hackr_alias: "Neo", data: {"faction_name" => "Hackrcore", "new_tier" => "TRUSTED", "direction" => "up"})
      expect(described_class.render_message(event)).to eq("Neo reached TRUSTED standing with Hackrcore")
    end

    it "formats rep_tier_changed down" do
      event = WorldEvent.new(event_type: "rep_tier_changed", hackr_alias: "Neo", data: {"direction" => "down", "new_tier" => "FLAGGED", "faction_name" => "GovCorp"})
      expect(described_class.render_message(event)).to eq("Neo dropped to FLAGGED standing with GovCorp")
    end

    it "formats achievement_unlocked" do
      event = WorldEvent.new(event_type: "achievement_unlocked", hackr_alias: "Neo", data: {"achievement_name" => "First Steps"})
      expect(described_class.render_message(event)).to eq("Neo unlocked First Steps")
    end

    it "formats hackr_registered" do
      event = WorldEvent.new(event_type: "hackr_registered", hackr_alias: "Neo", data: {})
      expect(described_class.render_message(event)).to eq("Neo jacked into THE PULSE GRID for the first time")
    end

    it "formats wire_post with truncation" do
      event = WorldEvent.new(event_type: "wire_post", hackr_alias: "Neo", data: {"content" => "hello world"})
      expect(described_class.render_message(event)).to include("hello world")
    end

    it "formats manual events" do
      event = WorldEvent.new(event_type: "manual", hackr_alias: "SYSTEM", data: {"message" => "Server restarting"})
      expect(described_class.render_message(event)).to eq("Server restarting")
    end
  end

  describe ".current_organic_rate" do
    it "returns 0 with no cached data" do
      expect(described_class.current_organic_rate).to eq(0)
    end
  end
end
