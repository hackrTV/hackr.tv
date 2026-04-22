# frozen_string_literal: true

module GridHackr::Loadout
  extend ActiveSupport::Concern

  GEAR_SLOT_LABELS = {
    "deck" => "DECK",
    "back" => "BACK",
    "chest" => "CHEST",
    "head" => "HEAD",
    "ears" => "EARS",
    "eyes" => "EYES",
    "left_wrist" => "L.WRIST",
    "right_wrist" => "R.WRIST",
    "hands" => "HANDS",
    "neck" => "NECK",
    "waist" => "WAIST",
    "legs" => "LEGS",
    "feet" => "FEET"
  }.freeze

  # Returns Hash { slot => GridItem } for all 13 slots.
  def loadout_by_slot
    equipped = grid_items.equipped_by(self).includes(:grid_item_definition).index_by(&:equipped_slot)
    GridItem::GEAR_SLOTS.each_with_object({}) { |slot, h| h[slot] = equipped[slot] }
  end

  # Aggregate all effects from currently equipped gear.
  # Additive stacking for numeric values; boolean effects use logical OR.
  # Memoized per-instance to avoid repeated queries within a single request.
  def loadout_effects
    return @loadout_effects if defined?(@loadout_effects)
    @loadout_effects = grid_items.equipped_by(self).each_with_object(Hash.new(0)) do |item, acc|
      item.gear_effects.each do |key, value|
        if value == true || value == false
          acc[key] = false if acc[key] == 0
          acc[key] = acc[key] || value
        else
          acc[key] += value.to_f
        end
      end
    end
  end

  # Effective max for a vital, incorporating gear bonuses.
  # Base cap is 100. Gear effects key: "bonus_max_<vital>"
  def effective_max(vital)
    100 + loadout_effects["bonus_max_#{vital}"].to_i
  end

  # Clear memoized loadout effects (call after equip/unequip).
  def reset_loadout_cache!
    remove_instance_variable(:@loadout_effects) if defined?(@loadout_effects)
  end

  # Override inventory_capacity from Stats to include gear bonuses.
  def inventory_capacity
    GridHackr::Stats::INVENTORY_BASE_SLOTS + stat("bonus_inventory_slots").to_i + loadout_effects["bonus_inventory_slots"].to_i
  end
end
