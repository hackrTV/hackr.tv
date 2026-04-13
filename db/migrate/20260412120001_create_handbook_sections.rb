class CreateHandbookSections < ActiveRecord::Migration[8.1]
  def change
    create_table :handbook_sections do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :icon
      t.text :summary
      t.integer :position, default: 0, null: false
      t.boolean :published, default: true, null: false

      t.timestamps
    end

    add_index :handbook_sections, :slug, unique: true
    add_index :handbook_sections, :published
    add_index :handbook_sections, [:published, :position]
  end
end
