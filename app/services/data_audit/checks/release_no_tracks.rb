# frozen_string_literal: true

module DataAudit
  module Checks
    class ReleaseNoTracks < DataAudit::Check
      SEVERITY = "info"
      DOMAIN = "music"

      def violations
        Release
          .where(coming_soon: false)
          .left_joins(:tracks)
          .group("releases.id")
          .having("COUNT(tracks.id) = 0")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Release '#{name}' has no tracks",
              subject_type: "Release",
              subject_id: id
            )
          end
      end
    end
  end
end
