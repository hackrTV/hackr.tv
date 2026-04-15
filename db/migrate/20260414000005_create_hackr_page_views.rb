class CreateHackrPageViews < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_page_views do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.string :page_type, null: false
      t.integer :resource_id, null: false
      t.datetime :viewed_at, null: false
      t.timestamps
    end
    add_index :hackr_page_views, [:grid_hackr_id, :page_type, :resource_id],
      unique: true, name: "index_hackr_page_views_unique"
    add_index :hackr_page_views, [:grid_hackr_id, :page_type],
      name: "index_hackr_page_views_hackr_type"
  end
end
