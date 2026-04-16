# frozen_string_literal: true

module Grid
  # Orchestrates mission lifecycle for a single hackr. Delegates reward
  # grants to Grid::MissionRewardGranter and progress ticks to
  # Grid::MissionProgressor. Every mutation is transactional; gate checks
  # raise specific error classes so the command path can render friendly
  # messages.
  class MissionService
    class Error < StandardError; end
    class MissionMissing < Error; end
    class NotAtGiver < Error; end
    class PrereqUnmet < Error; end
    class ClearanceTooLow < Error; end
    class RepTooLow < Error; end
    class AlreadyActive < Error; end
    class AlreadyCompletedNonRepeatable < Error; end
    class NotActive < Error; end
    class ObjectivesIncomplete < Error; end
    class NotAtTurnIn < Error; end

    def initialize(hackr)
      @hackr = hackr
    end

    # Missions this hackr could accept RIGHT NOW from a given room.
    # Only returns missions whose giver is in the room and whose gates
    # (prereq, clearance, min-rep) are satisfied. Already-active missions
    # are filtered out; completed non-repeatable missions are filtered;
    # completed repeatable missions ARE included (re-acceptable).
    def available_missions(room)
      return [] unless room
      mob_ids = room.grid_mobs.pluck(:id)
      return [] if mob_ids.empty?

      candidate_missions = GridMission.published
        .where(giver_mob_id: mob_ids)
        .includes(:grid_mission_arc, :prereq_mission, :min_rep_faction, :grid_mission_objectives, :grid_mission_rewards)
        .ordered

      candidate_missions.select { |m| gates_met?(m) && !already_active?(m) && !completed_nonrepeatable?(m) }
    end

    # All active mission rows for the `missions` command and the
    # /api/grid/missions index. Preloads the progress rows too so the
    # serializer's `all_objectives_completed?` + per-objective progress
    # lookup each run against loaded associations, not fresh queries.
    def active_hackr_missions
      @hackr.grid_hackr_missions.active
        .includes(:grid_hackr_mission_objectives,
          grid_mission: [:grid_mission_objectives, :grid_mission_arc, :giver_mob])
        .order(accepted_at: :desc)
    end

    def completed_hackr_missions(limit: 10)
      @hackr.grid_hackr_missions.completed
        .includes(grid_mission: [:grid_mission_arc, :giver_mob])
        .order(completed_at: :desc).limit(limit)
    end

    # Returns a struct of gate flags + a human-readable refusal reason
    # for the first failing gate (or nil when all gates pass). Callers:
    # CommandParser renders `reason`; Api serializer returns flags;
    # internal accept! path re-uses the predicates. Single source of truth.
    GateStatus = Struct.new(:clearance_met, :prereq_met, :rep_met, :reason, keyword_init: true) do
      def all_met?
        clearance_met && prereq_met && rep_met
      end
    end

    def gate_status(mission)
      clearance = clearance_met?(mission)
      prereq = prereq_met?(mission)
      rep = rep_met?(mission)

      reason = if !prereq
        "Complete '#{mission.prereq_mission&.name || "prerequisite"}' first."
      elsif !clearance
        "Requires clearance #{mission.min_clearance}."
      elsif !rep
        "Your reputation with #{mission.min_rep_faction&.display_name} is too low."
      end

      GateStatus.new(clearance_met: clearance, prereq_met: prereq, rep_met: rep, reason: reason)
    end

    # Accept a mission. Validates room/prereq/clearance/rep/duplicate and
    # creates GridHackrMission + GridHackrMissionObjective rows (one per
    # definition objective). Raises on any gate failure.
    def accept!(mission_slug, room:)
      # Only published missions are acceptable. Unpublished/draft missions
      # are invisible to players even by direct slug lookup — matches the
      # `available_missions` scope so admins can stage content safely.
      mission = GridMission.published.find_by(slug: mission_slug)
      raise MissionMissing, "No mission with that slug." unless mission
      raise NotAtGiver, "You need to be in the same room as the mission giver." unless at_giver?(mission, room)
      raise PrereqUnmet, "This mission requires completing '#{mission.prereq_mission&.name || "a prerequisite"}' first." unless prereq_met?(mission)
      raise ClearanceTooLow, "This mission requires clearance #{mission.min_clearance}." unless clearance_met?(mission)
      raise RepTooLow, "Your reputation with #{mission.min_rep_faction&.display_name} is too low." unless rep_met?(mission)
      raise AlreadyActive, "You are already working on that mission." if already_active?(mission)
      raise AlreadyCompletedNonRepeatable, "You have already completed that mission." if completed_nonrepeatable?(mission)

      hackr_mission = nil
      ActiveRecord::Base.transaction do
        # The DB-level partial unique index on (hackr_id, mission_id)
        # WHERE status = 'active' turns any concurrent accept race into
        # a RecordNotUnique that we surface as AlreadyActive — the
        # guarantee doesn't rely on the app-level guard alone.
        hackr_mission = @hackr.grid_hackr_missions.create!(
          grid_mission: mission,
          status: "active",
          accepted_at: Time.current
        )

        mission.grid_mission_objectives.each do |obj|
          hackr_mission.grid_hackr_mission_objectives.create!(
            grid_mission_objective: obj,
            progress: 0
          )
        end

        # Seed threshold-trigger objectives with the hackr's current
        # state so a "reach clearance 5" mission with the hackr already
        # at CL5 doesn't require a pointless level-up tick to complete
        # at accept time. Inside the same transaction so a failure
        # rolls back the whole accept.
        seed_threshold_objectives(hackr_mission)
      end

      invalidate_mission_ids_cache!
      hackr_mission
    rescue ActiveRecord::RecordNotUnique => e
      # Only the partial index on active (hackr, mission) pairs is the
      # user-facing race we want to surface as AlreadyActive. Other
      # unique-constraint violations (objective progress rows, future
      # indexes, etc.) should propagate with their real error so bugs
      # don't hide behind a misleading "already active" message.
      raise AlreadyActive, "You are already working on that mission." if e.message.include?("index_hackr_missions_unique_active")
      raise
    end

    # Drop a mission. Destroys the row so a one-shot mission is freely
    # re-acceptable (no cooldown per spec).
    def abandon!(mission_slug)
      hackr_mission = active_for_slug(mission_slug)
      raise NotActive, "You are not working on that mission." unless hackr_mission
      hackr_mission.destroy!
      invalidate_mission_ids_cache!
      hackr_mission
    end

    # Turn in. Requires all objectives complete AND hackr in giver's room.
    # Delegates reward pipeline to MissionRewardGranter.
    def turn_in!(mission_slug, room:)
      hackr_mission = active_for_slug(mission_slug)
      raise NotActive, "You are not working on that mission." unless hackr_mission
      raise ObjectivesIncomplete, "Not all objectives are complete." unless hackr_mission.all_objectives_completed?
      raise NotAtTurnIn, "Return to #{hackr_mission.grid_mission.giver_mob&.name || "the mission giver"} to turn in." unless at_giver?(hackr_mission.grid_mission, room)

      result = Grid::MissionRewardGranter.new(@hackr, hackr_mission).grant!
      invalidate_mission_ids_cache!
      result
    end

    private

    def at_giver?(mission, room)
      return false unless room && mission.giver_mob_id
      mission.giver_mob_id && room.grid_mobs.where(id: mission.giver_mob_id).exists?
    end

    def gates_met?(mission)
      gate_status(mission).all_met?
    end

    def prereq_met?(mission)
      return true if mission.prereq_mission_id.nil?
      completed_mission_ids.include?(mission.prereq_mission_id)
    end

    def clearance_met?(mission)
      @hackr.stat("clearance").to_i >= mission.min_clearance.to_i
    end

    def rep_met?(mission)
      return true if mission.min_rep_faction_id.nil?
      faction = mission.min_rep_faction
      return true unless faction
      reputation_service.effective_rep(faction) >= mission.min_rep_value.to_i
    end

    public :prereq_met?, :clearance_met?, :rep_met?

    def completed_mission_ids
      return @completed_mission_ids if defined?(@completed_mission_ids)
      @completed_mission_ids = @hackr.grid_hackr_missions.completed.pluck(:grid_mission_id).to_set
    end

    # Drop memoized active + completed sets. Called after any mutation
    # the service performs on its own hackr's missions, so
    # subsequent queries (e.g. another `accept!`, `available_missions`)
    # see the post-mutation state. External writes between service
    # calls aren't covered — by design, the service expects a
    # short-lived per-request instance.
    def invalidate_mission_ids_cache!
      remove_instance_variable(:@active_mission_ids) if defined?(@active_mission_ids)
      remove_instance_variable(:@completed_mission_ids) if defined?(@completed_mission_ids)
    end

    # Memoized per-instance so `available_missions` (and any other
    # caller iterating candidates) doesn't fire one EXISTS per mission.
    # Discard the service instance after a request/job — the snapshot
    # isn't refreshed mid-flight by design.
    def active_mission_ids
      return @active_mission_ids if defined?(@active_mission_ids)
      @active_mission_ids = @hackr.grid_hackr_missions.active.pluck(:grid_mission_id).to_set
    end

    def already_active?(mission)
      active_mission_ids.include?(mission.id)
    end

    def completed_nonrepeatable?(mission)
      return false if mission.repeatable?
      completed_mission_ids.include?(mission.id)
    end

    def active_for_slug(slug)
      @hackr.grid_hackr_missions.active
        .joins(:grid_mission).where(grid_missions: {slug: slug}).first
    end

    def reputation_service
      @reputation_service ||= Grid::ReputationService.new(@hackr)
    end

    # For `reach_rep` / `reach_clearance` objectives, evaluate the hackr's
    # current state on accept so pre-met conditions auto-complete.
    #
    # Scoped strictly to this hackr_mission. We write progress rows
    # directly rather than delegating to MissionProgressor — the
    # progressor is a fan-out over ALL active missions and would advance
    # sibling missions' thresholds as a side effect of accepting THIS
    # one, which is surprising (users expect accept to touch the
    # accepted mission and nothing else). Sibling thresholds catch up
    # via the normal command-path hooks (go, talk, salvage, buy, turn_in).
    def seed_threshold_objectives(hackr_mission)
      clearance = @hackr.stat("clearance").to_i

      hackr_mission.grid_mission.grid_mission_objectives.each do |obj|
        value = case obj.objective_type
        when "reach_clearance"
          clearance
        when "reach_rep"
          faction = GridFaction.find_by(slug: obj.target_slug)
          next unless faction
          reputation_service.effective_rep(faction)
        end
        next if value.nil?

        hackr_obj = hackr_mission.grid_hackr_mission_objectives
          .find_by(grid_mission_objective_id: obj.id)
        next unless hackr_obj && hackr_obj.completed_at.nil?

        new_progress = [value.to_i, obj.target_count.to_i].min
        next if new_progress <= hackr_obj.progress.to_i

        hackr_obj.progress = new_progress
        hackr_obj.completed_at = Time.current if new_progress >= obj.target_count.to_i
        hackr_obj.save!
      end
    end
  end
end
