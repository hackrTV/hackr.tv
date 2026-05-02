# frozen_string_literal: true

class AddFacilityRoomFksToGridRegions < ActiveRecord::Migration[8.0]
  def change
    add_reference :grid_regions, :cell_block_room, foreign_key: {to_table: :grid_rooms, on_delete: :nullify}
    add_reference :grid_regions, :sally_port_room, foreign_key: {to_table: :grid_rooms, on_delete: :nullify}
  end
end
