class AddBreachPhase2aFields < ActiveRecord::Migration[8.1]
  def change
    # RestorePoint™ — regional hospital room for health-at-zero respawn
    add_reference :grid_regions, :hospital_room, null: true,
      foreign_key: {to_table: :grid_rooms, on_delete: :nullify}
  end
end
