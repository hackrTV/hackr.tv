# frozen_string_literal: true

class AddEquippedSlotToGridItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_items, :equipped_slot, :string

    add_index :grid_items, [:grid_hackr_id, :equipped_slot],
      unique: true,
      where: "equipped_slot IS NOT NULL",
      name: "index_grid_items_on_hackr_equipped_slot_unique"
  end
end
