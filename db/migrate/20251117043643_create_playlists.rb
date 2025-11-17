class CreatePlaylists < ActiveRecord::Migration[8.1]
  def change
    create_table :playlists do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :is_public, default: false, null: false
      t.string :share_token, null: false

      t.timestamps
    end

    add_index :playlists, :share_token, unique: true
  end
end
