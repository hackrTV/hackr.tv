class AddIndexOnGridItemsGridHackrId < ActiveRecord::Migration[8.1]
  def change
    add_index :grid_items, :grid_hackr_id
  end
end
