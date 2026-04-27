# frozen_string_literal: true

module Grid
  module NpcDialogue
    # Null-object replacement for Grid::MissionProgressor.
    # Returns empty arrays so callers see no notifications without branching.
    class NullMissionProgressor
      def record(_trigger_type, _context = {})
        []
      end
    end
  end
end
