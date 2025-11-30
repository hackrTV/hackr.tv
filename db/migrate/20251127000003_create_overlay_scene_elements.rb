class CreateOverlaySceneElements < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_scene_elements do |t|
      t.references :overlay_scene, null: false, foreign_key: true
      t.references :overlay_element, null: false, foreign_key: true
      t.integer :x, default: 0
      t.integer :y, default: 0
      t.integer :width
      t.integer :height
      t.integer :z_index, default: 0
      t.json :overrides, default: {}

      t.timestamps
    end

    add_index :overlay_scene_elements, [:overlay_scene_id, :overlay_element_id],
      name: "idx_scene_elements_composite"
    add_index :overlay_scene_elements, :z_index
  end
end
