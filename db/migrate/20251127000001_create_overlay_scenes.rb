class CreateOverlayScenes < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_scenes do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :scene_type, null: false, default: "composition"
      t.integer :width, default: 1920
      t.integer :height, default: 1080
      t.boolean :active, default: true
      t.json :settings, default: {}
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :overlay_scenes, :slug, unique: true
    add_index :overlay_scenes, :scene_type
    add_index :overlay_scenes, :active
  end
end
