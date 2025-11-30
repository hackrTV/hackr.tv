class CreateOverlayNowPlaying < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_now_playing do |t|
      t.references :track, foreign_key: true
      t.string :custom_title
      t.string :custom_artist
      t.boolean :is_live, default: false
      t.boolean :paused, default: false, null: false
      t.datetime :started_at

      t.timestamps
    end
  end
end
