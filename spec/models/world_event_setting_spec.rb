require "rails_helper"

RSpec.describe WorldEventSetting do
  describe "validations" do
    it "requires target_events_per_minute > 0" do
      setting = WorldEventSetting.new(target_events_per_minute: 0)
      expect(setting).not_to be_valid
    end

    it "requires target_events_per_minute <= 60" do
      setting = WorldEventSetting.new(target_events_per_minute: 61)
      expect(setting).not_to be_valid
    end

    it "accepts valid target_events_per_minute" do
      setting = WorldEventSetting.new(target_events_per_minute: 30)
      expect(setting).to be_valid
    end
  end

  describe ".current" do
    it "creates a singleton row on first call" do
      expect { WorldEventSetting.current }.to change { WorldEventSetting.count }.by(1)
    end

    it "returns the same record on subsequent calls" do
      first = WorldEventSetting.current
      second = WorldEventSetting.current
      expect(first.id).to eq(second.id)
    end

    it "defaults to 12 events per minute" do
      expect(WorldEventSetting.current.target_events_per_minute).to eq(12)
    end
  end

  describe ".target_rate" do
    it "returns the configured target" do
      WorldEventSetting.create!(target_events_per_minute: 42)
      expect(WorldEventSetting.target_rate).to eq(42)
    end
  end

  describe ".simulator_enabled?" do
    it "returns true by default" do
      expect(WorldEventSetting.simulator_enabled?).to be true
    end
  end

  describe ".visible?" do
    it "returns false by default" do
      expect(WorldEventSetting.visible?).to be false
    end

    it "returns true when set" do
      WorldEventSetting.current.update!(visible: true)
      expect(WorldEventSetting.visible?).to be true
    end
  end
end
