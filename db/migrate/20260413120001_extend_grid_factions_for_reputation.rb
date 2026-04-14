class ExtendGridFactionsForReputation < ActiveRecord::Migration[8.1]
  def change
    add_reference :grid_factions, :parent, foreign_key: {to_table: :grid_factions}, index: true, null: true
    add_column :grid_factions, :kind, :string, default: "collective", null: false
    add_column :grid_factions, :position, :integer, default: 0, null: false
    add_index :grid_factions, :kind
    add_index :grid_factions, :slug, unique: true unless index_exists?(:grid_factions, :slug, unique: true)

    create_table :grid_faction_rep_links do |t|
      t.references :source_faction, null: false, foreign_key: {to_table: :grid_factions}, index: true
      t.references :target_faction, null: false, foreign_key: {to_table: :grid_factions}, index: true
      t.decimal :weight, precision: 6, scale: 3, null: false
      t.timestamps
    end
    add_index :grid_faction_rep_links, [:source_faction_id, :target_faction_id],
      unique: true, name: "index_faction_rep_links_unique"
  end
end
