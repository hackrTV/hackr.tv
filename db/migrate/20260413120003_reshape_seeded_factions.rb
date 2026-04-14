class ReshapeSeededFactions < ActiveRecord::Migration[8.1]
  # Data migration: rename TCP faction → hackrcore, remove xeraen faction.
  # The YAML seed (data/world/factions.yml) is the source of truth for the
  # remaining faction tree; the data:factions rake task will fill in the rest.
  def up
    return unless table_exists?(:grid_factions)

    tcp = GridFaction.find_by(slug: "thecyberpulse")
    tcp&.update_columns(slug: "hackrcore", name: "Hackrcore")

    xeraen = GridFaction.find_by(slug: "xeraen")
    if xeraen
      GridMob.where(grid_faction_id: xeraen.id).update_all(grid_faction_id: nil) if defined?(GridMob)
      GridZone.where(grid_faction_id: xeraen.id).update_all(grid_faction_id: nil) if defined?(GridZone)
      # Polymorphic rep tables have no FK constraint to grid_factions. Clean up
      # any orphan rows explicitly so their `subject` association doesn't dangle.
      if defined?(GridHackrReputation)
        GridHackrReputation.where(subject_type: "GridFaction", subject_id: xeraen.id).delete_all
      end
      if defined?(GridReputationEvent)
        GridReputationEvent.where(subject_type: "GridFaction", subject_id: xeraen.id).delete_all
      end
      xeraen.destroy
    end
  end

  def down
    # Recreate xeraen minimally; TCP rename is not reversed because the new slug
    # is semantically correct and downstream data references it.
    GridFaction.find_or_create_by!(slug: "xeraen") do |f|
      f.name = "XERAEN"
      f.description = "Temporal guardian broadcasting from the future to prevent the timeline he lives in."
      f.color_scheme = "purple"
    end
  end
end
