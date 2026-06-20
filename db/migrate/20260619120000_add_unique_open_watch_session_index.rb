# frozen_string_literal: true

class AddUniqueOpenWatchSessionIndex < ActiveRecord::Migration[8.1]
  def up
    # Close any currently-open sessions so the new constraint applies
    # cleanly (pre-fix artifacts; at most one open session per hackr now).
    execute(<<~SQL)
      UPDATE hackr_watch_sessions
      SET disconnected_at = last_heartbeat_at, updated_at = CURRENT_TIMESTAMP
      WHERE disconnected_at IS NULL
    SQL

    # At most one open watch session per hackr — enforces the anti-double-
    # count guarantee atomically (the channel's check-then-create was raceable).
    add_index :hackr_watch_sessions, :grid_hackr_id,
      unique: true,
      where: "disconnected_at IS NULL",
      name: "index_hackr_watch_sessions_one_open_per_hackr"
  end

  def down
    remove_index :hackr_watch_sessions, name: "index_hackr_watch_sessions_one_open_per_hackr"
  end
end
