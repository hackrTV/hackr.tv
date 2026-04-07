class AddProgressionFieldsToGridItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_items, :rarity, :string
    add_column :grid_items, :value, :integer, default: 0, null: false
    add_column :grid_items, :quantity, :integer, default: 1, null: false
  end
end
