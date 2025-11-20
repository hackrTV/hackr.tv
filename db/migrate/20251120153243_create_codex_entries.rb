class CreateCodexEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :codex_entries do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :entry_type, null: false
      t.text :summary
      t.text :content
      t.json :metadata, default: {}
      t.boolean :published, default: false, null: false
      t.integer :position

      t.timestamps
    end
    add_index :codex_entries, :slug, unique: true
    add_index :codex_entries, :entry_type
    add_index :codex_entries, :published
  end
end
