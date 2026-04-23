# frozen_string_literal: true

class FixBreachTableConstraints < ActiveRecord::Migration[8.1]
  def change
    # origin_room_id was NOT NULL but FK has on_delete: :nullify — contradiction.
    # Model declares belongs_to :origin_room, optional: true, so nullable is correct.
    change_column_null :grid_hackr_breaches, :origin_room_id, true

    # Enforce unique protocol positions within a breach to prevent targeting ambiguity.
    remove_index :grid_breach_protocols, [:grid_hackr_breach_id, :position],
      name: "index_breach_protocols_on_breach_and_position"
    add_index :grid_breach_protocols, [:grid_hackr_breach_id, :position],
      unique: true,
      name: "index_breach_protocols_on_breach_and_position"
  end
end
