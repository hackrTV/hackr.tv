# frozen_string_literal: true

module Grid
  class BreachService
    StartResult = Data.define(:hackr_breach, :protocols, :display)
    EndRoundResult = Data.define(:hackr_breach, :state, :protocol_messages, :display, :failure_display)
    ResolveResult = Data.define(:hackr_breach, :xp_awarded, :cred_awarded, :xp_result, :display)
    FailureResult = Data.define(:hackr_breach, :vitals_hit, :zone_lockout_minutes, :display)
    JackoutResult = Data.define(:hackr_breach, :clean, :vitals_hit, :display)

    class AlreadyInBreach < StandardError; end
    class NoDeckEquipped < StandardError; end
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

    def self.breach_rank(clearance)
      BREACH_RANK_TABLE.find { |range, _| range.include?(clearance.to_i) }&.last
    end

    def self.start!(hackr:, template:)
      new(hackr).start!(template)
    end

    def self.end_round!(hackr_breach:)
      new(hackr_breach.grid_hackr).end_round!(hackr_breach)
    end

    def self.resolve_success!(hackr_breach:)
      new(hackr_breach.grid_hackr).resolve_success!(hackr_breach)
    end

    def self.resolve_failure!(hackr_breach:)
      new(hackr_breach.grid_hackr).resolve_failure!(hackr_breach)
    end

    def self.jackout!(hackr:)
      new(hackr).jackout!
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def start!(template)
      raise AlreadyInBreach, "You are already in a BREACH encounter." if @hackr.in_breach?
      raise TemplateGated, "This encounter is not available." unless template.published?

      cl = @hackr.stat("clearance")
      if cl < template.min_clearance
        raise ClearanceBlocked, "Requires CLEARANCE #{template.min_clearance}. You are CLEARANCE #{cl}."
      end

      deck = @hackr.equipped_deck
      raise NoDeckEquipped, "No DECK equipped. Equip a DECK before initiating a BREACH." unless deck

      breach = nil
      protocols = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!

        # Mission prerequisite gate
        if template.requires_mission_slug.present?
          completed = @hackr.grid_mission_progresses
            .joins(:grid_mission)
            .exists?(grid_missions: {slug: template.requires_mission_slug}, state: "completed")
          raise TemplateGated, "Requires completed mission: #{template.requires_mission_slug}." unless completed
        end

        # Item prerequisite gate
        if template.requires_item_slug.present?
          has_item = @hackr.grid_items.joins(:grid_item_definition)
            .exists?(grid_item_definitions: {slug: template.requires_item_slug})
          raise TemplateGated, "Requires item: #{template.requires_item_slug}." unless has_item
        end

        # Cooldown gate
        if template.cooldown_min > 0
          last_breach = @hackr.grid_hackr_breaches
            .where(grid_breach_template: template)
            .where(state: %w[success failure jacked_out])
            .order(ended_at: :desc)
            .first
          if last_breach&.ended_at
            cooldown_seconds = [template.cooldown_min, template.cooldown_max].max
            cooldown_until = last_breach.ended_at + cooldown_seconds.seconds
            if Time.current < cooldown_until
              remaining = ((cooldown_until - Time.current) / 60.0).ceil
              raise TemplateGated, "Encounter on cooldown. Available in #{remaining} minute(s)."
            end
          end
        end

        initial_actions = 1 # Always start with 1 action — inspiration ramps during encounter

        breach = GridHackrBreach.create!(
          grid_hackr: @hackr,
          grid_breach_template: template,
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
          failure_result = resolve_failure!(hackr_breach)
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

          # 5. Check win condition (all protocols destroyed)
          if state == :ongoing && hackr_breach.all_protocols_destroyed?
            state = :success
          end
        end
      end

      # RestorePoint™ admission happens outside the breach transaction
      if state == :health_zero
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
      template = hackr_breach.grid_breach_template
      xp_awarded = template.xp_reward
      cred_awarded = (template.cred_reward * hackr_breach.reward_multiplier).floor

      xp_result = nil

      ActiveRecord::Base.transaction do
        hackr_breach.lock!
        @hackr.lock!

        hackr_breach.update!(state: "success", ended_at: Time.current)

        # Grant XP
        xp_result = @hackr.grant_xp!(xp_awarded) if xp_awarded > 0

        # Increment breach completed stat
        current = @hackr.stat("breach_completed_count").to_i
        @hackr.set_stat!("breach_completed_count", current + 1)
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

      display = Grid::BreachRenderer.new(hackr_breach).render_success(xp_awarded, cred_awarded, template.name)
      ResolveResult.new(
        hackr_breach: hackr_breach,
        xp_awarded: xp_awarded,
        cred_awarded: cred_awarded,
        xp_result: xp_result || {leveled_up: false},
        display: display
      )
    end

    def resolve_failure!(hackr_breach)
      unless hackr_breach.state == "active"
        return FailureResult.new(hackr_breach: hackr_breach, vitals_hit: [], zone_lockout_minutes: nil, display: "")
      end

      template = hackr_breach.grid_breach_template
      vitals_hit = []
      zone_lockout_minutes = nil
      tier = template.tier

      # Wrap in transaction if not already inside one (end_round! calls this inside its own)
      wrap = !ActiveRecord::Base.connection.transaction_open?
      run = proc do
        hackr_breach.lock! if wrap
        @hackr.lock! if wrap

        hackr_breach.update!(state: "failure", ended_at: Time.current)

        # Tier 1: vitals drain (all tiers get this)
        vitals_hit << drain_vital!("energy", 20)
        vitals_hit << drain_vital!("psyche", 20)

        # Tier 2: zone lockout (standard+ encounters)
        unless tier == "ambient"
          zone_lockout_minutes = (1 + (hackr_breach.round_number / 3.0).floor).clamp(1, 10)

          zone = GridRoom.find_by(id: hackr_breach.origin_room_id)&.grid_zone
          if zone
            lockout_until = (Time.current + zone_lockout_minutes.minutes).to_i
            @hackr.set_stat!("zone_lockout_#{zone.id}", lockout_until)
          end
        end

        # Eject to zone entry room
        eject_room_id = @hackr.zone_entry_room_id || hackr_breach.origin_room_id
        if eject_room_id && eject_room_id != @hackr.current_room_id
          @hackr.update!(current_room_id: eject_room_id)
        end
      end

      if wrap
        ActiveRecord::Base.transaction(&run)
      else
        run.call
      end

      vitals_hit.compact!
      display = Grid::BreachRenderer.new(hackr_breach).render_failure(vitals_hit, zone_lockout_minutes)
      FailureResult.new(
        hackr_breach: hackr_breach,
        vitals_hit: vitals_hit,
        zone_lockout_minutes: zone_lockout_minutes,
        display: display
      )
    end

    def jackout!
      hackr_breach = @hackr.active_breach
      raise NotInBreach, "You are not in a BREACH encounter." unless hackr_breach

      clean = !hackr_breach.pnr_crossed?
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
      end

      vitals_hit.compact!
      display = Grid::BreachRenderer.new(hackr_breach).render_jackout(clean, vitals_hit)
      JackoutResult.new(hackr_breach: hackr_breach, clean: clean, vitals_hit: vitals_hit, display: display)
    end

    private

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
