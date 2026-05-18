# frozen_string_literal: true

module DataAudit
  module Checks
    class RegionMissingHospital < DataAudit::Check
      SEVERITY = "critical"
      DOMAIN = "grid"

      def violations
        GridRegion
          .where(hospital_room_id: nil)
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Region '#{name}' has no hospital room (RestorePoint™)",
              subject_type: "GridRegion",
              subject_id: id
            )
          end
      end
    end
  end
end
