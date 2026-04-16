class AddActiveMissionUniqueIndex < ActiveRecord::Migration[8.1]
  # Partial unique index serializes concurrent accept!/turn_in! races at the
  # DB level. Only one "active" row per (hackr, mission) may exist — once
  # turned in (status flips to "completed"), history rows accumulate without
  # blocking re-accept of repeatable missions.
  #
  # SQLite and Postgres both support `WHERE` on unique indexes.
  def change
    add_index :grid_hackr_missions, [:grid_hackr_id, :grid_mission_id],
      unique: true,
      where: "status = 'active'",
      name: "index_hackr_missions_unique_active"
  end
end
