class CreateReleases < ActiveRecord::Migration[8.1]
  def change
    create_table :releases do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :release_type
      t.date :release_date
      t.text :description
      t.string :catalog_number
      t.string :media_format
      t.string :classification
      t.string :label
      t.text :credits
      t.text :notes
      t.references :artist, null: false, foreign_key: true

      t.timestamps
    end

    add_index :releases, [:artist_id, :slug], unique: true
  end
end
