# Uplink replies (Phase 2 item 2): a packet may quote one earlier packet
# in the same channel. Self-referential, nullable; an admin hard-delete of
# the parent (/root/uplink/packets/:id) nulls the reference instead of
# failing, so the reply survives as a plain packet.
class AddReplyToToChatMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :chat_messages, :reply_to, null: true, index: true,
      foreign_key: {to_table: :chat_messages, on_delete: :nullify}
  end
end
