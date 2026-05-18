# frozen_string_literal: true

module DataAudit
  module Checks
    class BreachTemplateNoProtocols < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        GridBreachTemplate
          .where(published: true)
          .where("protocol_composition IS NULL OR protocol_composition = '[]' OR protocol_composition = 'null'")
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Published breach template '#{name}' has empty protocol composition",
              subject_type: "GridBreachTemplate",
              subject_id: id
            )
          end
      end
    end
  end
end
