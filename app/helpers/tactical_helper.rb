module TacticalHelper
  # InventoryTab/SchematicsTab shared label maps.
  ITEM_TYPE_LABELS = {
    "gear" => "Gear", "software" => "Software", "module" => "Module", "firmware" => "Firmware",
    "consumable" => "Consumable", "material" => "Material", "data" => "Data", "tool" => "Tool",
    "rig_component" => "Rig Component", "collectible" => "Collectible", "faction" => "Faction", "fixture" => "Fixture"
  }.freeze

  EFFECT_LABELS = {
    "heal" => "Restores Health", "energy_restore" => "Restores Energy", "psyche_restore" => "Restores Psyche",
    "energize" => "Restores Energy", "psyche_boost" => "Restores Psyche",
    "inspire" => "Grants Inspiration", "deck_recharge" => "Recharges DECK Battery", "repair_deck" => "Repairs Fried DECK",
    "signal_flare" => "Reduces Detection", "emergency_jackout" => "Emergency BREACH Exit",
    "dmg" => "Damage", "detection_reduction" => "Detection Reduction"
  }.freeze

  # BreachPanel/DeckPage category colors.
  SOFTWARE_CATEGORY_COLORS = {
    "offensive" => "#f87171", "defensive" => "#60a5fa",
    "utility" => "#fbbf24", "exploit" => "#a78bfa"
  }.freeze

  ACTION_CONFIG = {
    "use" => {label: "USE", css: "use"},
    "equip" => {label: "EQUIP", css: "equip"},
    "drop" => {label: "DROP", css: "drop"},
    "salvage" => {label: "SALVAGE", css: "salvage"},
    "place" => {label: "PLACE", css: "place"},
    "sell" => {label: "SELL", css: "sell"}
  }.freeze

  # InventoryTab humanizeProperties port.
  def tactical_item_properties(props)
    props ||= {}
    result = []
    if props["slot"]
      result << ["Slot", GridHackr::Loadout::GEAR_SLOT_LABELS[props["slot"].to_s] || props["slot"].to_s.upcase]
    end
    result << ["Category", props["software_category"].to_s] if props["software_category"]
    if props["effect_type"]
      label = EFFECT_LABELS[props["effect_type"].to_s] || props["effect_type"].to_s
      mag = props["effect_magnitude"].to_i.nonzero? || props["amount"].to_i
      result << ["Effect", (mag > 0) ? "#{label} (#{mag})" : label]
    end
    targets = Array(props["target_types"])
    result << ["Targets", targets.join(", ")] if targets.any?
    result << ["Slot Cost", "#{props["slot_cost"]} slots"] if props["slot_cost"].to_i > 1
    result << ["Battery Cost", props["battery_cost"].to_s] if props["battery_cost"].to_i > 0
    result << ["Storage", "#{props["storage_capacity"]} slots"] if props["storage_capacity"]
    if props["effects"].is_a?(Hash)
      props["effects"].each do |k, v|
        result << [k.to_s.tr("_", " "), "+#{v}"] if v && v != 0 && v != false
      end
    end
    result
  end

  # InventoryTab actionHint port — feeds turbo_confirm strings.
  def tactical_action_hint(action, item)
    case action
    when "use" then (item.item_type == "consumable") ? "Item will be consumed." : ""
    when "equip"
      slot = item.properties&.dig("gear_slot")
      label = slot && (GridHackr::Loadout::GEAR_SLOT_LABELS[slot.to_s] || slot.to_s.upcase)
      label ? "Equips to #{label} slot." : ""
    when "drop" then "Item will be left on the ground."
    when "salvage" then "Item will be destroyed for XP."
    when "place" then "Fixture will be installed in your den."
    else ""
    end
  end

  # RepTab.tsx repBar port: ±1000 clamped onto 10 cells per side around
  # a center pivot, e.g. "░░░░░░░░░░│███░░░░░░░".
  def tactical_rep_bar(value)
    half = 10
    max_val = 1000
    clamped = value.clamp(-max_val, max_val)
    fill = ((clamped.abs * half).to_f / max_val).round

    left = (value < 0) ? "░" * (half - fill) + "█" * fill : "░" * half
    right = (value > 0) ? "█" * fill + "░" * (half - fill) : "░" * half
    "#{left}│#{right}"
  end
end
