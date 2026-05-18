# frozen_string_literal: true

module DataAudit
  module Checks
    class TrackNoAudio < DataAudit::Check
      SEVERITY = "info"
      DOMAIN = "music"

      def violations
        Track
          .joins(:release)
          .where(releases: {coming_soon: false})
          .left_joins(:audio_file_attachment)
          .where(active_storage_attachments: {id: nil})
          .pluck("tracks.id", "tracks.title")
          .map do |id, title|
            build_violation(
              title: "Track '#{title}' has no audio file attached",
              subject_type: "Track",
              subject_id: id
            )
          end
      end
    end
  end
end
