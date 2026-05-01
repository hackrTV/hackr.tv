# frozen_string_literal: true

module Grid
  class BreachService
    StartResult = Data.define(:hackr_breach, :protocols, :display)
    EndRoundResult = Data.define(:hackr_breach, :state, :protocol_messages, :display, :failure_display)
    ResolveResult = Data.define(:hackr_breach, :xp_awarded, :cred_awarded, :xp_result, :display)
    FailureResult = Data.define(:hackr_breach, :vitals_hit, :zone_lockout_minutes, :fried_level, :software_wiped, :captured, :display)
    JackoutResult = Data.define(:hackr_breach, :clean, :vitals_hit, :display)

    class AlreadyInBreach < StandardError; end
    class NoDeckEquipped < StandardError; end
    class DeckFried < StandardError; end
    class ClearanceBlocked < StandardError; end
    class NotInBreach < StandardError; end
    class TemplateGated < StandardError; end

    # Clearance → action ceiling lookup table (hand-tuned per architecture doc)
    BREACH_RANK_TABLE = {
      (0..4) => {rank: "Script Kiddie", ceiling: 1},
      (5..9) => {rank: "Packet Rat", ceiling: 2},
      (10..19) => {rank: "Socket Jockey", ceiling: 3},
      (20..29) => {rank: "Netcutter", ceiling: 4},
      (30..39) => {rank: "Exploit Artist", ceiling: 5},
      (40..49) => {rank: "Signal Ghost", ceiling: 6},
      (50..59) => {rank: "Phantom Thread", ceiling: 7},
      (60..69) => {rank: "Zero-Day Broker", ceiling: 8},
      (70..79) => {rank: "Kernel Surgeon", ceiling: 9},
      (80..89) => {rank: "Root Operator", ceiling: 11},
      (90..98) => {rank: "Void Architect", ceiling: 13},
      (99..99) => {rank: "████████████", ceiling: 16}
    }.freeze

    TRACE_DETECTION_BONUS = 4
    UNLIMITED_ATTEMPTS = -1 # Sentinel for infinite puzzle gate attempts (facility BREACHes)

    # Failure modes that trigger DECK consequences and capture eligibility.
    # :health_zero is excluded — dying in a breach skips DECK frying and capture.
    DECK_CONSEQUENCE_MODES = %i[detection_overflow gate_exhaustion].freeze

    def self.breach_rank(clearance)
      BREACH_RANK_TABLE.find { |range, _| range.include?(clearance.to_i) }&.last
    end

    def self.start!(hackr:, encounter:)
      new(hackr).start!(encounter)
    end

    def self.start_ambient!(hackr:, template:)
      new(hackr).start_ambient!(template)
    end

    def self.start_sandbox!(hackr:, template:)
      new(hackr).start_sandbox!(template)
    end

    def self.end_round!(hackr_breach:)
      new(hackr_breach.grid_hackr).end_round!(hackr_breach)
    end

    def self.resolve_success!(hackr_breach:)
      new(hackr_breach.grid_hackr).resolve_success!(hackr_breach)
    end

    def self.resolve_failure!(hackr_breach:, failure_mode: :detection_overflow)
      new(hackr_breach.grid_hackr).resolve_failure!(hackr_breach, failure_mode: failure_mode)
    end

    def self.jackout!(hackr:, emergency: false)
      new(hackr).jackout!(emergency: emergency)
    end

    # List voluntary encounters in a room, respecting cooldowns and gates.
    # Lazy expiration: expired cooldowns are flushed on read rather than via
    # a background job. Each check_cooldown! is a single UPDATE when the timer
    # has elapsed, no-op otherwise. Acceptable trade-off vs. cron infrastructure.
    def self.available_encounters(room:, hackr: nil)
      encounters = room.grid_breach_encounters
        .not_depleted
        .includes(:grid_breach_template)
        .select { |enc| enc.grid_breach_template.published? }

      # Flush expired cooldowns (lazy expiration — see class comment above)
      encounters.each(&:check_cooldown!)

      # Filter to available state after cooldown check
      encounters = encounters.select(&:available?)

      # Apply hackr-specific gates if provided
      if hackr
        cl = hackr.stat("clearance")
        encounters = encounters.select { |enc| cl >= enc.min_clearance }
      end

      encounters.sort_by { |enc| enc.grid_breach_template.position }
    end

    # Returns all non-depleted encounters in room for display, including locked ones.
    # Each entry: { encounter:, template:, available:, locked_reason: }
    # Used by look_command to show "[LOCKED]" indicators on gated encounters.
    def self.listed_encounters(room:, hackr: nil)
      encounters = room.grid_breach_encounters
        .not_depleted
        .includes(:grid_breach_template)
        .select { |enc| enc.grid_breach_template.published? }

      encounters.each(&:check_cooldown!)
      encounters = encounters.reject(&:active?)

      cl = hackr ? hackr.stat("clearance") : 0

      encounters.sort_by { |enc| enc.grid_breach_template.position }.map do |enc|
        t = enc.grid_breach_template
        locked_reason = nil

        if !enc.available?
          locked_reason = "ON COOLDOWN"
        elsif hackr && cl < t.min_clearance
          locked_reason = "CLEARANCE #{t.min_clearance} REQUIRED"
        elsif t.requires_mission_slug.present? && hackr
          completed = hackr.grid_hackr_missions
            .joins(:grid_mission)
            .exists?(grid_missions: {slug: t.requires_mission_slug}, status: "completed")
          locked_reason = "MISSION REQUIRED" unless completed
        elsif t.requires_item_slug.present? && hackr
          has_item = hackr.grid_items.joins(:grid_item_definition)
            .exists?(grid_item_definitions: {slug: t.requires_item_slug})
          locked_reason = "KEY ITEM REQUIRED" unless has_item
        end

        {encounter: enc, template: t, available: locked_reason.nil?, locked_reason: locked_reason}
      end
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def start!(encounter)
      raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?

      template = encounter.grid_breach_template
      raise TemplateGated, "This encounter is not available." unless template.published?
      raise TemplateGated, "This encounter is not available." unless encounter.available?

      cl = @hackr.stat("clearance")
      if cl < template.min_clearance
        raise ClearanceBlocked, "Requires CLEARANCE #{template.min_clearance}. You are CLEARANCE #{cl}."
      end

      deck = @hackr.equipped_deck
      raise NoDeckEquipped, "No DECK equipped. Equip a DECK before initiating a BREACH." unless deck
      raise DeckFried, "DECK is fried (level #{deck.deck_fried_level}/5). Repair it before initiating a BREACH." if deck.deck_fried?

      breach = nil
      protocols = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!
        encounter.lock!

        # Re-check availability after lock
        raise TemplateGated, "This encounter is not available." unless encounter.available?

        # Mission prerequisite gate
        if template.requires_mission_slug.present?
          completed = @hackr.grid_hackr_missions
            .joins(:grid_mission)
            .exists?(grid_missions: {slug: template.requires_mission_slug}, status: "completed")
          raise TemplateGated, "Requires completed mission: #{template.requires_mission_slug}." unless completed
        end

        # Item prerequisite gate
        if template.requires_item_slug.present?
          has_item = @hackr.grid_items.joins(:grid_item_definition)
            .exists?(grid_item_definitions: {slug: template.requires_item_slug})
          raise TemplateGated, "Requires item: #{template.requires_item_slug}." unless has_item
        end

        # Mark encounter as active
        encounter.update!(state: "active")

        initial_actions = 1 # Always start with 1 action — inspiration ramps during encounter

        breach = GridHackrBreach.create!(
          grid_hackr: @hackr,
          grid_breach_template: template,
          grid_breach_encounter: encounter,
          origin_room_id: @hackr.current_room_id,
          state: "active",
          detection_level: 0,
          pnr_threshold: template.pnr_threshold,
          round_number: 1,
          inspiration: 0,
          actions_this_round: initial_actions,
          actions_remaining: initial_actions,
          reward_multiplier: 1.0,
          started_at: Time.current
        )

        protocols = generate_protocols!(breach, template)
        generate_puzzle_gates!(breach, template)
      end

      display = Grid::BreachRenderer.new(breach, protocols).render_full
      StartResult.new(hackr_breach: breach, protocols: protocols, display: display)
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyInBreach, "You are already in a BREACH encounter."
    end

    # Start an ambient encounter (no persistent GridBreachEncounter record).
    # Called by BreachGeneratorService when a random encounter triggers.
    def start_ambient!(template)
      raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?

      deck = @hackr.equipped_deck
      raise NoDeckEquipped, "No DECK equipped." unless deck
      raise DeckFried, "DECK is fried. Repair it before initiating a BREACH." if deck.deck_fried?

      cl = @hackr.stat("clearance")
      if cl < template.min_clearance
        raise ClearanceBlocked, "Requires CLEARANCE #{template.min_clearance}. You are CLEARANCE #{cl}."
      end

      breach = nil
      protocols = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!

        # Re-check after lock (another request may have started a breach)
        raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?

        breach = GridHackrBreach.create!(
          grid_hackr: @hackr,
          grid_breach_template: template,
          grid_breach_encounter: nil,
          origin_room_id: @hackr.current_room_id,
          state: "active",
          detection_level: 0,
          pnr_threshold: template.pnr_threshold,
          round_number: 1,
          inspiration: 0,
          actions_this_round: 1,
          actions_remaining: 1,
          reward_multiplier: 1.0,
          started_at: Time.current
        )

        protocols = generate_protocols!(breach, template)
        generate_puzzle_gates!(breach, template)
      end

      display = Grid::BreachRenderer.new(breach, protocols).render_full
      StartResult.new(hackr_breach: breach, protocols: protocols, display: display)
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyInBreach, "You are already in a BREACH encounter."
    end

    # Start a sandbox (dry-run) breach. Bypasses all gates (clearance, mission,
    # item prerequisites). No encounter record. Requires DECK equipped + not fried.
    # Snapshots hackr vitals + DECK battery; restored on breach end.
    def start_sandbox!(template)
      raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?

      deck = @hackr.equipped_deck
      raise NoDeckEquipped, "No DECK equipped. Equip a DECK before initiating a BREACH." unless deck
      raise DeckFried, "DECK is fried (level #{deck.deck_fried_level}/5). Repair it before initiating a BREACH." if deck.deck_fried?

      breach = nil
      protocols = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!
        raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?

        breach = GridHackrBreach.create!(
          grid_hackr: @hackr,
          grid_breach_template: template,
          grid_breach_encounter: nil,
          origin_room_id: @hackr.current_room_id,
          state: "active",
          detection_level: 0,
          pnr_threshold: template.pnr_threshold,
          round_number: 1,
          inspiration: 0,
          actions_this_round: 1,
          actions_remaining: 1,
          reward_multiplier: 1.0,
          started_at: Time.current,
          meta: {
            "sandbox" => true,
            "sandbox_snapshot" => {
              "deck_id" => deck.id,
              "deck_battery" => deck.deck_battery,
              "health" => @hackr.stat("health"),
              "energy" => @hackr.stat("energy"),
              "psyche" => @hackr.stat("psyche"),
              "inspiration" => @hackr.stat("inspiration")
            }
          }
        )

        protocols = generate_protocols!(breach, template)
        generate_puzzle_gates!(breach, template)
      end

      display = Grid::BreachRenderer.new(breach, protocols).render_full
      StartResult.new(hackr_breach: breach, protocols: protocols, display: display)
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyInBreach, "You are already in a BREACH encounter."
    end

    def end_round!(hackr_breach)
      protocol_messages = []
      failure_display = nil
      restore_point_display = nil
      state = :ongoing

      ActiveRecord::Base.transaction do
        hackr_breach.lock!
        @hackr.lock!

        protocols = hackr_breach.grid_breach_protocols.alive.ordered.to_a

        # 1. Protocol ticks (system turn)
        # Break on death: if a tick kills the hackr, stop ticking remaining protocols.
        protocols.each do |protocol|
          messages = Grid::BreachProtocol::Engine.tick!(protocol, hackr_breach)
          protocol_messages.concat(messages)

          # Check for death between ticks
          @hackr.reload
          break if @hackr.stat("health") <= 0
        end

        # 1b. Health-at-zero check
        @hackr.reload
        if @hackr.stat("health") <= 0
          failure_result = resolve_failure!(hackr_breach, failure_mode: :health_zero)
          state = :health_zero
          failure_display = failure_result.display
        end

        unless state == :health_zero
          # 1c. Protocol synergies (evaluated after all ticks)
          synergy_result = evaluate_synergies!(hackr_breach, protocols)
          protocol_messages.concat(synergy_result[:messages])

          # 2. Detection increment
          hackr_breach.reload # re-read after protocol engine updates
          trace_count = hackr_breach.grid_breach_protocols.alive.where(protocol_type: "trace", state: "active").count
          base_rate = hackr_breach.grid_breach_template.base_detection_rate
          trace_bonus = trace_count * TRACE_DETECTION_BONUS

          # TRACE+TRACE synergy: double trace bonus when 2+ active
          trace_bonus *= 2 if synergy_result[:trace_synergy]

          detection_delta = base_rate + trace_bonus
          new_detection = [hackr_breach.detection_level + detection_delta, 100].min

          # 3. Inspiration ramp + action calculation for new round
          new_inspiration = compute_new_inspiration(hackr_breach)
          new_actions = actions_for_inspiration(new_inspiration)

          hackr_breach.update!(
            detection_level: new_detection,
            round_number: hackr_breach.round_number + 1,
            inspiration: new_inspiration,
            actions_this_round: new_actions,
            actions_remaining: new_actions
          )

          # 4. Check loss condition
          if new_detection >= 100
            failure_result = resolve_failure!(hackr_breach)
            state = :failure
            failure_display = failure_result.display
          end

          # 5. Check win condition (all protocols destroyed OR all circumvention gates solved)
          if state == :ongoing && hackr_breach.breach_won?
            state = :success
          end

          # 6. Check unwinnable (gate-only BREACH with all required gates failed)
          if state == :ongoing && hackr_breach.breach_unwinnable?
            failure_result = resolve_failure!(hackr_breach, failure_mode: :gate_exhaustion)
            state = :failure
            failure_display = failure_result.display
          end
        end
      end

      # RestorePoint™ admission happens outside the breach transaction
      # Sandbox breaches skip RestorePoint — vitals are restored by restore_sandbox_state!
      if state == :health_zero && !hackr_breach.sandbox?
        restore_result = Grid::RestorePointService.admit!(@hackr)
        restore_point_display = restore_result.display
      end

      # Reload protocols for display
      hackr_breach.reload
      display_parts = [Grid::BreachRenderer.new(hackr_breach).render_round_end(protocol_messages)]
      display_parts << failure_display if failure_display
      display_parts << restore_point_display if restore_point_display
      display = display_parts.join("\n")

      EndRoundResult.new(
        hackr_breach: hackr_breach,
        state: (state == :health_zero) ? :failure : state,
        protocol_messages: protocol_messages,
        display: display,
        failure_display: failure_display
      )
    end

    def resolve_success!(hackr_breach)
      return resolve_sandbox_end!(hackr_breach, "success") if hackr_breach.sandbox?

      template = hackr_breach.grid_breach_template
      xp_awarded = template.xp_reward
      cred_awarded = (template.cred_reward * hackr_breach.reward_multiplier).floor

      xp_result = nil
      fragments_granted = []

      ActiveRecord::Base.transaction do
        hackr_breach.lock!
        @hackr.lock!

        hackr_breach.update!(state: "success", ended_at: Time.current)

        # Transition encounter to cooldown
        transition_encounter_cooldown!(hackr_breach)

        # Grant XP
        xp_result = @hackr.grant_xp!(xp_awarded) if xp_awarded > 0

        # Increment breach completed stat
        current = @hackr.stat("breach_completed_count").to_i
        @hackr.set_stat!("breach_completed_count", current + 1)

        # Grant pending fragments from utility software extraction
        fragments_granted = grant_pending_fragments!(hackr_breach)
      end

      # Grant CRED outside transaction (TransactionService has its own mutex)
      if cred_awarded > 0
        cache = @hackr.default_cache
        if cache&.active?
          Grid::TransactionService.mint_gameplay!(
            to_cache: cache,
            amount: cred_awarded,
            memo: "BREACH: #{template.name}"
          )
        else
          Rails.logger.warn("[BreachService] skipped CRED for hackr=#{@hackr.id}: no active cache")
        end
      end

      display = Grid::BreachRenderer.new(hackr_breach).render_success(xp_awarded, cred_awarded, template.name, fragments_granted)
      ResolveResult.new(
        hackr_breach: hackr_breach,
        xp_awarded: xp_awarded,
        cred_awarded: cred_awarded,
        xp_result: xp_result || {leveled_up: false},
        display: display
      )
    end

    def resolve_failure!(hackr_breach, failure_mode: :detection_overflow)
      unless hackr_breach.state == "active"
        return FailureResult.new(hackr_breach: hackr_breach, vitals_hit: [], zone_lockout_minutes: nil, fried_level: nil, software_wiped: false, captured: false, display: "")
      end

      return resolve_sandbox_end!(hackr_breach, "failure", failure_mode: failure_mode) if hackr_breach.sandbox?

      template = hackr_breach.grid_breach_template
      vitals_hit = []
      zone_lockout_minutes = nil
      fried_level_set = nil
      software_wiped = false
      captured = false
      tier = template.tier

      # Determine failure path: standard consequences OR GovCorp capture.
      # Capture replaces lockout + DECK consequences — you're in custody instead.
      govcorp_capture = should_capture?(tier, failure_mode)

      # Wrap in transaction if not already inside one (end_round! calls this inside its own)
      wrap = !ActiveRecord::Base.connection.transaction_open?
      run = proc do
        hackr_breach.lock! if wrap
        @hackr.lock! if wrap

        hackr_breach.update!(state: "failure", ended_at: Time.current)

        # Transition encounter to cooldown
        transition_encounter_cooldown!(hackr_breach)

        # Tier 1: vitals drain (all tiers get this)
        vitals_hit << drain_vital!("energy", 20)
        vitals_hit << drain_vital!("psyche", 20)

        unless govcorp_capture
          # Standard failure path: lockout + DECK consequences + eject

          # Tier 2: zone lockout (standard+ encounters)
          unless tier == "ambient"
            zone_lockout_minutes = (1 + (hackr_breach.round_number / 3.0).floor).clamp(1, 10)

            zone = GridRoom.find_by(id: hackr_breach.origin_room_id)&.grid_zone
            if zone
              lockout_until = (Time.current + zone_lockout_minutes.minutes).to_i
              @hackr.set_stat!("zone_lockout_#{zone.id}", lockout_until)
            end
          end

          # Tier 3+4: DECK consequences (detection-overflow/gate-exhaustion, not health-zero)
          deck = @hackr.equipped_deck
          if deck && DECK_CONSEQUENCE_MODES.include?(failure_mode)
            if %w[advanced elite world_event].include?(tier)
              # Tier 4: DECK fried — compute level + wipe software
              fried_level_set = compute_fried_level(tier)
              deck.lock!
              deck.loaded_software.destroy_all
              deck.update!(properties: deck.properties.merge("fried_level" => fried_level_set))
              software_wiped = true
            elsif tier == "standard"
              # Tier 3: software wipe only (no fry)
              deck.lock!
              deck.loaded_software.destroy_all
              software_wiped = true
            end
          end

          # Eject to zone entry room
          eject_room_id = @hackr.zone_entry_room_id || hackr_breach.origin_room_id
          if eject_room_id && eject_room_id != @hackr.current_room_id
            @hackr.update!(current_room_id: eject_room_id)
          end
        end
        # Capture path is handled outside the transaction (ContainmentService has its own)
      end

      if wrap
        ActiveRecord::Base.transaction(&run)
      else
        run.call
      end

      # Tier 5+6: GovCorp capture (outside main transaction)
      capture_result = nil
      if govcorp_capture
        captured = true
        impound = %w[elite world_event].include?(tier) ||
          (tier == "advanced" && rand < Grid::ContainmentService::ADVANCED_IMPOUND_CHANCE)
        begin
          capture_result = Grid::ContainmentService.capture!(
            hackr: @hackr, breach: hackr_breach, impound: impound
          )
        rescue Grid::ContainmentService::AlreadyCaptured, Grid::ContainmentService::NoContainmentRoom => e
          Rails.logger.warn("[BreachService] Capture failed: #{e.message} — applying standard failure consequences")
          captured = false
          apply_standard_failure!(hackr_breach, tier, failure_mode, vitals_hit) do |result|
            zone_lockout_minutes = result[:zone_lockout_minutes]
            fried_level_set = result[:fried_level]
            software_wiped = result[:software_wiped]
          end
        end
      end

      vitals_hit.compact!
      display = Grid::BreachRenderer.new(hackr_breach).render_failure(
        vitals_hit, zone_lockout_minutes,
        fried_level: fried_level_set, software_wiped: software_wiped,
        failure_mode: failure_mode
      )
      display = [display, capture_result&.display].compact.join("\n") if capture_result

      FailureResult.new(
        hackr_breach: hackr_breach,
        vitals_hit: vitals_hit,
        zone_lockout_minutes: zone_lockout_minutes,
        fried_level: fried_level_set,
        software_wiped: software_wiped,
        captured: captured,
        display: display
      )
    end

    def jackout!(emergency: false)
      hackr_breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless hackr_breach

      return resolve_sandbox_end!(hackr_breach, "jacked_out") if hackr_breach.sandbox?

      clean = emergency || !hackr_breach.pnr_crossed?
      vitals_hit = []

      ActiveRecord::Base.transaction do
        hackr_breach.lock!
        @hackr.lock!

        if clean
          vitals_hit << drain_vital!("energy", 5)
        else
          vitals_hit << drain_vital!("health", 10)
          vitals_hit << drain_vital!("energy", 15)
          vitals_hit << drain_vital!("psyche", 15)
        end

        hackr_breach.update!(state: "jacked_out", ended_at: Time.current)

        # Transition encounter to cooldown
        transition_encounter_cooldown!(hackr_breach)

        # Log jackout action
        GridHackrBreachLog.create!(
          grid_hackr_breach: hackr_breach,
          round: hackr_breach.round_number,
          action_type: "jackout",
          result: {clean: clean}
        )
      end

      vitals_hit.compact!
      display = Grid::BreachRenderer.new(hackr_breach).render_jackout(clean, vitals_hit)
      JackoutResult.new(hackr_breach: hackr_breach, clean: clean, vitals_hit: vitals_hit, display: display)
    end

    private

    # End a sandbox breach: mark terminal state, restore hackr snapshot.
    # Works inside or outside an existing transaction (resolve_failure! is
    # called from end_round!'s transaction; resolve_success!/jackout! are not).
    def resolve_sandbox_end!(hackr_breach, end_state, failure_mode: nil)
      wrap = !ActiveRecord::Base.connection.transaction_open?
      run = proc do
        hackr_breach.lock! if wrap
        @hackr.lock! if wrap
        hackr_breach.update!(state: end_state, ended_at: Time.current)
        restore_sandbox_state!(hackr_breach)
      end

      if wrap
        ActiveRecord::Base.transaction(&run)
      else
        run.call
      end

      display = Grid::BreachRenderer.new(hackr_breach).render_sandbox_end(end_state, failure_mode: failure_mode)

      case end_state
      when "success"
        ResolveResult.new(hackr_breach: hackr_breach, xp_awarded: 0, cred_awarded: 0, xp_result: {leveled_up: false}, display: display)
      when "failure"
        FailureResult.new(hackr_breach: hackr_breach, vitals_hit: [], zone_lockout_minutes: nil, fried_level: nil, software_wiped: false, captured: false, display: display)
      when "jacked_out"
        JackoutResult.new(hackr_breach: hackr_breach, clean: true, vitals_hit: [], display: display)
      end
    end

    # Restore hackr vitals and DECK battery from the sandbox snapshot.
    def restore_sandbox_state!(hackr_breach)
      snapshot = hackr_breach.meta&.dig("sandbox_snapshot")
      return unless snapshot

      new_stats = (@hackr.stats || {}).merge(
        "health" => snapshot["health"],
        "energy" => snapshot["energy"],
        "psyche" => snapshot["psyche"],
        "inspiration" => snapshot["inspiration"]
      )
      @hackr.update_column(:stats, new_stats)
      @hackr.stats = new_stats

      deck = GridItem.find_by(id: snapshot["deck_id"])
      deck&.update!(properties: deck.properties.merge("battery_current" => snapshot["deck_battery"]))
    end

    def generate_protocols!(breach, template)
      composition = template.protocols
      position = 0
      protocols = []

      composition.each do |entry|
        count = (entry["count"] || 1).to_i
        type = entry["type"]
        health = (entry["health"] || 50).to_i
        max_health = (entry["max_health"] || health).to_i
        charge = (entry["charge_rounds"] || 0).to_i
        weakness = entry["weakness"]

        count.times do
          protocols << GridBreachProtocol.create!(
            grid_hackr_breach: breach,
            protocol_type: type,
            health: health,
            max_health: max_health,
            weakness: weakness,
            state: (charge > 0) ? "charging" : "active",
            charge_rounds: charge,
            rounds_charging: 0,
            position: position,
            rerouted: false,
            meta: {}
          )
          position += 1
        end
      end

      protocols
    end

    # Generate puzzle circumvention gates from template definition.
    # Clearance reduces required gate count; psyche grants bonus attempts.
    def generate_puzzle_gates!(breach, template)
      gate_defs = template.puzzle_gate_definitions
      return if gate_defs.empty?

      clearance = @hackr.stat("clearance")
      psyche = @hackr.stat("psyche")
      total = gate_defs.size

      # no_clearance_bypass: facility containment locks — all gates must be solved
      if template.no_clearance_bypass
        bypass_count = 0
        attempts = UNLIMITED_ATTEMPTS
      else
        bypass_count = [(clearance / 30).floor, total - 1].min # Always leave at least 1 gate active
        # Base 3 attempts. Psyche bonus: +1 if psyche >= 50% of max
        max_psyche = @hackr.effective_max("psyche")
        psyche_bonus = (max_psyche > 0 && psyche.to_f / max_psyche >= 0.5) ? 1 : 0
        attempts = 3 + psyche_bonus
      end
      required_count = [1, total - bypass_count].max

      # Last N gates (by template order) are bypassed — hardest gates last convention
      bypassed_ids = gate_defs.last(bypass_count).map { |g| g["id"] }

      gates = {}
      gate_defs.each_with_index do |spec, idx|
        rng = Random.new(breach.id * 31 + idx)
        generated = Grid::PuzzleGeneratorService.generate(spec, rng)

        is_bypassed = bypassed_ids.include?(spec["id"])
        dep = spec["depends_on"]
        dep_is_bypassed = dep && bypassed_ids.include?(dep)

        initial_state = if is_bypassed
          "bypassed"
        elsif dep && !dep_is_bypassed
          "locked"
        else
          "active"
        end

        gate_data = {
          "type" => spec["type"],
          "state" => initial_state,
          "attempts_remaining" => is_bypassed ? 0 : attempts,
          "max_attempts" => is_bypassed ? 0 : attempts,
          "depends_on" => dep,
          "solution" => is_bypassed ? nil : generated[:solution],
          "display" => generated[:display_data]
        }

        # Circuit gates get a probe budget for interactive signal testing
        if spec["type"] == "circuit" && !is_bypassed
          gate_data["probes_remaining"] = generated[:display_data]["probe_budget"]
          gate_data["probe_results"] = {}
        end

        gates[spec["id"]] = gate_data
      end

      puzzle_state = {
        "required_count" => required_count,
        "solved_count" => 0,
        "gates" => gates
      }

      breach.update!(meta: breach.meta.merge("puzzle_state" => puzzle_state))
    end

    def compute_new_inspiration(hackr_breach)
      # Inspiration increases by 1 per successful offensive action this round,
      # capped at the clearance ceiling. For Phase 1, simple: +2 per round survived.
      ceiling = clearance_ceiling
      [hackr_breach.inspiration + 2, ceiling * 10].min
    end

    def actions_for_inspiration(inspiration)
      ceiling = clearance_ceiling
      return 1 if ceiling <= 1

      # Scale: inspiration 0 = 1 action, full inspiration = ceiling actions
      max_inspiration = ceiling * 10 # rough scale
      ratio = (max_inspiration > 0) ? (inspiration.to_f / max_inspiration) : 0
      [1, (ratio * ceiling).ceil].max.clamp(1, ceiling)
    end

    def clearance_ceiling
      rank_data = self.class.breach_rank(@hackr.stat("clearance"))
      rank_data ? rank_data[:ceiling] : 1
    end

    # Transition the encounter back to cooldown (or available if no cooldown).
    # Called inside the breach-ending transaction. Wrapped in rescue to prevent
    # a cooldown transition failure from leaving the encounter stuck in "active".
    def transition_encounter_cooldown!(hackr_breach)
      encounter = hackr_breach.grid_breach_encounter
      return unless encounter # Ambient encounters have no persistent record

      encounter.lock!
      encounter.start_cooldown!
    rescue => e
      Rails.logger.error("[BreachService] Failed to transition encounter #{encounter.id} to cooldown: #{e.message}")
      # Force encounter back to available so it's not stuck in "active"
      begin
        encounter.update_columns(state: "available", cooldown_until: nil)
      rescue
        nil
      end
    end

    # Grant pending fragments accumulated during the breach via utility software.
    # Called inside the success transaction. Returns array of granted fragment slugs.
    def grant_pending_fragments!(hackr_breach)
      pending = hackr_breach.meta&.dig("pending_fragments")
      return [] if pending.blank?

      granted = []
      pending.tally.each do |fragment_slug, qty|
        definition = GridItemDefinition.find_by(slug: fragment_slug)
        next unless definition

        granted_qty = 0
        qty.times do
          Grid::Inventory.grant_item!(hackr: @hackr, definition: definition)
          granted_qty += 1
        rescue Grid::InventoryErrors::InventoryFull
          Rails.logger.warn("[BreachService] Inventory full — fragment #{fragment_slug} skipped for hackr #{@hackr.id}")
          break
        end
        granted << {slug: fragment_slug, name: definition.name, quantity: granted_qty} if granted_qty > 0
      end

      # Update data_extracted stat
      total = pending.size
      if total > 0
        current = @hackr.stat("data_extracted_count").to_i
        @hackr.set_stat!("data_extracted_count", current + total)
      end

      granted
    end

    # Compute fried_level based on encounter tier and hackr clearance.
    # Higher clearance = weighted toward lower fried_level (better at damage control).
    # Only called for advanced/elite/world_event tiers (standard gets software wipe only, no fry).
    def compute_fried_level(tier)
      clearance = @hackr.stat("clearance")
      case tier
      when "advanced"
        # 2-3, weighted toward 2 for high clearance (clearance >= 40 = 70% chance of 2)
        if rand < ((clearance >= 40) ? 0.7 : 0.4)
          2
        else
          3
        end
      when "elite"
        # 3-4, weighted toward 3 for high clearance
        if rand < ((clearance >= 60) ? 0.65 : 0.35)
          3
        else
          4
        end
      when "world_event"
        5
      else
        1
      end
    end

    # Apply standard failure consequences (lockout + DECK + eject).
    # Used as fallback when capture attempt fails.
    def apply_standard_failure!(hackr_breach, tier, failure_mode, vitals_hit)
      zone_lockout_minutes = nil
      fried_level_set = nil
      software_wiped = false

      ActiveRecord::Base.transaction do
        @hackr.lock!

        # Tier 2: zone lockout
        unless tier == "ambient"
          zone_lockout_minutes = (1 + (hackr_breach.round_number / 3.0).floor).clamp(1, 10)
          zone = GridRoom.find_by(id: hackr_breach.origin_room_id)&.grid_zone
          if zone
            lockout_until = (Time.current + zone_lockout_minutes.minutes).to_i
            @hackr.set_stat!("zone_lockout_#{zone.id}", lockout_until)
          end
        end

        # Tier 3+4: DECK consequences
        deck = @hackr.equipped_deck
        if deck && DECK_CONSEQUENCE_MODES.include?(failure_mode)
          if %w[advanced elite world_event].include?(tier)
            fried_level_set = compute_fried_level(tier)
            deck.lock!
            deck.loaded_software.destroy_all
            deck.update!(properties: deck.properties.merge("fried_level" => fried_level_set))
            software_wiped = true
          elsif tier == "standard"
            deck.lock!
            deck.loaded_software.destroy_all
            software_wiped = true
          end
        end

        # Eject to zone entry room
        eject_room_id = @hackr.zone_entry_room_id || hackr_breach.origin_room_id
        if eject_room_id && eject_room_id != @hackr.current_room_id
          @hackr.update!(current_room_id: eject_room_id)
        end
      end

      yield({zone_lockout_minutes: zone_lockout_minutes, fried_level: fried_level_set, software_wiped: software_wiped})
    end

    # Determine whether this failure results in GovCorp capture.
    # Capture only on detection-overflow/gate-exhaustion, never health-zero.
    # Probabilistic: standard 25%, advanced 50%, elite+ 100%.
    def should_capture?(tier, failure_mode)
      return false unless DECK_CONSEQUENCE_MODES.include?(failure_mode)
      return false if Grid::ContainmentService.captured?(@hackr)

      case tier
      when "standard"
        rand < Grid::ContainmentService::STANDARD_CAPTURE_CHANCE
      when "advanced"
        rand < Grid::ContainmentService::ADVANCED_CAPTURE_CHANCE
      when "elite", "world_event"
        true
      else
        false
      end
    end

    def drain_vital!(key, amount)
      old = @hackr.stat(key)
      @hackr.adjust_vital!(key, -amount)
      new_val = @hackr.stat(key)
      return nil if old == new_val
      {vital: key, amount: old - new_val}
    end

    # Evaluate protocol synergies after all ticks.
    # Returns { messages: [], trace_synergy: bool }
    def evaluate_synergies!(hackr_breach, protocols)
      messages = []
      trace_synergy = false

      # Reload protocols to get fresh state after ticks
      active_types = protocols.select(&:alive?).select { |p| p.state == "active" }.map(&:protocol_type)
      type_counts = active_types.tally

      # TRACE+TRACE: detection rate doubled (consumed in detection calc)
      if type_counts.fetch("trace", 0) >= 2
        trace_synergy = true
        # Message emitted only on first occurrence. evaluate_synergies! runs before
        # round_number is incremented, so round_number == 1 on the first end_round! call.
        if hackr_breach.round_number <= 1
          messages << "<span style='color: #f59e0b; font-weight: bold;'>\u26a1 SYNERGY: TRACE\u00d7#{type_counts["trace"]} \u2014 detection rate doubled!</span>"
        end
      end

      # ADAPT+TRACE: adapted protocols harder to analyze
      # (mechanical effect applied in BreachActionService#analyze! via protocol.meta["adapted"])
      # Silent synergy — players discover it through analyze accuracy, not announcements.

      {messages: messages, trace_synergy: trace_synergy}
    end
  end
end
