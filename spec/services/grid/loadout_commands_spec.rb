# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Grid::CommandParser loadout commands" do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:gear_def) { create(:grid_item_definition, :gear, name: "Neural Visor", properties: {"slot" => "eyes", "effects" => {"bonus_max_psyche" => 10}}) }
  let(:gear_item) { create(:grid_item, :in_inventory, grid_item_definition: gear_def, grid_hackr: hackr) }

  def execute(input)
    Grid::CommandParser.new(hackr, input).execute
  end

  describe "equip command" do
    before { gear_item }

    it "equips a gear item" do
      result = execute("equip Neural Visor")
      expect(result[:output]).to include("Equipped")
      expect(result[:output]).to include("Neural Visor")
      expect(result[:output]).to include("EYES")
      expect(gear_item.reload.equipped_slot).to eq("eyes")
    end

    it "shows effects on equip" do
      result = execute("equip Neural Visor")
      expect(result[:output]).to include("bonus max psyche")
    end

    it "auto-swaps when slot is occupied" do
      gear_item.update!(equipped_slot: "eyes")
      second_def = create(:grid_item_definition, :gear, name: "Stealth Goggles", properties: {"slot" => "eyes", "effects" => {}})
      create(:grid_item, :in_inventory, grid_item_definition: second_def, grid_hackr: hackr)

      result = execute("equip Stealth Goggles")
      expect(result[:output]).to include("Swapped out: Neural Visor")
      expect(gear_item.reload.equipped_slot).to be_nil
    end

    it "rejects non-gear items" do
      tool_def = create(:grid_item_definition, name: "Wrench")
      create(:grid_item, :in_inventory, grid_item_definition: tool_def, grid_hackr: hackr)

      result = execute("equip Wrench")
      expect(result[:output]).to include("not gear")
    end

    it "shows already equipped message" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("equip Neural Visor")
      expect(result[:output]).to include("already equipped")
    end

    it "shows not found for missing items" do
      result = execute("equip Nonexistent")
      expect(result[:output]).to include("don't have")
    end

    it "blocks equip in danger zones" do
      danger_room = create(:grid_room, grid_zone: zone, room_type: "danger_zone")
      hackr.update!(current_room: danger_room)

      result = execute("equip Neural Visor")
      expect(result[:output]).to include("danger zone")
    end

    it "blocks equip with insufficient clearance" do
      cl_def = create(:grid_item_definition, :gear, name: "Elite Helm", properties: {"slot" => "head", "required_clearance" => 50, "effects" => {}})
      create(:grid_item, :in_inventory, grid_item_definition: cl_def, grid_hackr: hackr)

      result = execute("equip Elite Helm")
      expect(result[:output]).to include("ACCESS DENIED")
      expect(result[:output]).to include("CLEARANCE 50")
    end

    it "works with wear alias" do
      result = execute("wear Neural Visor")
      expect(result[:output]).to include("Equipped")
      expect(gear_item.reload.equipped_slot).to eq("eyes")
    end
  end

  describe "unequip command" do
    before { gear_item.update!(equipped_slot: "eyes") }

    it "unequips by item name" do
      result = execute("unequip Neural Visor")
      expect(result[:output]).to include("Unequipped")
      expect(result[:output]).to include("Neural Visor")
      expect(gear_item.reload.equipped_slot).to be_nil
    end

    it "unequips by slot name" do
      result = execute("unequip eyes")
      expect(result[:output]).to include("Unequipped")
      expect(gear_item.reload.equipped_slot).to be_nil
    end

    it "clamps vitals on unequip" do
      hackr.set_stat!("psyche", 110)
      result = execute("unequip Neural Visor")
      expect(result[:output]).to include("Psyche reduced to 100")
      expect(hackr.stat("psyche")).to eq(100)
    end

    it "shows error for non-equipped items" do
      gear_item.update!(equipped_slot: nil)
      result = execute("unequip Neural Visor")
      expect(result[:output]).to include("don't have")
    end

    it "works with remove alias" do
      result = execute("remove Neural Visor")
      expect(result[:output]).to include("Unequipped")
    end
  end

  describe "loadout command" do
    it "shows all slots" do
      result = execute("loadout")
      expect(result[:output]).to include("LOADOUT")
      expect(result[:output]).to include("DECK")
      expect(result[:output]).to include("HEAD")
      expect(result[:output]).to include("EYES")
      expect(result[:output]).to include("-- empty --")
    end

    it "shows equipped items" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("loadout")
      expect(result[:output]).to include("Neural Visor")
    end

    it "shows active effects" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("lo")
      expect(result[:output]).to include("Active Effects")
      expect(result[:output]).to include("bonus max psyche")
    end
  end

  describe "equipped item guards" do
    before { gear_item.update!(equipped_slot: "eyes") }

    it "blocks drop with equipped message" do
      result = execute("drop Neural Visor")
      expect(result[:output]).to include("equipped")
      expect(result[:output]).to include("unequip")
    end

    it "blocks salvage with equipped message" do
      result = execute("salvage Neural Visor")
      expect(result[:output]).to include("equipped")
      expect(result[:output]).to include("unequip")
    end

    it "blocks give with equipped message" do
      create(:grid_mob, grid_room: room, name: "Test NPC")
      result = execute("give Neural Visor to Test NPC")
      expect(result[:output]).to include("equipped")
      expect(result[:output]).to include("unequip")
    end
  end

  describe "stat command with gear" do
    it "shows effective max vitals" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("stat")
      expect(result[:output]).to include("PSYCHE")
      expect(result[:output]).to include("/110")
    end

    it "shows loadout summary" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("stat")
      expect(result[:output]).to include("LOADOUT:")
      expect(result[:output]).to include("1/13 slots")
    end
  end

  describe "examine with gear" do
    before { gear_item }

    it "shows gear properties on examine" do
      result = execute("examine Neural Visor")
      expect(result[:output]).to include("Gear Slot: EYES")
      expect(result[:output]).to include("bonus max psyche")
      expect(result[:output]).to include("equip neural visor")
    end

    it "shows equipped status on examine" do
      gear_item.update!(equipped_slot: "eyes")
      result = execute("examine Neural Visor")
      expect(result[:output]).to include("EQUIPPED")
    end
  end
end
