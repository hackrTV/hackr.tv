class CreateHackrRadioTunes < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_radio_tunes do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :radio_station, null: false, foreign_key: true
      t.datetime :tuned_at, null: false
      t.timestamps
    end
    add_index :hackr_radio_tunes, [:grid_hackr_id, :radio_station_id],
      unique: true, name: "index_hackr_radio_tunes_unique"
  end
end
