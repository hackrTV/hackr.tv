# frozen_string_literal: true

class CreateBreachPhase3Infrastructure < ActiveRecord::Migration[8.0]
  def change
    # Impound records: tracks gear confiscated during BREACH failure (tier 5+6).
    # Multiple captures = multiple records, each paid/forfeited independently.
    create_table :grid_impound_records do |t|
      t.references :grid_hackr, null: false, foreign_key: {on_delete: :cascade}
      t.references :grid_hackr_breach, null: true, foreign_key: {on_delete: :nullify}
      t.string :status, null: false, default: "impounded"
      t.integer :bribe_cost, null: false, default: 0
      t.timestamps
    end

    add_index :grid_impound_records, [:grid_hackr_id, :status]

    # Items with non-null impound FK are confiscated — excluded from all
    # player-facing scopes. ON DELETE nullify = admin cleanup safety net.
    add_reference :grid_items, :grid_impound_record, null: true,
      foreign_key: {on_delete: :nullify}, index: true

    # Per-region containment room + facility exit rooms.
    # Mirrors the existing hospital_room_id pattern.
    add_reference :grid_regions, :containment_room, null: true,
      foreign_key: {to_table: :grid_rooms, on_delete: :nullify}, index: true
    add_reference :grid_regions, :facility_exit_room, null: true,
      foreign_key: {to_table: :grid_rooms, on_delete: :nullify}, index: true
    add_reference :grid_regions, :facility_bribe_exit_room, null: true,
      foreign_key: {to_table: :grid_rooms, on_delete: :nullify}, index: true

    # Puzzle gate override: disables clearance-based gate bypass.
    # Used for containment cell + sally port BREACHes.
    add_column :grid_breach_templates, :no_clearance_bypass, :boolean, default: false, null: false
  end
end
