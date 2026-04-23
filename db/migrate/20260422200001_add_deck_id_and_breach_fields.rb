class AddDeckIdAndBreachFields < ActiveRecord::Migration[8.1]
  def change
    # Software/firmware items loaded into a DECK point back to the DECK item
    add_column :grid_items, :deck_id, :integer
    add_index :grid_items, :deck_id
    add_foreign_key :grid_items, :grid_items, column: :deck_id, on_delete: :nullify

    # Track which room the hackr entered the current zone from (for BREACH ejection)
    add_column :grid_hackrs, :zone_entry_room_id, :integer
    add_foreign_key :grid_hackrs, :grid_rooms, column: :zone_entry_room_id, on_delete: :nullify

    # Room-level link to a breach template (voluntary encounters)
    add_column :grid_rooms, :breach_template_slug, :string
  end
end
