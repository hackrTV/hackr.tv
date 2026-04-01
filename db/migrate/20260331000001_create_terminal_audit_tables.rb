# frozen_string_literal: true

class CreateTerminalAuditTables < ActiveRecord::Migration[8.1]
  def change
    create_table :terminal_sessions do |t|
      t.string :ip_address
      t.references :grid_hackr, foreign_key: true
      t.datetime :connected_at, null: false
      t.datetime :disconnected_at
      t.integer :duration_seconds
      t.string :disconnect_reason
    end

    add_index :terminal_sessions, :ip_address
    add_index :terminal_sessions, :connected_at

    create_table :terminal_events do |t|
      t.references :terminal_session, null: false, foreign_key: true
      t.string :event_type, null: false
      t.string :handler
      t.string :input
      t.json :metadata
      t.datetime :created_at, null: false
    end

    add_index :terminal_events, :event_type
    add_index :terminal_events, :created_at
    add_index :terminal_events, [:terminal_session_id, :created_at]
  end
end
