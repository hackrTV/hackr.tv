# frozen_string_literal: true

module DataAudit
  module Checks
    class RoomNoExits < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      # Room types that are intentionally isolated (no outbound exits expected)
      EXEMPT_TYPES = %w[den].freeze

      def violations
        GridRoom
          .where.not(room_type: EXEMPT_TYPES)
          .left_joins(:exits_from)
          .group("grid_rooms.id")
          .having("COUNT(grid_exits.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Room '#{name}' has no exits",
              subject_type: "GridRoom",
              subject_id: id
            )
          end
      end
    end
  end
end
