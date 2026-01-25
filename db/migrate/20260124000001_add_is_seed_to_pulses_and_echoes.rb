class AddIsSeedToPulsesAndEchoes < ActiveRecord::Migration[8.0]
  def change
    add_column :pulses, :is_seed, :boolean, default: false, null: false
    add_column :echoes, :is_seed, :boolean, default: false, null: false
    add_index :pulses, :is_seed
    add_index :echoes, :is_seed
  end
end
