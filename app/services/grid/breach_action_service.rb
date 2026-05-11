# frozen_string_literal: true

module Grid
  class BreachActionService
    ExecResult = Data.define(:hit, :damage_dealt, :program_name, :target_position,
      :protocol_destroyed, :battery_consumed, :all_destroyed, :exploit, :fragment, :debuff_hint)
    AnalyzeResult = Data.define(:target_position, :level_reached, :info_revealed, :bonus_action, :debuff_hint)
    RerouteResult = Data.define(:target_position, :protocol_type_label)
    UseItemResult = Data.define(:item_name, :effect_output, :emergency_jackout)
    InterfaceResult = Data.define(:gate_id, :correct, :gate_state, :attempts_remaining, :all_solved, :all_failed, :feedback)
    CircuitProbeResult = Data.define(:gate_id, :probe_pair, :connected, :probes_remaining, :feedback)

    class NotInBreach < StandardError; end
    class NoActionsRemaining < StandardError; end
    class ProgramNotLoaded < StandardError; end
    class InsufficientBattery < StandardError; end
    class InvalidTarget < StandardError; end
    class ProtocolAlreadyDestroyed < StandardError; end
    class AlreadyRerouted < StandardError; end
    class ItemNotFound < StandardError; end
    class GateNotFound < StandardError; end
    class GateLocked < StandardError; end
    class GateAlreadySolved < StandardError; end
    class GateFailed < StandardError; end
    class NoProbesRemaining < StandardError; end

    WRONG_ANSWER_DETECTION_BUMP = 5

    def self.exec!(hackr:, program_name:, target_position:)
      new(hackr).exec!(program_name, target_position)
    end

    def self.analyze!(hackr:, target_position:)
      new(hackr).analyze!(target_position)
    end

    def self.reroute!(hackr:, target_position:)
      new(hackr).reroute!(target_position)
    end

    def self.use_item!(hackr:, item_name:)
      new(hackr).use_item!(item_name)
    end

    def self.interface!(hackr:, gate_id:, answer:)
      new(hackr).interface!(gate_id, answer)
    end

    def self.circuit_probe!(hackr:, gate_id:, probe_pair:)
      new(hackr).circuit_probe!(gate_id, probe_pair)
    end

    include Grid::ItemEffectApplier

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

      # Module gate: some software requires a specific module installed in DECK
      required_module = program.properties&.dig("requires_module")
      if required_module.present? && !deck.has_module?(required_module)
        raise ProgramNotLoaded, "#{program.name} requires module '#{required_module}' installed in DECK."
      end

      is_exploit = program.properties&.dig("software_category") == "exploit"

      # Exploit type-guard: check target_types BEFORE consuming action
      if is_exploit
        target_types = program.properties&.dig("target_types")
        if target_types.is_a?(Array) && target_types.any? && !target_types.include?(protocol.protocol_type)
          # Mismatch — action NOT consumed, exploit NOT destroyed
          raise InvalidTarget, "Exploit incompatible with #{protocol.type_label} protocol. Requires: #{target_types.map(&:upcase).join(", ")}."
        end
      end

      battery_cost = (program.properties&.dig("battery_cost") || 10).to_i
      if deck.deck_battery < battery_cost
        raise InsufficientBattery, "Insufficient battery. Need #{battery_cost}, have #{deck.deck_battery}."
      end

      damage = 0
      destroyed = false
      all_destroyed = false
      fragment_extracted = nil

      ActiveRecord::Base.transaction do
        breach.lock!
        @hackr.lock!
        deck.lock!
        protocol.lock!

        # Re-check actions after lock
        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

        # Re-check battery after lock
        raise InsufficientBattery, "Insufficient battery. Need #{battery_cost}, have #{deck.deck_battery}." if deck.deck_battery < battery_cost

        if is_exploit
          # Exploit: instant kill — protocol destroyed regardless of health
          damage = protocol.health
          destroyed = true
          protocol.update_columns(health: 0, state: "destroyed")
        else
          # Standard: compute damage normally
          damage = compute_damage(program, protocol)

          new_health = [protocol.health - damage, 0].max
          destroyed = new_health <= 0
          attrs = {health: new_health}
          attrs[:state] = "destroyed" if destroyed
          protocol.update_columns(attrs)
        end

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

        # Exploit consumed from DECK after successful use (one-shot)
        if is_exploit
          program.destroy!
        end

        # Utility fragment extraction: roll for fragment drop
        is_utility = program.properties&.dig("software_category") == "utility"
        if is_utility && damage > 0
          fragment_extracted = roll_fragment_extraction!(breach, protocol, program)
        end

        # Inspiration bump on successful hit
        bump_inspiration!(breach) if damage > 0

        # Check all-destroyed win condition
        all_destroyed = breach.all_protocols_destroyed?

        log_action!(breach, "exec", target_position, program.grid_item_definition&.slug, {
          hit: damage > 0,
          damage: damage,
          destroyed: destroyed,
          battery_consumed: battery_cost,
          exploit: is_exploit,
          fragment: fragment_extracted
        })
      end

      ExecResult.new(
        hit: damage > 0,
        damage_dealt: damage,
        program_name: program.name,
        target_position: target_position,
        protocol_destroyed: destroyed,
        battery_consumed: battery_cost,
        all_destroyed: all_destroyed,
        exploit: is_exploit,
        fragment: fragment_extracted,
        debuff_hint: energy_debuff_hint
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
            bonus_action: false,
            debuff_hint: nil
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
        bonus_action: bonus_action,
        debuff_hint: psyche_debuff_hint
      )
    end

    def use_item!(item_name)
      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach
      raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

      item = Grid::NameResolver.resolve(@hackr.grid_items.in_inventory(@hackr).where(item_type: "consumable"), item_name)
      raise ItemNotFound, "No consumable named '#{item_name}' in your inventory." unless item

      effect_output = nil
      emergency_jackout = false
      saved_name = item.name

      ActiveRecord::Base.transaction do
        breach.lock!
        @hackr.lock!

        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

        # Apply item effect (from ItemEffectApplier module)
        result = apply_item_effect(item, breach: breach)

        if result == :emergency_jackout
          emergency_jackout = true
          effect_output = "<span style='color: #22d3ee; font-weight: bold;'>EMERGENCY JACK-OUT INITIATED — PNR override engaged.</span>"
        else
          effect_output = result
        end

        # Consume the item
        if item.quantity > 1
          item.update!(quantity: item.quantity - 1)
        else
          item.destroy!
        end

        # Consume action
        breach.update!(actions_remaining: breach.actions_remaining - 1)

        log_action!(breach, "use", nil, nil, {
          item_name: saved_name,
          item_slug: item.grid_item_definition&.slug,
          effect_type: item.properties&.dig("effect_type"),
          emergency_jackout: emergency_jackout
        })
      end

      UseItemResult.new(
        item_name: saved_name,
        effect_output: effect_output,
        emergency_jackout: emergency_jackout
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

    def interface!(gate_id, answer)
      gate_id = gate_id.to_s.upcase

      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach
      raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

      puzzle_state = breach.meta&.dig("puzzle_state")
      raise GateNotFound, "No circumvention gates in this encounter." unless puzzle_state&.dig("gates")&.any?

      gate = puzzle_state["gates"][gate_id]
      raise GateNotFound, "No gate [#{gate_id}]." unless gate
      validate_gate_state!(gate_id, gate)

      # If breach is already won (e.g., protocols destroyed), don't waste the action
      raise GateAlreadySolved, "Encounter already complete." if breach.breach_won?

      correct = false
      gate_state = nil
      attempts_remaining = 0
      all_solved = false
      all_failed = false
      feedback = nil

      ActiveRecord::Base.transaction do
        breach.lock!
        @hackr.lock!

        raise NoActionsRemaining, "No actions remaining this round." if breach.actions_remaining <= 0

        # Re-read puzzle state after lock and re-validate
        puzzle_state = breach.meta["puzzle_state"]
        gate = puzzle_state["gates"][gate_id]
        validate_gate_state!(gate_id, gate)

        correct = answers_match?(gate["type"], gate["solution"], answer)

        if correct
          gate["state"] = "solved"
          puzzle_state["solved_count"] = puzzle_state["solved_count"].to_i + 1
          feedback = "ACCESS GRANTED"
          unlock_dependent_gates!(puzzle_state, gate_id)
        elsif gate["attempts_remaining"].to_i == Grid::BreachService::UNLIMITED_ATTEMPTS
          # Infinite attempts (facility BREACHes): never decrement, never fail
          hint = sequence_position_hint(gate, answer)
          feedback = "Incorrect — try again"
          feedback = "#{feedback}. #{hint}" if hint
        else
          gate["attempts_remaining"] = gate["attempts_remaining"].to_i - 1
          if gate["attempts_remaining"] <= 0
            gate["state"] = "failed"
            feedback = "LOCKED OUT — all attempts exhausted"
          else
            hint = sequence_position_hint(gate, answer)
            feedback = "Incorrect — #{gate["attempts_remaining"]} attempt(s) remaining"
            feedback = "#{feedback}. #{hint}" if hint
          end
        end

        gate_state = gate["state"]
        attempts_remaining = gate["attempts_remaining"].to_i

        # Wrong answers raise the alarm — detection bump per failed attempt
        detection_bump = correct ? 0 : WRONG_ANSWER_DETECTION_BUMP
        new_detection = [breach.detection_level + detection_bump, 100].min

        breach.update!(
          meta: breach.meta.merge("puzzle_state" => puzzle_state),
          actions_remaining: breach.actions_remaining - 1,
          detection_level: new_detection
        )

        all_solved = breach.all_circumvention_gates_solved?
        all_failed = !all_solved && breach.breach_unwinnable?

        log_action!(breach, "interface", gate_id, nil, {
          gate_id: gate_id,
          correct: correct,
          gate_state: gate_state,
          attempts_remaining: attempts_remaining
        })
      end

      InterfaceResult.new(
        gate_id: gate_id.upcase,
        correct: correct,
        gate_state: gate_state,
        attempts_remaining: attempts_remaining,
        all_solved: all_solved,
        all_failed: all_failed,
        feedback: feedback
      )
    end

    # Test a single circuit connection without consuming an action.
    # Costs 1 probe from the gate's budget. Re-probing a cached pair is free.
    def circuit_probe!(gate_id, probe_pair)
      gate_id = gate_id.to_s.upcase

      breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless breach

      puzzle_state = breach.meta&.dig("puzzle_state")
      raise GateNotFound, "No circumvention gates in this encounter." unless puzzle_state&.dig("gates")&.any?

      gate = puzzle_state["gates"][gate_id]
      raise GateNotFound, "No gate [#{gate_id}]." unless gate
      validate_gate_state!(gate_id, gate)

      raise InvalidTarget, "Probes are only available for circuit gates." unless gate["type"] == "circuit"

      # Normalize pair: upcase, sort halves canonically
      parts = probe_pair.to_s.strip.upcase.split("-")
      raise InvalidTarget, "Invalid probe format. Use: interface #{gate_id} probe NODE1-NODE2" unless parts.size == 2

      # Validate both nodes exist in the circuit
      display = gate["display"] || {}
      valid_nodes = ((display["left_nodes"] || []) + (display["right_nodes"] || [])).map(&:upcase)
      parts.each do |node|
        raise InvalidTarget, "Unknown node '#{node}'. Check the circuit layout with 'status'." unless valid_nodes.include?(node)
      end

      normalized = parts.sort.join("-")

      # Return cached result for already-probed pairs (no budget cost)
      probe_results = gate["probe_results"] || {}
      if probe_results.key?(normalized)
        prev = probe_results[normalized]
        label = prev ? "CONNECTED \u2713" : "NO SIGNAL \u2717"
        return CircuitProbeResult.new(
          gate_id: gate_id, probe_pair: normalized, connected: prev,
          probes_remaining: gate["probes_remaining"].to_i,
          feedback: "Already probed: #{label}"
        )
      end

      raise NoProbesRemaining, "No probes remaining for gate [#{gate_id}]. Submit your answer." if gate["probes_remaining"].to_i <= 0

      connected = false

      ActiveRecord::Base.transaction do
        breach.lock!

        # Re-read state after lock — another request may have probed the same pair
        puzzle_state = breach.meta["puzzle_state"]
        gate = puzzle_state["gates"][gate_id]

        # Re-check cache and budget after lock
        if gate["probe_results"]&.key?(normalized)
          prev = gate["probe_results"][normalized]
          label = prev ? "CONNECTED \u2713" : "NO SIGNAL \u2717"
          return CircuitProbeResult.new(
            gate_id: gate_id, probe_pair: normalized, connected: prev,
            probes_remaining: gate["probes_remaining"].to_i,
            feedback: "Already probed: #{label}"
          )
        end
        raise NoProbesRemaining, "No probes remaining for gate [#{gate_id}]. Submit your answer." if gate["probes_remaining"].to_i <= 0

        solution_pairs = gate["solution"].split
        connected = solution_pairs.include?(normalized)

        gate["probe_results"] ||= {}
        gate["probe_results"][normalized] = connected
        gate["probes_remaining"] = gate["probes_remaining"].to_i - 1

        breach.update!(meta: breach.meta.merge("puzzle_state" => puzzle_state))

        log_action!(breach, "probe", gate_id, nil, {
          gate_id: gate_id, probe_pair: normalized,
          connected: connected, probes_remaining: gate["probes_remaining"]
        })
      end

      label = connected ? "CONNECTED \u2713 \u2014 signal path confirmed" : "NO SIGNAL \u2717 \u2014 path rejected"
      CircuitProbeResult.new(
        gate_id: gate_id, probe_pair: normalized, connected: connected,
        probes_remaining: gate["probes_remaining"],
        feedback: label
      )
    end

    private

    attr_reader :hackr

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end

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

    # Roll for fragment drop from utility software execution.
    # Fragments are pending on the breach — only granted on success.
    def roll_fragment_extraction!(breach, protocol, program)
      chance = (program.properties&.dig("fragment_chance") || 0.25).to_f
      return nil unless rand < chance

      # Determine fragment type from the protocol being targeted
      fragment_slug = "#{protocol.protocol_type}-fragment"
      pending = breach.meta["pending_fragments"] || []
      pending << fragment_slug
      breach.update!(meta: breach.meta.merge("pending_fragments" => pending))

      fragment_slug
    end

    # Compare player answer to stored solution. Normalization varies by puzzle type.
    def answers_match?(type, stored_solution, provided_answer)
      case type
      when "sequence"
        # Case-insensitive, space-separated tokens
        normalize_tokens(provided_answer) == normalize_tokens(stored_solution)
      when "logic_gate"
        # Evaluate any valid input combination — stored solution is "GATE_TYPE:TARGET:INPUT_COUNT"
        validate_logic_gate_answer(stored_solution, provided_answer)
      when "circuit"
        # Sort pairs before compare (order doesn't matter)
        normalize_circuit(provided_answer) == normalize_circuit(stored_solution)
      when "credential"
        # Exact match (case-sensitive — passwords are case-sensitive)
        provided_answer.strip == stored_solution
      else
        provided_answer.strip.upcase == stored_solution.strip.upcase
      end
    end

    def validate_logic_gate_answer(stored_solution, provided_answer)
      gate_type, target, input_count_str = stored_solution.split(":")
      input_count = input_count_str.to_i
      tokens = provided_answer.strip.upcase.split
      return false unless tokens.size == input_count
      return false unless tokens.all? { |t| %w[HIGH LOW].include?(t) }

      bools = tokens.map { |t| t == "HIGH" }
      result = Grid::PuzzleGeneratorService.evaluate_gate(gate_type, bools)
      (result ? "HIGH" : "LOW") == target
    end

    def normalize_tokens(str)
      str.to_s.strip.upcase.split.join(" ")
    end

    def normalize_circuit(str)
      str.to_s.strip.upcase.split.map { |pair|
        pair.split("-").sort.join("-")
      }.sort.join(" ")
    end

    def validate_gate_state!(gate_id, gate)
      raise GateAlreadySolved, "Gate [#{gate_id}] is already complete." if gate["state"] == "solved" || gate["state"] == "bypassed"
      raise GateFailed, "Gate [#{gate_id}] is locked out — all attempts exhausted." if gate["state"] == "failed"
      raise GateLocked, "Gate [#{gate_id}] is locked — solve #{gate["depends_on"]} first." if gate["state"] == "locked"
    end

    # Wordle-style progressive hint for sequence puzzles.
    # Shows which positions are correct (✓) and which are wrong (✗).
    def sequence_position_hint(gate, answer)
      return nil unless gate["type"] == "sequence"

      solution_tokens = gate["solution"].to_s.strip.upcase.split
      answer_tokens = answer.to_s.strip.upcase.split
      return nil if answer_tokens.empty?

      hints = solution_tokens.each_with_index.map do |node, i|
        if i < answer_tokens.size && answer_tokens[i] == node
          "\u2713#{node}"
        else
          "\u2717"
        end
      end
      "Positions: #{hints.join(" ")}"
    end

    def unlock_dependent_gates!(puzzle_state, solved_gate_id)
      puzzle_state["gates"].each do |_id, gate|
        next unless gate["state"] == "locked"
        next unless gate["depends_on"] == solved_gate_id
        gate["state"] = "active"
      end
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

    # Debuff hint for exec output — tells the player why damage is reduced/zero
    def energy_debuff_hint
      energy = @hackr.stat("energy")
      max_energy = @hackr.effective_max("energy")
      return "ENERGY depleted — damage output disabled." if energy <= 0
      ratio = energy.to_f / max_energy
      if ratio < 0.10
        "Low ENERGY — damage reduced to 50%."
      elsif ratio < 0.25
        "Low ENERGY — damage reduced to 75%."
      elsif ratio < 0.50
        "Low ENERGY — damage reduced to 90%."
      end
    end

    # Debuff hint for analyze output — tells the player intel may be unreliable
    def psyche_debuff_hint
      psyche = @hackr.stat("psyche")
      max_psyche = @hackr.effective_max("psyche")
      return "PSYCHE depleted — intel unreliable." if psyche <= 0
      ratio = psyche.to_f / max_psyche
      if ratio < 0.10
        "Low PSYCHE — high chance of false intel."
      elsif ratio < 0.25
        "Low PSYCHE — intel may be unreliable."
      elsif ratio < 0.50
        "Low PSYCHE — slight chance of false intel."
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
