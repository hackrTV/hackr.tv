# frozen_string_literal: true

module DataAudit
  module Checks
    class RoomNoDescription < DataAudit::Check
      SEVERITY = "info"
      DOMAIN = "grid"

      # Den rooms have user-controlled descriptions, skip them.
      EXEMPT_TYPES = %w[den].freeze

      def violations
        GridRoom
          .where.not(room_type: EXEMPT_TYPES)
          .where(description: [nil, ""])
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Room '#{name}' has no description",
              subject_type: "GridRoom",
              subject_id: id
            )
          end
      end
    end
  end
end
