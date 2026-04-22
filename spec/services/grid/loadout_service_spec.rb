# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::LoadoutService do
  let(:hackr) { create(:grid_hackr) }
  let(:room) { create(:grid_room) }
  let(:gear_def) { create(:grid_item_definition, :gear, properties: {"slot" => "head", "effects" => {"bonus_max_health" => 10}}) }
  let(:gear_item) { create(:grid_item, :in_inventory, grid_item_definition: gear_def, grid_hackr: hackr) }

  before do
    hackr.update!(current_room: room)
  end

  describe ".equip!" do
    it "equips a gear item to its slot" do
      result = described_class.equip!(hackr: hackr, item: gear_item)
      expect(result.slot).to eq("head")
      expect(result.item).to eq(gear_item)
      expect(result.swapped_item).to be_nil
      expect(gear_item.reload.equipped_slot).to eq("head")
    end

    it "auto-swaps when slot is occupied" do
      gear_item.update!(equipped_slot: "head")

      second_def = create(:grid_item_definition, :gear, properties: {"slot" => "head", "effects" => {}})
      second_item = create(:grid_item, :in_inventory, grid_item_definition: second_def, grid_hackr: hackr)

      result = described_class.equip!(hackr: hackr, item: second_item)
      expect(result.swapped_item).to eq(gear_item)
      expect(result.item).to eq(second_item)
      expect(gear_item.reload.equipped_slot).to be_nil
      expect(second_item.reload.equipped_slot).to eq("head")
    end

    it "raises NotGear for non-gear items" do
      tool = create(:grid_item, :in_inventory, grid_hackr: hackr)

      expect { described_class.equip!(hackr: hackr, item: tool) }
        .to raise_error(Grid::LoadoutService::NotGear)
    end

    it "raises ClearanceBlocked when clearance too low" do
      cl_def = create(:grid_item_definition, :gear, properties: {"slot" => "eyes", "required_clearance" => 50, "effects" => {}})
      cl_item = create(:grid_item, :in_inventory, grid_item_definition: cl_def, grid_hackr: hackr)

      expect { described_class.equip!(hackr: hackr, item: cl_item) }
        .to raise_error(Grid::LoadoutService::ClearanceBlocked)
    end

    it "raises ZoneRestricted in danger zones" do
      danger_room = create(:grid_room, room_type: "danger_zone")
      hackr.update!(current_room: danger_room)

      expect { described_class.equip!(hackr: hackr, item: gear_item) }
        .to raise_error(Grid::LoadoutService::ZoneRestricted)
    end
  end

  describe ".unequip!" do
    before { gear_item.update!(equipped_slot: "head") }

    it "unequips an item" do
      result = described_class.unequip!(hackr: hackr, item: gear_item)
      expect(result.slot).to eq("head")
      expect(gear_item.reload.equipped_slot).to be_nil
    end

    it "clamps vitals when cap is lowered" do
      hackr.set_stat!("health", 110)
      result = described_class.unequip!(hackr: hackr, item: gear_item)
      expect(result.vitals_clamped).to include(hash_including(vital: "health", new_value: 100))
      expect(hackr.stat("health")).to eq(100)
    end

    it "raises NotEquipped for non-equipped items" do
      gear_item.update!(equipped_slot: nil)
      expect { described_class.unequip!(hackr: hackr, item: gear_item) }
        .to raise_error(Grid::LoadoutService::NotEquipped)
    end
  end

  describe "inventory exclusion" do
    it "equipped items are excluded from in_inventory scope" do
      gear_item.update!(equipped_slot: "head")
      expect(hackr.grid_items.in_inventory(hackr)).not_to include(gear_item)
    end

    it "equipped items appear in equipped_by scope" do
      gear_item.update!(equipped_slot: "head")
      expect(hackr.grid_items.equipped_by(hackr)).to include(gear_item)
    end

    it "equipped items do not count against inventory capacity" do
      gear_item.update!(equipped_slot: "head")
      expect(hackr.grid_items.in_inventory(hackr).count).to eq(0)
    end
  end

  describe "loadout_effects" do
    it "sums effects from equipped gear" do
      gear_item.update!(equipped_slot: "head")

      eyes_def = create(:grid_item_definition, :gear, properties: {"slot" => "eyes", "effects" => {"bonus_max_health" => 5, "bonus_max_energy" => 10}})
      eyes_item = create(:grid_item, :in_inventory, grid_item_definition: eyes_def, grid_hackr: hackr)
      eyes_item.update!(equipped_slot: "eyes")

      effects = hackr.loadout_effects
      expect(effects["bonus_max_health"]).to eq(15.0)
      expect(effects["bonus_max_energy"]).to eq(10.0)
    end
  end

  describe "effective_max" do
    it "returns 100 with no gear" do
      expect(hackr.effective_max("health")).to eq(100)
    end

    it "returns boosted cap with gear equipped" do
      gear_item.update!(equipped_slot: "head")
      expect(hackr.effective_max("health")).to eq(110)
    end
  end

  describe "loadout_by_slot" do
    it "returns all 13 slots" do
      loadout = hackr.loadout_by_slot
      expect(loadout.keys).to eq(GridItem::GEAR_SLOTS)
    end

    it "shows equipped items in correct slots" do
      gear_item.update!(equipped_slot: "head")
      loadout = hackr.loadout_by_slot
      expect(loadout["head"]).to eq(gear_item)
      expect(loadout["eyes"]).to be_nil
    end
  end
end
