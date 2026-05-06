# frozen_string_literal: true

class AddMapPositionToGridZones < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_zones, :map_x, :integer
    add_column :grid_zones, :map_y, :integer
  end
end
