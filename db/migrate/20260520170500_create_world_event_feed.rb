# frozen_string_literal: true

class CreateWorldEventFeed < ActiveRecord::Migration[8.0]
  def change
    create_table :world_events do |t|
      t.string :event_type, null: false
      t.string :hackr_alias, null: false
      t.json :data, null: false, default: {}
      t.boolean :simulated, null: false, default: false
      t.datetime :created_at, null: false
    end

    add_index :world_events, :created_at
    add_index :world_events, :event_type
    add_index :world_events, :simulated

    create_table :world_event_simulants do |t|
      t.references :grid_hackr, null: false, foreign_key: true, index: {unique: true}
      t.json :state, null: false, default: {}

      t.timestamps
    end

    create_table :world_event_settings do |t|
      t.integer :target_events_per_minute, null: false, default: 12
      t.boolean :simulator_enabled, null: false, default: true

      t.timestamps
    end
  end
end
