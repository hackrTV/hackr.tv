class CreatePulses < ActiveRecord::Migration[8.1]
  def change
    create_table :pulses do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :parent_pulse_id
      t.integer :thread_root_id
      t.integer :echo_count, default: 0, null: false
      t.integer :splice_count, default: 0, null: false
      t.datetime :pulsed_at, null: false
      t.boolean :signal_dropped, default: false, null: false
      t.datetime :signal_dropped_at

      t.timestamps
    end

    add_index :pulses, :parent_pulse_id
    add_index :pulses, :thread_root_id
    add_index :pulses, :pulsed_at
    add_index :pulses, :signal_dropped
    add_foreign_key :pulses, :pulses, column: :parent_pulse_id
    add_foreign_key :pulses, :pulses, column: :thread_root_id
  end
end
