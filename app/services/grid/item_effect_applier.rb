# frozen_string_literal: true

module Grid
  # Shared item-effect logic used by both CommandParser (outside BREACH)
  # and BreachCommandParser (inside BREACH). Includer must provide:
  #   - hackr   (GridHackr)
  #   - h(text) (HTML escape helper)
  module ItemEffectApplier
    # Apply the effect of an item. Returns display string.
    # Pass breach: to enable BREACH-scoped effects (signal_flare, emergency_jackout, inspire).
    def apply_item_effect(item, breach: nil)
      props = (item.properties || {}).with_indifferent_access
      effect_type = props[:effect_type]

      case effect_type
      when "heal"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("health", amount)
        max_val = hackr.effective_max("health")
        "<span style='color: #34d399;'>You use #{h(item.name)}. Health restored by #{amount}. (#{new_val}/#{max_val})</span>"
      when "energize"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("energy", amount)
        max_val = hackr.effective_max("energy")
        "<span style='color: #60a5fa;'>You use #{h(item.name)}. Energy restored by #{amount}. (#{new_val}/#{max_val})</span>"
      when "psyche_boost"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("psyche", amount)
        max_val = hackr.effective_max("psyche")
        "<span style='color: #c084fc;'>You use #{h(item.name)}. Psyche boosted by #{amount}. (#{new_val}/#{max_val})</span>"
      when "deck_recharge"
        apply_deck_recharge(item, props)
      when "inspire"
        apply_inspire(item, props, breach)
      when "signal_flare"
        apply_signal_flare(item, props, breach)
      when "emergency_jackout"
        apply_emergency_jackout(item, props, breach)
      when "xp_boost"
        amount = props[:amount].to_i
        result = hackr.grant_xp!(amount)
        level_msg = result[:leveled_up] ? "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{result[:new_clearance]}!</span>" : ""
        "<span style='color: #fbbf24;'>You use #{h(item.name)}. +#{amount} XP.#{level_msg}</span>"
      when "repair_deck"
        apply_repair_deck(item, props)
      when "redeem_den"
        apply_redeem_den(item)
      else
        "<span style='color: #9ca3af;'>You use #{h(item.name)}. Nothing happens.</span>"
      end
    end

    private

    def apply_deck_recharge(item, props)
      amount = props[:amount].to_i
      deck = hackr.equipped_deck
      unless deck
        return "<span style='color: #f87171;'>No DECK equipped.</span>"
      end
      old_battery = deck.deck_battery
      new_battery = [old_battery + amount, deck.deck_battery_max].min
      deck.update!(properties: deck.properties.merge("battery_current" => new_battery))
      "<span style='color: #fbbf24;'>You use #{h(item.name)}. DECK battery restored by #{new_battery - old_battery}. (#{new_battery}/#{deck.deck_battery_max})</span>"
    end

    def apply_inspire(item, props, breach)
      unless breach
        return "<span style='color: #9ca3af;'>You use #{h(item.name)}... but the effect fizzles. Nothing to inspire outside a BREACH.</span>"
      end
      amount = props[:amount].to_i
      ceiling = Grid::BreachService.breach_rank(hackr.stat("clearance"))&.dig(:ceiling) || 1
      max_inspiration = ceiling * 10
      new_inspiration = [breach.inspiration + amount, max_inspiration].min
      gained = new_inspiration - breach.inspiration
      breach.update!(inspiration: new_inspiration)
      "<span style='color: #a78bfa;'>You use #{h(item.name)}. INSPIRATION +#{gained}. (#{new_inspiration}/#{max_inspiration})</span>"
    end

    def apply_signal_flare(item, props, breach)
      unless breach
        return "<span style='color: #9ca3af;'>You use #{h(item.name)}... but there's no signal to disrupt outside a BREACH.</span>"
      end
      amount = props[:amount].to_i
      old_detection = breach.detection_level
      new_detection = [old_detection - amount, 0].max
      reduction = old_detection - new_detection
      breach.update!(detection_level: new_detection)
      "<span style='color: #22d3ee;'>You use #{h(item.name)}. Detection reduced by #{reduction}%. (#{new_detection}%)</span>"
    end

    def apply_emergency_jackout(item, _props, breach)
      unless breach
        return "<span style='color: #9ca3af;'>You use #{h(item.name)}... but there's nothing to jack out of.</span>"
      end
      # Returns a sentinel that the caller checks to trigger a clean jackout
      :emergency_jackout
    end

    def apply_repair_deck(item, props)
      deck = hackr.equipped_deck
      unless deck
        return "<span style='color: #f87171;'>No DECK equipped.</span>"
      end
      unless deck.deck_fried?
        return "<span style='color: #9ca3af;'>Your DECK doesn't need repair.</span>"
      end

      kit_level = props[:kit_level].to_i
      fried = deck.deck_fried_level
      if kit_level < fried
        return "<span style='color: #f87171;'>Repair Kit Mk.#{kit_level} is insufficient for damage level #{fried}. Need Mk.#{fried}+ kit.</span>"
      end

      deck.update!(properties: deck.properties.merge("fried_level" => 0))
      "<span style='color: #34d399; font-weight: bold;'>You use #{h(item.name)}. DECK repaired \u2014 damage cleared (was level #{fried}/5).</span>"
    end

    def apply_redeem_den(item)
      den = Grid::DenService.new(hackr).create_den!(consume_item: item)
      "<span style='color: #a78bfa; font-weight: bold;'>DEN PROVISIONED.</span> " \
        "<span style='color: #d0d0d0;'>Your private node is ready in the Residential District.</span>\n" \
        "<span style='color: #9ca3af;'>Navigate to the Residential Corridor and enter: </span>" \
        "<span style='color: #22d3ee;'>go #{den.slug}</span>"
    rescue Grid::DenService::DenAlreadyExists
      "<span style='color: #f87171;'>You already have a den. The chip sizzles uselessly.</span>"
    end
  end
end
