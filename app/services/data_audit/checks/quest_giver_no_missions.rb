# frozen_string_literal: true

module DataAudit
  module Checks
    class QuestGiverNoMissions < DataAudit::Check
      SEVERITY = "warning"
      DOMAIN = "grid"

      def violations
        quest_giver_ids = GridMob.where(mob_type: "quest_giver").pluck(:id)
        return [] if quest_giver_ids.empty?

        givers_with_missions = GridMission
          .where(published: true)
          .where(giver_mob_id: quest_giver_ids)
          .distinct
          .pluck(:giver_mob_id)
          .to_set

        orphaned_ids = quest_giver_ids.reject { |id| givers_with_missions.include?(id) }
        return [] if orphaned_ids.empty?

        GridMob
          .where(id: orphaned_ids)
          .pluck(:id, :name)
          .map do |id, name|
            build_violation(
              title: "Quest giver mob '#{name}' has no published missions",
              subject_type: "GridMob",
              subject_id: id
            )
          end
      end
    end
  end
end
