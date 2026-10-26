# Uplink reactions (Phase 2 item 7): one row per hackr per emote per
# packet — a chip under the packet reads ":slug: N" for everyone, and the
# viewer's own rows mark their chips. The emote is referenced by slug,
# as packet text references emotes (the render map is keyed by slug and
# a reaction whose emote vanished still reads as its token); the Emote
# model cleans up on destroy and follows a rename. Both FKs cascade: a
# hard-deleted packet or hackr takes its reactions with it.
class CreateChatMessageReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_message_reactions do |t|
      t.references :chat_message, null: false, index: false, foreign_key: {on_delete: :cascade}
      t.references :grid_hackr, null: false, foreign_key: {on_delete: :cascade}
      t.string :emote_slug, null: false, limit: 32
      t.datetime :created_at, null: false
    end
    # The toggle's lookup and the chips' grouping both start from the packet.
    add_index :chat_message_reactions, [:chat_message_id, :grid_hackr_id, :emote_slug],
      unique: true, name: "index_chat_message_reactions_unique"
  end
end
