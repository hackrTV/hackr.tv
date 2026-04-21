class AddContainerIdToGridItems < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_items, :container_id, :integer, null: true
    add_index :grid_items, :container_id
    add_foreign_key :grid_items, :grid_items, column: :container_id
  end
end
