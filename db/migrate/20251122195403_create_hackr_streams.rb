class CreateHackrStreams < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_streams do |t|
      t.references :artist, null: false, foreign_key: true
      t.boolean :is_live, default: false, null: false
      t.string :live_url
      t.string :vod_url
      t.string :title
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
