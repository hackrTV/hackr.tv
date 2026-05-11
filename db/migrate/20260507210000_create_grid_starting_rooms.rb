# frozen_string_literal: true

class CreateGridStartingRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_starting_rooms do |t|
      t.references :grid_room, null: false, foreign_key: {on_delete: :cascade}, index: {unique: true}
      t.string :name, null: false
      t.text :blurb, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end
  end
end
