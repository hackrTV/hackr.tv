class DropMapCoordinatesFromGridRoomsAndZones < ActiveRecord::Migration[8.0]
  def change
    remove_column :grid_rooms, :map_x, :integer
    remove_column :grid_rooms, :map_y, :integer
    remove_column :grid_rooms, :map_z, :integer, default: 0, null: false
    remove_column :grid_zones, :map_x, :integer
    remove_column :grid_zones, :map_y, :integer
  end
end
