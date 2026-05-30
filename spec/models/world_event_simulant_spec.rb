# == Schema Information
#
# Table name: world_event_simulants
# Database name: primary
#
#  id            :integer          not null, primary key
#  state         :json             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_world_event_simulants_on_grid_hackr_id  (grid_hackr_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe WorldEventSimulant do
  let(:hackr) { create(:grid_hackr) }

  describe "validations" do
    it "requires unique grid_hackr_id" do
      WorldEventSimulant.create!(grid_hackr: hackr, state: {"clearance" => 0})
      dup = WorldEventSimulant.new(grid_hackr: hackr, state: {"clearance" => 5})
      expect(dup).not_to be_valid
    end
  end

  describe "state accessors" do
    let(:simulant) do
      WorldEventSimulant.create!(grid_hackr: hackr, state: {
        "clearance" => 15,
        "breach_count" => 7,
        "completed_missions" => ["Signal Recovery"],
        "active_mission" => "Data Salvage",
        "faction_standings" => {"Hackrcore" => "TRUSTED"},
        "achievements_earned" => ["First Steps"],
        "deck_name" => "Phantom DECK"
      })
    end

    it "reads clearance" do
      expect(simulant.clearance).to eq(15)
    end

    it "reads breach_count" do
      expect(simulant.breach_count).to eq(7)
    end

    it "reads completed_missions" do
      expect(simulant.completed_missions).to eq(["Signal Recovery"])
    end

    it "reads active_mission" do
      expect(simulant.active_mission).to eq("Data Salvage")
    end

    it "reads faction_standings" do
      expect(simulant.faction_standings).to eq({"Hackrcore" => "TRUSTED"})
    end

    it "reads achievements_earned" do
      expect(simulant.achievements_earned).to eq(["First Steps"])
    end

    it "reads deck_name" do
      expect(simulant.deck_name).to eq("Phantom DECK")
    end

    it "returns defaults for missing keys" do
      empty = WorldEventSimulant.create!(grid_hackr: create(:grid_hackr), state: {})
      expect(empty.clearance).to eq(0)
      expect(empty.breach_count).to eq(0)
      expect(empty.completed_missions).to eq([])
      expect(empty.active_mission).to be_nil
    end
  end

  describe "#advance_state!" do
    let(:simulant) { WorldEventSimulant.create!(grid_hackr: hackr, state: {"clearance" => 5}) }

    it "updates a single key and persists" do
      simulant.advance_state!("clearance", 6)
      expect(simulant.clearance).to eq(6)
      expect(simulant.reload.clearance).to eq(6)
    end

    it "preserves other state keys" do
      simulant.advance_state!("breach_count", 1)
      expect(simulant.clearance).to eq(5)
      expect(simulant.breach_count).to eq(1)
    end
  end

  describe "#hackr_alias" do
    it "delegates to grid_hackr" do
      simulant = WorldEventSimulant.create!(grid_hackr: hackr, state: {})
      expect(simulant.hackr_alias).to eq(hackr.hackr_alias)
    end
  end
end
