# frozen_string_literal: true

module DataAudit
  module Checks
    class BreachEncounterOrphaned < DataAudit::Check
      SEVERITY = "critical"
      DOMAIN = "grid"

      def violations
        # Encounters stuck in "active" state with no corresponding active breach.
        # This makes the encounter invisible to players (filtered out of available list).
        active_encounter_ids = GridBreachEncounter.where(state: "active").pluck(:id)
        return [] if active_encounter_ids.empty?

        encounters_with_active_breach = GridHackrBreach
          .where(state: "active")
          .where(grid_breach_encounter_id: active_encounter_ids)
          .pluck(:grid_breach_encounter_id)
          .to_set

        orphaned = active_encounter_ids.reject { |id| encounters_with_active_breach.include?(id) }
        return [] if orphaned.empty?

        GridBreachEncounter
          .where(id: orphaned)
          .joins(:grid_breach_template)
          .pluck("grid_breach_encounters.id", "grid_breach_templates.name")
          .map do |id, template_name|
            build_violation(
              title: "Breach encounter ##{id} ('#{template_name}') stuck in active state — no matching active breach",
              subject_type: "GridBreachEncounter",
              subject_id: id
            )
          end
      end
    end
  end
end
