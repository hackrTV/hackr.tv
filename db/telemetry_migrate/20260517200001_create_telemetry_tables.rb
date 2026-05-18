# frozen_string_literal: true

class CreateTelemetryTables < ActiveRecord::Migration[8.1]
  def change
    create_table :performance_metrics do |t|
      t.string :metric_name, null: false # LCP, INP, CLS, FCP, TTFB, zone_map_render, panel_open, page_nav
      t.string :metric_type, null: false # web_vital, component, navigation
      t.float :value, null: false
      t.string :unit, null: false # ms, score
      t.string :page_path, null: false
      t.string :session_id, limit: 64
      t.integer :hackr_id
      t.string :connection_type, limit: 32
      t.string :device_class, limit: 16
      t.timestamps
    end

    add_index :performance_metrics, :metric_name
    add_index :performance_metrics, :created_at

    create_table :analytics_events do |t|
      t.string :event_type, null: false # page_view, feature_click, button_click, panel_open, panel_close, command_entered, session_start, session_end
      t.string :event_name, null: false
      t.integer :hackr_id
      t.string :session_id, limit: 36, null: false
      t.text :properties # JSON
      t.datetime :created_at, null: false
    end

    add_index :analytics_events, :created_at
    add_index :analytics_events, :event_type
  end
end
