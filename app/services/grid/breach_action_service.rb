# frozen_string_literal: true

module Grid
  class BreachActionService
    ExecResult = Data.define(:hit, :damage_dealt, :program_name, :target_position,
      :protocol_destroyed, :battery_consumed, :all_destroyed)
    AnalyzeResult = Data.define(:target_position, :level_reached, :info_revealed, :bonus_action)
    RerouteResult = Data.define(:target_position, :protocol_type_label)

    class NotInBreach < StandardError; end
    class NoActionsRemaining < StandardError; end
    class ProgramNotLoaded < StandardError; end
    class InsufficientBattery < StandardError; end
    class InvalidTarget < StandardError; end
    class ProtocolAlreadyDestroyed < StandardError; end
    class AlreadyRerouted < StandardError; end

    def self.exec!(hackr:, program_name:, target_position:)
      new(hackr).exec!(program_name, target_position)
    end

    def self.analyze!(hackr:, target_position:)
      new(hackr).analyze!(target_position)
    end

    def self.reroute!(hackr:, target_position:)
      new(hackr).reroute!(target_position)
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def exec!(program_name, target_position)
      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach
      raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

      deck = @hackr.equipped_deck
      raise ProgramNotLoaded, "No DECK equipped." unless deck

      program = find_loaded_program(deck, program_name)
      raise ProgramNotLoaded, "'#{program_name}' is not loaded in your DECK." unless program

      protocol = find_protocol(breach, target_position)

      battery_cost = (program.properties&.dig("battery_cost") || 10).to_i
      if deck.deck_battery < battery_cost
        raise InsufficientBattery, "Insufficient battery. Need #{battery_cost}, have #{deck.deck_battery}."
      end

      damage = 0
      destroyed = false
      all_destroyed = false

      ActiveRecord::Base.transaction do
        breach.lock!
        @hackr.lock!
        deck.lock!
        protocol.lock!

        # Re-check actions after lock
        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

        # Re-check battery after lock
        raise InsufficientBattery, "Insufficient battery. Need #{battery_cost}, have #{deck.deck_battery}." if deck.deck_battery < battery_cost

        # Compute damage
        damage = compute_damage(program, protocol)

        # Apply damage
        new_health = [protocol.health - damage, 0].max
        destroyed = new_health <= 0
        attrs = {health: new_health}
        attrs[:state] = "destroyed" if destroyed
        protocol.update_columns(attrs)

        if destroyed

          # Increment cumulative stat
          count = @hackr.stat("protocols_dismantled_count").to_i
          @hackr.set_stat!("protocols_dismantled_count", count + 1)
        end

        # Consume battery
        new_battery = deck.deck_battery - battery_cost
        deck.update!(properties: deck.properties.merge("battery_current" => new_battery))

        # Consume action
        breach.update!(actions_remaining: breach.actions_remaining - 1)

        # Inspiration bump on successful hit
        bump_inspiration!(breach) if damage > 0

        # Check all-destroyed win condition
        all_destroyed = breach.all_protocols_destroyed?

        log_action!(breach, "exec", target_position, program.grid_item_definition&.slug, {
          hit: damage > 0,
          damage: damage,
          destroyed: destroyed,
          battery_consumed: battery_cost
        })
      end

      ExecResult.new(
        hit: damage > 0,
        damage_dealt: damage,
        program_name: program.name,
        target_position: target_position,
        protocol_destroyed: destroyed,
        battery_consumed: battery_cost,
        all_destroyed: all_destroyed
      )
    end

    def analyze!(target_position)
      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach
      raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

      protocol = find_protocol(breach, target_position)

      level_reached = 0
      info_revealed = nil
      bonus_action = false

      ActiveRecord::Base.transaction do
        breach.lock!
        protocol.lock!

        # Re-check actions after lock
        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

        current_level = protocol.analyze_level
        if current_level >= 3
          # Already fully analyzed — still costs an action but reveals nothing new
          breach.update!(actions_remaining: breach.actions_remaining - 1)
          return AnalyzeResult.new(
            target_position: target_position,
            level_reached: current_level,
            info_revealed: "Already fully analyzed.",
            bonus_action: false
          )
        end

        level_reached = current_level + 1
        protocol.analyze_level = level_reached
        protocol.save!

        # Progressive reveal (with psyche degradation + ADAPT+TRACE penalty)
        wrong_info = psyche_wrong_info?(protocol)

        info_revealed = case level_reached
        when 1
          if wrong_info
            fake_type = (GridBreachProtocol::PROTOCOL_TYPES - [protocol.protocol_type]).sample
            "Protocol type identified: #{fake_type.upcase}."
          else
            "Protocol type identified: #{protocol.type_label}."
          end
        when 2
          weakness = protocol.weakness || Grid::BreachProtocol::Engine.weakness_for(protocol.protocol_type)
          # Assign weakness if not yet set
          if protocol.weakness.nil? && weakness
            protocol.update!(weakness: weakness)
          end
          if wrong_info
            fake_weakness = (%w[offensive defensive utility] - [protocol.weakness]).sample
            "Weakness revealed: #{fake_weakness}."
          else
            weakness_label = protocol.weakness || "none"
            "Weakness revealed: #{weakness_label}."
          end
        when 3
          "Full protocol analysis complete. Thresholds exposed."
        end

        # Bonus action roll (base 15% + gear effects)
        chance = 0.15 + @hackr.loadout_effects["breach_bonus_action_chance"].to_f
        bonus_action = rand < chance

        if bonus_action
          # Free action — don't decrement
        else
          breach.update!(actions_remaining: breach.actions_remaining - 1)
        end

        # Inspiration bump on analyze
        bump_inspiration!(breach)

        log_action!(breach, "analyze", target_position, nil, {
          level_reached: level_reached,
          info: info_revealed,
          bonus_action: bonus_action
        })
      end

      AnalyzeResult.new(
        target_position: target_position,
        level_reached: level_reached,
        info_revealed: info_revealed,
        bonus_action: bonus_action
      )
    end

    def reroute!(target_position)
      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach
      raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

      protocol = find_protocol(breach, target_position)
      raise AlreadyRerouted, "Protocol [#{target_position + 1}] is already rerouted." if protocol.rerouted?

      ActiveRecord::Base.transaction do
        breach.lock!
        protocol.lock!

        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0
        raise AlreadyRerouted, "Protocol [#{target_position + 1}] is already rerouted." if protocol.rerouted?

        # Can't reroute a protocol that's still charging or idle
        if protocol.state == "charging"
          raise InvalidTarget, "Protocol [#{target_position + 1}] is still charging — nothing to reroute."
        end
        if protocol.state == "idle"
          raise InvalidTarget, "Protocol [#{target_position + 1}] is idle — nothing to reroute."
        end

        protocol.update_columns(rerouted: true)

        # Consume action
        breach.update!(actions_remaining: breach.actions_remaining - 1)

        # Inspiration bump on reroute
        bump_inspiration!(breach)

        log_action!(breach, "reroute", target_position, nil, {
          protocol_type: protocol.protocol_type
        })
      end

      RerouteResult.new(
        target_position: target_position,
        protocol_type_label: protocol.type_label
      )
    end

    private

    def log_action!(breach, action_type, target_position, program_slug, result_data)
      GridHackrBreachLog.create!(
        grid_hackr_breach: breach,
        round: breach.round_number,
        action_type: action_type,
        target: target_position&.to_s,
        program_slug: program_slug,
        result: result_data
      )
    end

    def find_loaded_program(deck, name)
      deck.loaded_software.find { |s| s.name.downcase == name.to_s.downcase }
    end

    def find_protocol(breach, position)
      pos = position.to_i
      protocol = breach.grid_breach_protocols.find_by(position: pos)
      raise InvalidTarget, "No protocol at position #{pos + 1}." unless protocol
      raise ProtocolAlreadyDestroyed, "Protocol [#{pos + 1}] is already destroyed." if protocol.destroyed?
      protocol
    end

    def bump_inspiration!(breach)
      ceiling = Grid::BreachService.breach_rank(@hackr.stat("clearance"))&.dig(:ceiling) || 1
      max_inspiration = ceiling * 10
      new_inspiration = [breach.inspiration + 1, max_inspiration].min
      breach.update!(inspiration: new_inspiration)
    end

    def compute_damage(program, protocol)
      base = (program.properties&.dig("effect_magnitude") || 20).to_i

      # Weakness bonus: +50% if software category matches protocol weakness
      if protocol.weakness.present? &&
          program.properties&.dig("software_category") == protocol.weakness
        base = (base * 1.5).floor
      end

      # Target type restriction: if program has target_types, check if protocol matches
      target_types = program.properties&.dig("target_types")
      if target_types.is_a?(Array) && target_types.any?
        unless target_types.include?(protocol.protocol_type)
          base = (base * 0.5).floor # Reduced effectiveness against non-target types
        end
      end

      # Energy degradation: low energy reduces damage output
      energy_mult = energy_damage_multiplier
      return 0 if energy_mult <= 0.0 # 0 energy = no damage
      base = (base * energy_mult).floor

      [base, 1].max # Always deal at least 1 damage (when energy > 0)
    end

    # Energy scaling: damage reduction when energy is low.
    # 0 energy = no damage at all.
    def energy_damage_multiplier
      energy = @hackr.stat("energy")
      max_energy = @hackr.effective_max("energy")
      return 0.0 if energy <= 0
      ratio = energy.to_f / max_energy
      if ratio >= 0.50
        1.0
      elsif ratio >= 0.25
        0.90
      elsif ratio >= 0.10
        0.75
      else
        0.50
      end
    end

    # Psyche degradation: chance of wrong info during analyze.
    # ADAPT+TRACE synergy adds +15% wrong-info chance on adapted protocols.
    def psyche_wrong_info?(protocol)
      psyche = @hackr.stat("psyche")
      max_psyche = @hackr.effective_max("psyche")

      base_chance = if psyche <= 0
        1.0
      else
        ratio = psyche.to_f / max_psyche
        if ratio >= 0.50
          0.0
        elsif ratio >= 0.25
          0.10
        elsif ratio >= 0.10
          0.20
        else
          0.40
        end
      end

      # ADAPT+TRACE synergy: adapted protocols are harder to analyze
      base_chance += 0.15 if protocol.meta["adapted"]

      rand < base_chance
    end
  end
end
