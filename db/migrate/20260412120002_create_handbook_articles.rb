class CreateHandbookArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :handbook_articles do |t|
      t.references :handbook_section, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.string :slug, null: false
      t.string :kind, default: "reference", null: false
      t.string :difficulty
      t.text :summary
      t.text :body
      t.integer :position, default: 0, null: false
      t.boolean :published, default: true, null: false
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :handbook_articles, :slug, unique: true
    add_index :handbook_articles, :kind
    add_index :handbook_articles, :published
    add_index :handbook_articles, [:handbook_section_id, :position]
  end
end
