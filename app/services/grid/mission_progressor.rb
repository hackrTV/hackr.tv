# frozen_string_literal: true

module Grid
  # Advances mission objective progress for a single hackr. Called from
  # Grid::CommandParser hooks (go/talk/take/give/use/salvage/buy) and
  # post-commit hooks on rep/clearance changes. Only emits HTML
  # notification strings when an objective transitions from incomplete
  # to completed — every other tick is silent.
  #
  # Lifecycle: instantiate once per request/job, call `record(...)` as
  # many times as needed, discard. The per-instance memoization on
  # active_hackr_missions avoids re-querying across multiple records
  # firing from one command (e.g. a single `go` emits :visit_room
  # AND :rooms_visited-equivalent mission events).
  class MissionProgressor
    def initialize(hackr)
      @hackr = hackr
    end

    # Record a gameplay event against all active missions. Returns an
    # array of inline HTML notifications for objectives that JUST
    # completed on this call; progress-only ticks are silent (spec).
    #
    # `context` keys expected per trigger_type:
    #   :visit_room       → room_slug:
    #   :talk_npc         → npc_name:  (case-insensitive match on target_slug)
    #   :collect_item     → item_name:, amount: (default 1)
    #   :deliver_item     → item_name:, npc_name:, amount: (default 1)
    #   :spend_cred       → amount:   (accumulator, capped at target_count)
    #   :buy_item         → item_name:, amount: (default 1)
    #   :reach_rep        → faction_slug:, rep_value:  (threshold; rep_value is NEW value)
    #   :reach_clearance  → clearance: (threshold; NEW value)
    #   :use_item         → item_name:
    #   :salvage_item     → item_name:, amount: (default 1)
    #   :salvage_yield_received → item_name:, amount: (default 1)
    #   :fabricate_item   → item_name: (name of crafted output item)
    def record(trigger_type, context = {})
      return [] unless @hackr

      matched_objectives = candidates_for(trigger_type)
      return [] if matched_objectives.empty?

      notifications = []

      matched_objectives.each do |pair|
        hackr_mission, objective = pair
        next unless objective_target_matches?(objective, trigger_type, context, hackr_mission)

        # accept! pre-creates a progress row per objective, so normally
        # `find_or_initialize_by` finds an existing record. But if a
        # definition gains a new objective AFTER a hackr has accepted
        # (admin edit, YAML re-seed), the first tick creates the row on
        # the fly. Two concurrent ticks could race on that create — the
        # retry mirrors ReputationService#adjust!'s two-step pattern.
        hackr_obj = hackr_mission.grid_hackr_mission_objectives
          .find_or_initialize_by(grid_mission_objective_id: objective.id)

        # Already done — don't re-notify or re-advance. Spec: state-change only.
        next if hackr_obj.completed_at.present?

        new_progress = next_progress_value(hackr_obj.progress.to_i, trigger_type, context, objective.target_count.to_i)
        next if new_progress == hackr_obj.progress.to_i

        hackr_obj.progress = new_progress
        just_completed = new_progress >= objective.target_count.to_i
        hackr_obj.completed_at = Time.current if just_completed
        begin
          hackr_obj.save!
        rescue ActiveRecord::RecordNotUnique
          # Another writer just created the row. Reload and retry once
          # with the latest persisted state so we don't clobber it.
          hackr_obj = hackr_mission.grid_hackr_mission_objectives
            .find_by!(grid_mission_objective_id: objective.id)
          next if hackr_obj.completed_at.present?
          next if new_progress <= hackr_obj.progress.to_i
          hackr_obj.progress = new_progress
          hackr_obj.completed_at = Time.current if just_completed
          hackr_obj.save!
        end

        if just_completed
          notifications << build_objective_completed_notification(hackr_mission, objective)
          ready_notif = build_ready_notification_if_applicable(hackr_mission, objective, hackr_obj)
          notifications << ready_notif if ready_notif
        end
      end

      notifications
    end

    private

    # Build [hackr_mission, objective] pairs for all active missions of this
    # hackr whose definition has an objective of the given type. Preloads
    # objectives + mission to avoid N+1 across the progressor's iteration.
    def candidates_for(trigger_type)
      active_hackr_missions.flat_map do |hackr_mission|
        hackr_mission.grid_mission.grid_mission_objectives
          .select { |o| o.objective_type == trigger_type.to_s }
          .map { |o| [hackr_mission, o] }
      end
    end

    def active_hackr_missions
      return @active_hackr_missions if defined?(@active_hackr_missions)
      @active_hackr_missions = @hackr.grid_hackr_missions.active
        .includes(grid_mission: :grid_mission_objectives).to_a
    end

    # True when the objective's target_slug matches the event context.
    # A blank target_slug is a wildcard — matches any room/npc/item of
    # that event type (used for "explore N rooms" etc.).
    def objective_target_matches?(objective, trigger_type, context, hackr_mission)
      target = objective.target_slug.to_s
      case trigger_type.to_s
      when "visit_room"
        target.blank? || target.casecmp?(context[:room_slug].to_s)
      when "complete_breach"
        target.blank? || target.casecmp?(context[:template_slug].to_s)
      when "dismantle_protocols"
        target.blank? || target.casecmp?(context[:protocol_type].to_s)
      when "talk_npc", "use_item", "salvage_item", "salvage_yield_received", "buy_item", "collect_item", "fabricate_item", "place_fixture", "equip_item"
        target.blank? || target.casecmp?(name_context(context).to_s)
      when "deliver_item"
        # Convention: `target_slug` holds the item name. The delivery
        # recipient is always the mission's giver_mob — this matches the
        # "bring X back to Y" RPG pattern and avoids a secondary target
        # column for v1. If future missions need drop-off NPCs distinct
        # from the giver, add a `secondary_target_slug` column.
        item_matches = target.blank? || target.casecmp?(context[:item_name].to_s)
        giver = hackr_mission.grid_mission.giver_mob
        npc_matches = giver.nil? || giver.name.to_s.casecmp?(context[:npc_name].to_s)
        item_matches && npc_matches
      when "spend_cred", "reach_rep", "reach_clearance"
        # Threshold triggers — target is a single faction (reach_rep) or
        # bare number (reach_clearance, spend_cred). For reach_rep the
        # target_slug pins the faction; others ignore target_slug.
        (trigger_type.to_s == "reach_rep") ? target.casecmp?(context[:faction_slug].to_s) : true
      else
        false
      end
    end

    # Map event context to the name used for string-match triggers.
    def name_context(context)
      context[:item_name] || context[:npc_name]
    end

    # Compute the new `progress` column value given the event semantics.
    # Event-style triggers increment by 1 (or by context[:amount] when
    # present). Threshold triggers (spend_cred accumulates, reach_rep /
    # reach_clearance take the NEW value directly) clamp to target_count
    # so the `progress >= target_count` completion check fires.
    def next_progress_value(current, trigger_type, context, target_count)
      case trigger_type.to_s
      when "visit_room", "talk_npc", "use_item", "fabricate_item", "place_fixture", "equip_item", "complete_breach"
        [current + 1, target_count].min
      when "collect_item", "deliver_item", "buy_item", "salvage_item", "salvage_yield_received", "dismantle_protocols"
        [current + context.fetch(:amount, 1).to_i, target_count].min
      when "spend_cred"
        [current + context[:amount].to_i, target_count].min
      when "reach_rep"
        [context[:rep_value].to_i, target_count].min
      when "reach_clearance"
        [context[:clearance].to_i, target_count].min
      else
        current
      end
    end

    def build_objective_completed_notification(hackr_mission, objective)
      mission_name = hackr_mission.grid_mission.name
      "<span style='color: #22d3ee;'>▸ MISSION</span> " \
        "<span style='color: #a78bfa;'>#{ERB::Util.html_escape(mission_name)}</span> " \
        "<span style='color: #9ca3af;'>::</span> " \
        "<span style='color: #34d399;'>✓ #{ERB::Util.html_escape(objective.label)}</span>"
    end

    # When the objective that just completed was the LAST one for the
    # mission, surface a READY FOR TURN-IN notification right after the
    # per-objective check line. Computed in-memory from the preloaded
    # association so we don't fire extra queries per tick — the model's
    # `all_objectives_completed?` would re-query twice per call, which
    # adds up across a tick that completes multiple objectives.
    def build_ready_notification_if_applicable(hackr_mission, just_completed_objective, saved_hackr_obj)
      mission = hackr_mission.grid_mission
      # Collect the set of objective_ids with `completed_at` set using
      # the cached rows the progressor is already tracking. Include the
      # just-saved row (whose membership in the AR cache depends on
      # find_or_initialize_by vs. find), since saved_hackr_obj may have
      # been newly built. The in-memory set is the source of truth.
      completed_ids = hackr_mission.grid_hackr_mission_objectives
        .each_with_object(Set.new) { |ho, set| set << ho.grid_mission_objective_id if ho.completed_at.present? }
      completed_ids << just_completed_objective.id

      required_ids = mission.grid_mission_objectives.map(&:id).to_set
      return nil unless (required_ids - completed_ids).empty?

      giver = mission.giver_mob
      giver_label = giver ? "Return to #{ERB::Util.html_escape(giver.name)}" : "Ready to turn in"
      "  <span style='color: #fbbf24;'>▲ READY FOR TURN-IN</span> " \
        "<span style='color: #6b7280;'>(#{giver_label}. Use 'turn_in #{ERB::Util.html_escape(mission.slug)}')</span>"
    end
  end
end
