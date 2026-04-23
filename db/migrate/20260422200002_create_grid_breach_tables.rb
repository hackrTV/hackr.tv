class CreateGridBreachTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_breach_templates do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.string :tier, null: false, default: "standard"
      t.json :protocol_composition, null: false, default: {}
      t.json :reward_table, null: false, default: {}
      t.integer :min_clearance, null: false, default: 0
      t.integer :pnr_threshold, null: false, default: 75
      t.integer :base_detection_rate, null: false, default: 5
      t.integer :cooldown_min, null: false, default: 300
      t.integer :cooldown_max, null: false, default: 600
      t.integer :xp_reward, null: false, default: 0
      t.integer :cred_reward, null: false, default: 0
      t.string :requires_mission_slug
      t.string :requires_item_slug
      t.boolean :published, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_breach_templates, :slug, unique: true
    add_index :grid_breach_templates, :tier
    add_index :grid_breach_templates, :published

    create_table :grid_hackr_breaches do |t|
      t.references :grid_hackr, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.references :grid_breach_template, null: false, foreign_key: {on_delete: :restrict}, index: true
      t.integer :origin_room_id, null: false
      t.string :state, null: false, default: "active"
      t.integer :detection_level, null: false, default: 0
      t.integer :pnr_threshold, null: false, default: 75
      t.integer :round_number, null: false, default: 1
      t.integer :inspiration, null: false, default: 0
      t.integer :actions_this_round, null: false, default: 1
      t.integer :actions_remaining, null: false, default: 1
      t.decimal :reward_multiplier, null: false, default: 1.0, precision: 5, scale: 4
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.timestamps
    end
    add_foreign_key :grid_hackr_breaches, :grid_rooms, column: :origin_room_id, on_delete: :nullify
    add_index :grid_hackr_breaches, :state
    # One active breach per hackr at a time
    add_index :grid_hackr_breaches, :grid_hackr_id,
      where: "state = 'active'",
      unique: true,
      name: "index_hackr_breaches_one_active_per_hackr"

    create_table :grid_breach_protocols do |t|
      t.references :grid_hackr_breach, null: false, foreign_key: {on_delete: :cascade}, index: true
      t.string :protocol_type, null: false
      t.integer :health, null: false
      t.integer :max_health, null: false
      t.string :weakness
      t.string :state, null: false, default: "idle"
      t.integer :charge_rounds, null: false, default: 0
      t.integer :rounds_charging, null: false, default: 0
      t.integer :position, null: false
      t.boolean :rerouted, null: false, default: false
      t.json :meta, null: false, default: {}
      t.timestamps
    end
    add_index :grid_breach_protocols, [:grid_hackr_breach_id, :position],
      name: "index_breach_protocols_on_breach_and_position"
  end
end
