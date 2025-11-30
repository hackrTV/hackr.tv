class CreateOverlayElements < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_elements do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :element_type, null: false
      t.json :settings, default: {}
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :overlay_elements, :slug, unique: true
    add_index :overlay_elements, :element_type
    add_index :overlay_elements, :active
  end
end
