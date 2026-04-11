class AddShopColumnsToRoomsAndMobs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_rooms, :min_clearance, :integer, default: 0, null: false
    add_column :grid_mobs, :vendor_config, :json
  end
end
