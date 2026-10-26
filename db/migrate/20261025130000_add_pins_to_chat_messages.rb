# Uplink channel pins (Phase 2 item 6): operators pin packets in a channel
# for everyone to find from the shell header's [◆] panel. Pin state lives
# on the packet (when, by whom); pinning a packet that is later dropped
# parks the pin until a restore. The pinner's FK nulls if that hackr is
# hard-deleted — the pin stays.
class AddPinsToChatMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :chat_messages, :pinned_at, :datetime
    add_reference :chat_messages, :pinned_by, null: true, index: false,
      foreign_key: {to_table: :grid_hackrs, on_delete: :nullify}
    # Pins per channel are few (PIN_CAP): a partial index keeps the header
    # count and the panel off the message heap.
    add_index :chat_messages, [:chat_channel_id, :pinned_at],
      where: "pinned_at IS NOT NULL", name: "index_chat_messages_pinned"
  end
end
