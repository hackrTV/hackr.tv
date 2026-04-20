class AddMaxStackToGridItemDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_item_definitions, :max_stack, :integer
  end
end
