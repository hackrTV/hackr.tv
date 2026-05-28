require "rails_helper"

RSpec.describe WorldEventFeed::SimulatorJob do
  let!(:simulants) do
    3.times.map do
      hackr = create(:grid_hackr)
      WorldEventSimulant.create!(grid_hackr: hackr, state: {"clearance" => 5, "breach_count" => 0, "completed_missions" => [], "active_mission" => nil, "faction_standings" => {}, "achievements_earned" => [], "deck_name" => nil})
    end
  end

  before do
    WorldEventSetting.create!(target_events_per_minute: 12, simulator_enabled: true, visible: true)
  end

  describe "#perform" do
    it "generates events when organic rate is below target" do
      expect { described_class.new.perform }.to change { WorldEvent.simulated.count }
    end

    it "skips when simulator is disabled" do
      WorldEventSetting.current.update!(simulator_enabled: false)
      expect { described_class.new.perform }.not_to change { WorldEvent.count }
    end

    it "skips when feed is not visible" do
      WorldEventSetting.current.update!(visible: false)
      expect { described_class.new.perform }.not_to change { WorldEvent.count }
    end

    it "does not exceed safety cap of 20 events per tick" do
      WorldEventSetting.current.update!(target_events_per_minute: 120)
      described_class.new.perform
      # Even with 120/min target and 0 organic, one tick should not exceed 20
      expect(WorldEvent.simulated.count).to be <= 20
    end

    it "generates zero events when organic rate exceeds target" do
      # Simulate high organic rate by creating many recent organic events
      15.times { WorldEvent.create!(event_type: "clearance_up", hackr_alias: "Real", simulated: false) }
      allow(WorldEventFeed::Publisher).to receive(:current_organic_rate).and_return(20.0)

      expect { described_class.new.perform }.not_to change { WorldEvent.simulated.count }
    end
  end
end
