# frozen_string_literal: true

module DataAudit
  module Checks
    class MissionNoObjectives < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        GridMission
          .where(published: true)
          .left_joins(:grid_mission_objectives)
          .group("grid_missions.id")
          .having("COUNT(grid_mission_objectives.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Published mission '#{name}' has no objectives",
              subject_type: "GridMission",
              subject_id: id
            )
          end
      end
    end
  end
end
