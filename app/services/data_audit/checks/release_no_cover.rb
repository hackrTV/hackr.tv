# frozen_string_literal: true

module DataAudit
  module Checks
    class ReleaseNoCover < DataAudit::Check
      SEVERITY = "info"
      DOMAIN = "music"

      def violations
        Release
          .where(coming_soon: false)
          .left_joins(:cover_image_attachment)
          .where(active_storage_attachments: {id: nil})
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Release '#{name}' has no cover image",
              subject_type: "Release",
              subject_id: id
            )
          end
      end
    end
  end
end
