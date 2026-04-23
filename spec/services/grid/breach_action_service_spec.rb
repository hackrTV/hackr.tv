# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::BreachActionService do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:template) { create(:grid_breach_template) }

  let(:deck_def) do
    create(:grid_item_definition, :gear,
      slug: "test-deck-action",
      name: "Test Deck",
      properties: {"slot" => "deck", "slot_count" => 4, "battery_max" => 64, "battery_current" => 64, "firmware_slot_count" => 1, "effects" => {}})
  end

  let!(:deck) do
    item = create(:grid_item, :in_inventory, grid_item_definition: deck_def, grid_hackr: hackr)
    item.update!(equipped_slot: "deck")
    item
  end

  let(:software_def) do
    create(:grid_item_definition,
      slug: "test-software",
      name: "Packet Storm",
      item_type: "software",
      rarity: "common",
      properties: {"software_category" => "offensive", "slot_cost" => 1, "battery_cost" => 12, "effect_type" => "damage", "effect_magnitude" => 30, "level" => 1})
  end

  let!(:software) do
    create(:grid_item, grid_item_definition: software_def, grid_hackr: hackr, room: nil, deck_id: deck.id)
  end

  let(:encounter) { create(:grid_breach_encounter, grid_breach_template: template, grid_room: room) }

  let!(:breach) do
    result = Grid::BreachService.start!(hackr: hackr, encounter: encounter)
    result.hackr_breach
  end

  describe ".exec!" do
    it "deals damage to target protocol" do
      result = described_class.exec!(
        hackr: hackr,
        program_name: "Packet Storm",
        target_position: 0
      )

      expect(result.hit).to be true
      expect(result.damage_dealt).to be > 0
      expect(result.battery_consumed).to eq(12)

      protocol = breach.grid_breach_protocols.find_by(position: 0)
      expect(protocol.health).to be < protocol.max_health
    end

    it "destroys protocol when health reaches 0" do
      # Set protocol health low enough to be one-shot
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update!(health: 1)

      result = described_class.exec!(
        hackr: hackr,
        program_name: "Packet Storm",
        target_position: 0
      )

      expect(result.protocol_destroyed).to be true
      expect(protocol.reload.state).to eq("destroyed")
    end

    it "deducts battery from deck" do
      old_battery = deck.deck_battery
      described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      expect(deck.reload.deck_battery).to eq(old_battery - 12)
    end

    it "decrements actions_remaining" do
      old_actions = breach.actions_remaining
      described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      expect(breach.reload.actions_remaining).to eq(old_actions - 1)
    end

    it "raises NoActionsRemaining when out of actions" do
      breach.update!(actions_remaining: 0)
      expect {
        described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      }.to raise_error(Grid::BreachActionService::NoActionsRemaining)
    end

    it "raises ProgramNotLoaded for unknown program" do
      expect {
        described_class.exec!(hackr: hackr, program_name: "Nonexistent", target_position: 0)
      }.to raise_error(Grid::BreachActionService::ProgramNotLoaded)
    end

    it "raises InsufficientBattery when deck is drained" do
      deck.update!(properties: deck.properties.merge("battery_current" => 0))
      expect {
        described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      }.to raise_error(Grid::BreachActionService::InsufficientBattery)
    end

    it "raises InvalidTarget for non-existent protocol position" do
      expect {
        described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 99)
      }.to raise_error(Grid::BreachActionService::InvalidTarget)
    end

    it "raises ProtocolAlreadyDestroyed for destroyed protocols" do
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update_columns(state: "destroyed", health: 0)
      expect {
        described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      }.to raise_error(Grid::BreachActionService::ProtocolAlreadyDestroyed)
    end

    it "applies weakness bonus when software category matches" do
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update!(weakness: "offensive")
      protocol.health

      result = described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)

      # Weakness bonus = 1.5x base magnitude (30 * 1.5 = 45)
      expect(result.damage_dealt).to eq(45)
    end

    it "detects all_destroyed when last protocol is killed" do
      # Destroy all but one
      breach.grid_breach_protocols.where.not(position: 0).update_all(state: "destroyed")
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update!(health: 1)

      result = described_class.exec!(hackr: hackr, program_name: "Packet Storm", target_position: 0)
      expect(result.all_destroyed).to be true
    end
  end

  describe ".analyze!" do
    it "reveals protocol info progressively" do
      result = described_class.analyze!(hackr: hackr, target_position: 0)

      expect(result.level_reached).to eq(1)
      expect(result.info_revealed).to include("type identified")
    end

    it "reveals weakness at level 2" do
      # First analyze
      described_class.analyze!(hackr: hackr, target_position: 0)
      # Need more actions
      breach.update!(actions_remaining: 2)

      result = described_class.analyze!(hackr: hackr, target_position: 0)
      expect(result.level_reached).to eq(2)
      expect(result.info_revealed).to include("Weakness revealed")
    end

    it "caps at level 3" do
      protocol = breach.grid_breach_protocols.find_by(position: 0)
      protocol.update!(meta: {"analyze_level" => 3})

      result = described_class.analyze!(hackr: hackr, target_position: 0)
      expect(result.level_reached).to eq(3)
      expect(result.info_revealed).to include("Already fully analyzed")
    end

    it "raises NoActionsRemaining when out of actions" do
      breach.update!(actions_remaining: 0)
      expect {
        described_class.analyze!(hackr: hackr, target_position: 0)
      }.to raise_error(Grid::BreachActionService::NoActionsRemaining)
    end
  end
end
