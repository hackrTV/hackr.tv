class CreateArtists < ActiveRecord::Migration[8.0]
  def change
    create_table :artists do |t|
      t.string :name
      t.string :slug
      t.string :genre
      t.string :artist_type, default: "band", null: false

      t.timestamps
    end
    add_index :artists, :slug, unique: true
  end
end
