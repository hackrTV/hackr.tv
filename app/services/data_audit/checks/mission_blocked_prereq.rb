# frozen_string_literal: true

module DataAudit
  module Checks
    class MissionBlockedPrereq < DataAudit::Check
      SEVERITY = "critical"
      DOMAIN = "grid"

      def violations
        # Published missions whose prereq exists but is unpublished —
        # players can never complete the prereq, so the chain is permanently blocked.
        GridMission
          .where(published: true)
          .where.not(prereq_mission_id: nil)
          .joins("INNER JOIN grid_missions prereqs ON prereqs.id = grid_missions.prereq_mission_id")
          .where("prereqs.published = ?", false)
          .pluck("grid_missions.id", "grid_missions.name", "prereqs.name")
          .map do |id, name, prereq_name|
            build_violation(
              title: "Published mission '#{name}' requires unpublished prereq '#{prereq_name}'",
              subject_type: "GridMission",
              subject_id: id
            )
          end
      end
    end
  end
end
