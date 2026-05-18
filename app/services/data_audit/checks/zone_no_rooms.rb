# frozen_string_literal: true

module DataAudit
  module Checks
    class ZoneNoRooms < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        GridZone
          .left_joins(:grid_rooms)
          .group("grid_zones.id")
          .having("COUNT(grid_rooms.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Zone '#{name}' has no rooms",
              subject_type: "GridZone",
              subject_id: id
            )
          end
      end
    end
  end
end
