# frozen_string_literal: true

class CreateHackrWatchSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_watch_sessions do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :hackr_stream, foreign_key: true
      t.datetime :connected_at, null: false
      t.datetime :last_heartbeat_at, null: false
      t.datetime :disconnected_at
      t.integer :accumulated_seconds, null: false, default: 0

      t.timestamps
    end

    # Open-session sweeps (disconnected_at IS NULL) + per-hackr totals.
    add_index :hackr_watch_sessions, [:grid_hackr_id, :disconnected_at]
    # Stale-heartbeat sweep for orphaned sessions.
    add_index :hackr_watch_sessions, :last_heartbeat_at
  end
end
