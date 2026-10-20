# Uplink shell sidebar (Discord-style channel list): channels group under
# a category heading and sort by position. Backfill puts livestream
# channels under BROADCAST ahead of everything else (COMMS).
class AddCategoryAndPositionToChatChannels < ActiveRecord::Migration[8.1]
  def up
    add_column :chat_channels, :category, :string, null: false, default: "COMMS"
    add_column :chat_channels, :position, :integer, null: false, default: 0
    add_index :chat_channels, [:position, :id]

    execute "UPDATE chat_channels SET category = 'BROADCAST', position = 0 WHERE requires_livestream = 1"
    execute "UPDATE chat_channels SET category = 'COMMS', position = 10 WHERE requires_livestream = 0"
  end

  def down
    remove_index :chat_channels, [:position, :id]
    remove_column :chat_channels, :position
    remove_column :chat_channels, :category
  end
end
