class CreateHackrVodWatches < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_vod_watches do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :hackr_stream, null: false, foreign_key: true
      t.datetime :watched_at, null: false
      t.timestamps
    end
    add_index :hackr_vod_watches, [:grid_hackr_id, :hackr_stream_id],
      unique: true, name: "index_hackr_vod_watches_unique"
  end
end
