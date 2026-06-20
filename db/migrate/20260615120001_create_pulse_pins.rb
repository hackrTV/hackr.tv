# frozen_string_literal: true

class CreatePulsePins < ActiveRecord::Migration[8.1]
  def change
    create_table :pulse_pins do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :pulse, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    # A hackr can pin a given pulse at most once.
    add_index :pulse_pins, [:grid_hackr_id, :pulse_id], unique: true
    # Ordered retrieval of a hackr's pins.
    add_index :pulse_pins, [:grid_hackr_id, :position]
  end
end
