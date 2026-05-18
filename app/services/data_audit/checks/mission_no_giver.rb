# frozen_string_literal: true

module DataAudit
  module Checks
    class MissionNoGiver < DataAudit::Check
      SEVERITY = "critical"
      DOMAIN = "grid"

      def violations
        GridMission
          .where(published: true, giver_mob_id: nil)
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Published mission '#{name}' has no giver mob",
              subject_type: "GridMission",
              subject_id: id
            )
          end
      end
    end
  end
end
