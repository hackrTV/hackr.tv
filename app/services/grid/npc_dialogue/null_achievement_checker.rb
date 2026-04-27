# frozen_string_literal: true

module Grid
  module NpcDialogue
    # Null-object replacement for Grid::AchievementChecker.
    # Returns empty arrays so callers see no notifications without branching.
    class NullAchievementChecker
      def check(_trigger_type, _context = {})
        []
      end
    end
  end
end
