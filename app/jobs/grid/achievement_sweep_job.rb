# frozen_string_literal: true

module Grid
  # Runs after login (and other catch-up moments) to evaluate all
  # cumulative-trigger achievements for a hackr. Counter-based progress
  # accumulates outside the Terminal (track plays, log reads, etc.), so a
  # triggering command may never fire. This job closes that gap.
  #
  # Cost profile (reviewed 2026-04-15): one checker instance is reused
  # across all 18 trigger types. That instance memoizes:
  #   - `earned_ids` (one query instead of 18)
  #   - each source count accessed by `progress` (e.g. `track_plays_count`
  #     runs once even though 5 tier achievements reference it)
  # For a brand-new user with nothing earned, the sweep is ~18 candidate
  # queries + ~10 source counts + 0 awards + 0 transactions. Fine as a
  # background job; worth re-measuring if the `GridAchievement` table
  # grows dramatically or new trigger types with expensive source
  # queries are added.
  class AchievementSweepJob < ApplicationJob
    queue_as :default

    def perform(hackr_id)
      hackr = GridHackr.find_by(id: hackr_id)
      return unless hackr

      checker = Grid::AchievementChecker.new(hackr)
      GridAchievement::CUMULATIVE_TRIGGERS.each do |trigger_type|
        checker.check(trigger_type)
      end
    end
  end
end
