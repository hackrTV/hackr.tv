# Uplink per-channel unread badges (Phase 2 item 5): one high-water mark
# per hackr per channel — the newest packet id they have seen there — so
# the /uplink sidebar can count the active packets above it. Mirrors
# hackr_log_reads / codex_entry_reads. last_read_message_id is a plain
# integer (0 = nothing yet), not a foreign key: a hard-deleted packet must
# not drag the mark down with it. A hackr without a row for a channel is
# seeded caught-up on their next shell visit, so nobody starts at 99+.
class CreateUplinkChannelReads < ActiveRecord::Migration[8.1]
  def change
    create_table :uplink_channel_reads do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :chat_channel, null: false, foreign_key: true
      t.integer :last_read_message_id, null: false, default: 0
      t.datetime :read_at, null: false
      t.timestamps
    end
    add_index :uplink_channel_reads, [:grid_hackr_id, :chat_channel_id], unique: true, name: "index_uplink_channel_reads_unique"
  end
end
