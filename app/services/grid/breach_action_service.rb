# frozen_string_literal: true

module Grid
  class BreachActionService
    ExecResult = Data.define(:hit, :damage_dealt, :program_name, :target_position,
      :protocol_destroyed, :battery_consumed, :all_destroyed)
    AnalyzeResult = Data.define(:target_position, :level_reached, :info_revealed, :bonus_action)

    class NotInBreach < StandardError; end
    class NoActionsRemaining < StandardError; end
    class ProgramNotLoaded < StandardError; end
    class InsufficientBattery < StandardError; end
    class InvalidTarget < StandardError; end
    class ProtocolAlreadyDestroyed < StandardError; end

    def self.exec!(hackr:, program_name:, target_position:)
      new(hackr).exec!(program_name, target_position)
    end

    def self.analyze!(hackr:, target_position:)
      new(hackr).analyze!(target_position)
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

        # Progressive reveal
        info_revealed = case level_reached
        when 1
          "Protocol type identified: #{protocol.type_label}."
        when 2
          weakness = protocol.weakness || Grid::BreachProtocol::Engine.weakness_for(protocol.protocol_type)
          # Assign weakness if not yet set
          if protocol.weakness.nil? && weakness
            protocol.update!(weakness: weakness)
          end
          weakness_label = protocol.weakness || "none"
          "Weakness revealed: #{weakness_label}."
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
      end

      AnalyzeResult.new(
        target_position: target_position,
        level_reached: level_reached,
        info_revealed: info_revealed,
        bonus_action: bonus_action
      )
    end

    private

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

      [base, 1].max # Always deal at least 1 damage
    end
  end
end
