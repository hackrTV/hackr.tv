class CreateGridMissionTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_mission_arcs do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.integer :position, default: 0, null: false
      t.boolean :published, default: false, null: false
      t.timestamps
    end
    add_index :grid_mission_arcs, :slug, unique: true

    create_table :grid_missions do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.references :giver_mob, foreign_key: {to_table: :grid_mobs, on_delete: :nullify}, index: true
      t.references :grid_mission_arc, foreign_key: {on_delete: :nullify}, index: true
      t.references :prereq_mission, foreign_key: {to_table: :grid_missions, on_delete: :nullify}, index: true
      t.integer :min_clearance, default: 0, null: false
      t.references :min_rep_faction, foreign_key: {to_table: :grid_factions, on_delete: :nullify}, index: true
      t.integer :min_rep_value, default: 0, null: false
      t.boolean :repeatable, default: false, null: false
      t.integer :position, default: 0, null: false
      t.boolean :published, default: false, null: false
      t.timestamps
    end
    add_index :grid_missions, :slug, unique: true

    create_table :grid_mission_objectives do |t|
      t.references :grid_mission, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.integer :position, default: 0, null: false
      t.string :objective_type, null: false
      t.string :label, null: false
      t.string :target_slug
      t.integer :target_count, default: 1, null: false
      t.timestamps
    end
    add_index :grid_mission_objectives, [:grid_mission_id, :position],
      name: "index_mission_objectives_on_mission_and_position"

    create_table :grid_mission_rewards do |t|
      t.references :grid_mission, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.integer :position, default: 0, null: false
      t.string :reward_type, null: false
      t.integer :amount, default: 0, null: false
      t.string :target_slug
      t.integer :quantity, default: 1, null: false
      t.timestamps
    end

    create_table :grid_hackr_missions do |t|
      t.references :grid_hackr, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.references :grid_mission, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.string :status, null: false, default: "active"
      t.datetime :accepted_at, null: false
      t.datetime :completed_at
      t.integer :turn_in_count, default: 0, null: false
      t.timestamps
    end
    add_index :grid_hackr_missions, [:grid_hackr_id, :status], name: "index_hackr_missions_on_hackr_and_status"
    # No unique index on (hackr, mission) — completed rows accumulate;
    # the current attempt is queried via scope(:active) on the hackr.

    create_table :grid_hackr_mission_objectives do |t|
      t.references :grid_hackr_mission, null: false, foreign_key: {on_delete: :cascade}, index: {name: "index_hackr_mission_objs_on_hackr_mission"}
      t.references :grid_mission_objective, null: false, foreign_key: {on_delete: :restrict}, index: {name: "index_hackr_mission_objs_on_objective"}
      t.integer :progress, default: 0, null: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :grid_hackr_mission_objectives,
      [:grid_hackr_mission_id, :grid_mission_objective_id],
      unique: true, name: "index_hackr_mission_objs_unique"
  end
end
