class CreateGridHackrTrackPlays < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_hackr_track_plays do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.datetime :first_played_at, null: false
      t.integer :play_count, default: 1, null: false
      t.timestamps
    end
    add_index :grid_hackr_track_plays, [:grid_hackr_id, :track_id], unique: true, name: "index_track_plays_unique"
  end
end
