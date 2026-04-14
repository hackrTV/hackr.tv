# frozen_string_literal: true

module Grid
  # Per-hackr reputation service. Handles leaf rep writes, event logging, and
  # derived rollup computation via the faction rep-link graph.
  #
  # Only LEAF values persist to grid_hackr_reputations. Aggregate subjects
  # (e.g. Fracture Network) are computed on read from weighted links.
  class ReputationService
    SubjectMissing = Class.new(StandardError)
    # Raised when a caller tries to adjust a subject whose effective rep is
    # computed from incoming rep-links. Stored leaf values on such subjects are
    # ignored by effective_rep, so allowing the write would silently diverge the
    # audit log from what players see.
    AggregateSubjectNotAdjustable = Class.new(StandardError)

    # Class of acceptable polymorphic subjects. `GridZone` is here because a
    # future regional-rep feature will reuse the same storage; all current call
    # sites pass GridFactions.
    VALID_SUBJECT_CLASSES = [GridFaction, GridZone].freeze

    def initialize(hackr)
      @hackr = hackr
    end

    # Adjust rep for a subject (faction or future region).
    # Clamps final stored value to [MIN_VALUE, MAX_VALUE]; delta applied is the
    # actual change after clamping, which may be smaller than requested.
    #
    # Returns a hash describing the change plus any aggregate standings that
    # transitioned tiers so the UI can surface them.
    def adjust!(subject, delta, reason: nil, source: nil, note: nil)
      subject = resolve_subject(subject)
      raise SubjectMissing, "reputation subject not found" unless subject
      if subject.respond_to?(:aggregate?) && subject.aggregate?
        raise AggregateSubjectNotAdjustable,
          "'#{subject.display_name}' is an aggregate — its rep is derived from incoming rep-links. Adjust a source faction instead."
      end

      result = nil
      attempts = 0
      begin
        attempts += 1
        ActiveRecord::Base.transaction do
          # Ensure the row exists BEFORE taking the pessimistic lock so the lock
          # is meaningful (SELECT FOR UPDATE only locks extant rows). If the row
          # is created between find_or_create_by! and .lock by another worker,
          # we'll still see the latest value under FOR UPDATE.
          GridHackrReputation.find_or_create_by!(
            grid_hackr: @hackr, subject_type: subject.class.name, subject_id: subject.id
          ) { |r| r.value = 0 }

          rep = GridHackrReputation.lock.find_by!(
            grid_hackr: @hackr, subject_type: subject.class.name, subject_id: subject.id
          )

          old_value = rep.value
          rollup_before = rollup_snapshot_for_sources(subject)

          new_value = (old_value + delta.to_i).clamp(Reputation::MIN_VALUE, Reputation::MAX_VALUE)
          applied_delta = new_value - old_value

          rep.value = new_value
          rep.save!

          event = GridReputationEvent.create!(
            grid_hackr: @hackr,
            subject: subject,
            delta: applied_delta,
            value_after: new_value,
            reason: reason,
            source: source,
            note: note
          )

          rollup_after = rollup_snapshot_for_sources(subject)
          rollups = diff_rollups(rollup_before, rollup_after)

          result = {
            subject: subject,
            old_value: old_value,
            new_value: new_value,
            applied_delta: applied_delta,
            requested_delta: delta.to_i,
            tier_before: Reputation.tier_for(old_value),
            tier_after: Reputation.tier_for(new_value),
            rollups: rollups,
            event: event
          }
        end
      rescue ActiveRecord::RecordNotUnique
        # Two concurrent callers raced on initial create. Retry once; the second
        # attempt will find the row existing and proceed under the lock.
        retry if attempts < 2
        raise
      end

      result
    end

    # Effective (displayable) reputation for a subject.
    # - Leaf (no incoming rep-links): returns stored leaf value.
    # - Aggregate: recursively sums weighted EFFECTIVE rep of each source so
    #   chains of aggregates propagate correctly (A → B → C works).
    #   `visited` is a cycle guard; if the graph somehow contains a cycle
    #   (the model validates against this, but defensive anyway), a revisited
    #   node contributes 0. Clamps to [MIN, MAX].
    def effective_rep(subject, visited: nil)
      subject = resolve_subject(subject)
      return 0 unless subject

      visited ||= Set.new
      return 0 if visited.include?(subject.id)

      links = subject.respond_to?(:incoming_rep_links) ? subject.incoming_rep_links : []
      return leaf_value(subject) if links.empty?

      next_visited = visited + [subject.id]
      sum = links.sum { |link| link.weight * effective_rep(link.source_faction, visited: next_visited) }
      sum.round.clamp(Reputation::MIN_VALUE, Reputation::MAX_VALUE)
    end

    # Raw stored leaf value. Returns 0 if no row exists yet. Uses the per-call
    # preload cache (populated by faction_standings) when available.
    def leaf_value(subject)
      subject = resolve_subject(subject)
      return 0 unless subject

      if @preload
        return @preload.dig(subject.class.name, subject.id) || 0
      end

      rep = GridHackrReputation.find_by(
        grid_hackr: @hackr, subject_type: subject.class.name, subject_id: subject.id
      )
      rep&.value || 0
    end

    # All faction standings as a display-ready list. Returns every faction that
    # either has a stored leaf value for this hackr OR is an aggregate whose
    # computed value is nonzero. Always includes factions passed in `always`.
    def faction_standings(include_zero: false, always: [])
      factions = GridFaction.ordered
        .includes(incoming_rep_links: :source_faction, outgoing_rep_links: :target_faction)
        .to_a
      always_ids = Array(always).map { |f| resolve_subject(f)&.id }.compact.to_set

      prime_preload!

      factions.filter_map do |f|
        leaf = leaf_value(f)
        effective = effective_rep(f)
        has_activity = leaf != 0 || always_ids.include?(f.id)
        next nil unless include_zero || has_activity || effective != 0

        {
          faction: f,
          leaf: leaf,
          effective: effective,
          aggregate: f.aggregate?,
          tier: Reputation.tier_for(effective),
          next_tier: Reputation.next_tier_for(effective)
        }
      end
    ensure
      reset_preload!
    end

    private

    def resolve_subject(subject)
      case subject
      when *VALID_SUBJECT_CLASSES
        subject
      when String, Symbol
        GridFaction.find_by(slug: subject.to_s)
      end
    end

    # Build a {class_name => {id => value}} hash of all this hackr's rep rows
    # so repeated lookups during rendering are O(1) instead of O(1 query each).
    def prime_preload!
      @preload = Hash.new { |h, k| h[k] = {} }
      GridHackrReputation.where(grid_hackr: @hackr).find_each do |rep|
        @preload[rep.subject_type][rep.subject_id] = rep.value
      end
    end

    def reset_preload!
      @preload = nil
    end

    # For every faction whose rep this subject CONTRIBUTES to (outgoing links),
    # snapshot the hackr's effective rep so we can diff before/after an adjust!.
    def rollup_snapshot_for_sources(subject)
      return {} unless subject.is_a?(GridFaction)
      subject.outgoing_rep_links.includes(:target_faction).each_with_object({}) do |link, memo|
        target = link.target_faction
        memo[target.id] = {faction: target, value: effective_rep(target)}
      end
    end

    def diff_rollups(before, after)
      after.filter_map do |faction_id, after_snap|
        before_snap = before[faction_id]
        next nil unless before_snap
        next nil if before_snap[:value] == after_snap[:value]
        {
          faction: after_snap[:faction],
          old_value: before_snap[:value],
          new_value: after_snap[:value],
          tier_before: Reputation.tier_for(before_snap[:value]),
          tier_after: Reputation.tier_for(after_snap[:value])
        }
      end
    end
  end
end
