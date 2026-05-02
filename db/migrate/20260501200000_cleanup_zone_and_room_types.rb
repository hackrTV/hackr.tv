# frozen_string_literal: true

class CleanupZoneAndRoomTypes < ActiveRecord::Migration[8.0]
  def up
    # Drop unused zone columns
    remove_column :grid_zones, :zone_type, :string
    remove_column :grid_zones, :color_scheme, :string

    # Backfill mistyped hub rooms to standard
    execute <<~SQL
      UPDATE grid_rooms SET room_type = 'standard'
      WHERE slug IN ('riverlands-den-corridor', 'canyon-upper-dwelling')
        AND room_type = 'hub'
    SQL

    # Backfill any nil room_types, then enforce not-null with default
    execute <<~SQL
      UPDATE grid_rooms SET room_type = 'standard' WHERE room_type IS NULL
    SQL
    change_column_default :grid_rooms, :room_type, "standard"
    change_column_null :grid_rooms, :room_type, false
  end

  def down
    change_column_null :grid_rooms, :room_type, true
    change_column_default :grid_rooms, :room_type, nil

    add_column :grid_zones, :zone_type, :string
    add_column :grid_zones, :color_scheme, :string

    execute <<~SQL
      UPDATE grid_rooms SET room_type = 'hub'
      WHERE slug IN ('riverlands-den-corridor', 'canyon-upper-dwelling')
        AND room_type = 'standard'
    SQL
  end
end
