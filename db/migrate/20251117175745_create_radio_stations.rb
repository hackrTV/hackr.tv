class CreateRadioStations < ActiveRecord::Migration[8.1]
  def change
    create_table :radio_stations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :genre
      t.string :color
      t.string :stream_url
      t.integer :position, null: false, default: 0
      t.boolean :hidden, null: false, default: false

      t.timestamps
    end

    add_index :radio_stations, :slug, unique: true
    add_index :radio_stations, :position
  end
end
