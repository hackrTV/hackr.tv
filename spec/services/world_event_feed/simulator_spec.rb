require "rails_helper"

RSpec.describe WorldEventFeed::Simulator do
  let!(:simulants) do
    5.times.map do |i|
      hackr = create(:grid_hackr)
      WorldEventSimulant.create!(grid_hackr: hackr, state: {
        "clearance" => i * 5,
        "breach_count" => i,
        "completed_missions" => [],
        "active_mission" => nil,
        "faction_standings" => {},
        "achievements_earned" => [],
        "deck_name" => nil
      })
    end
  end

  subject(:simulator) { described_class.new }

  describe "#generate_event!" do
    it "creates a WorldEvent" do
      expect { simulator.generate_event! }.to change { WorldEvent.count }.by(1)
    end

    it "marks events as simulated" do
      event = simulator.generate_event!
      expect(event.simulated?).to be true
    end

    it "uses a simulant alias" do
      event = simulator.generate_event!
      aliases = simulants.map(&:hackr_alias)
      expect(aliases).to include(event.hackr_alias)
    end

    it "returns nil with no simulants" do
      WorldEventSimulant.delete_all
      sim = described_class.new
      expect(sim.generate_event!).to be_nil
    end
  end

  describe "state consistency" do
    it "advances clearance on clearance_up events" do
      simulant = simulants.find { |s| s.clearance < 99 }
      old_cl = simulant.clearance

      # Force a clearance_up event by calling the private method
      event = simulator.send(:generate_clearance_up, simulant)

      expect(event.event_type).to eq("clearance_up")
      expect(simulant.reload.clearance).to eq(old_cl + 1)
    end

    it "tracks completed missions" do
      simulant = simulants.first
      simulator.send(:generate_mission_completed, simulant)

      expect(simulant.reload.completed_missions).not_to be_empty
    end

    it "increments breach count" do
      simulant = simulants.first
      old_count = simulant.breach_count
      simulator.send(:generate_breach_completed, simulant)

      expect(simulant.reload.breach_count).to eq(old_count + 1)
    end

    it "tracks faction standings" do
      simulant = simulants.first
      simulator.send(:generate_rep_tier_changed, simulant)

      expect(simulant.reload.faction_standings).not_to be_empty
    end

    it "tracks earned achievements" do
      simulant = simulants.first
      simulator.send(:generate_achievement_unlocked, simulant)

      expect(simulant.reload.achievements_earned).not_to be_empty
    end
  end

  describe "event type distribution" do
    it "generates all event types over many iterations" do
      50.times { simulator.generate_event! }
      types = WorldEvent.distinct.pluck(:event_type)

      # With 50 events and weighted distribution, most types should appear
      expect(types.length).to be >= 5
    end
  end
end
