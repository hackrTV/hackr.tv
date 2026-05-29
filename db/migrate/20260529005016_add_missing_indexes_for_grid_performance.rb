# frozen_string_literal: true

class AddMissingIndexesForGridPerformance < ActiveRecord::Migration[8.0]
  def change
    # grid_mobs — had ZERO indexes. FK lookups (room.grid_mobs) and
    # mob_type filtering (vendor/quest_giver checks) scan full table.
    add_index :grid_mobs, :grid_room_id
    add_index :grid_mobs, [:grid_room_id, :mob_type]
    add_index :grid_mobs, :grid_faction_id

    # grid_items — missing room_id (floor items, fixture queries) and
    # item_type (inventory filtering by type in 15+ call sites).
    add_index :grid_items, :room_id
    add_index :grid_items, :item_type

    # grid_messages — all three FK columns unindexed.
    add_index :grid_messages, :room_id
    add_index :grid_messages, :grid_hackr_id
    add_index :grid_messages, :target_hackr_id

    # grid_zones — slug lookups and faction FK unindexed.
    add_index :grid_zones, :slug, unique: true
    add_index :grid_zones, :grid_faction_id

    # grid_hackrs — presence queries in ZoneMapBuilder use current_room_id.
    add_index :grid_hackrs, :current_room_id
  end
end
