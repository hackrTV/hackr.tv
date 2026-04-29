# frozen_string_literal: true

class AddMapCoordinatesToGridRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_rooms, :map_x, :integer
    add_column :grid_rooms, :map_y, :integer
    add_column :grid_rooms, :map_z, :integer, default: 0, null: false
  end
end
