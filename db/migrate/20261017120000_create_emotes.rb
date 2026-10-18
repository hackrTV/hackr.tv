class CreateEmotes < ActiveRecord::Migration[8.1]
  def change
    create_table :emotes do |t|
      t.string :slug, null: false
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :emotes, :slug, unique: true
  end
end
