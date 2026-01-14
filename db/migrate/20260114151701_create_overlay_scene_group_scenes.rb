class CreateOverlaySceneGroupScenes < ActiveRecord::Migration[8.1]
  def change
    create_table :overlay_scene_group_scenes do |t|
      t.references :overlay_scene_group, null: false, foreign_key: true
      t.references :overlay_scene, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :overlay_scene_group_scenes, [:overlay_scene_group_id, :overlay_scene_id], unique: true, name: "index_scene_group_scenes_unique"
    add_index :overlay_scene_group_scenes, [:overlay_scene_group_id, :position], name: "index_scene_group_scenes_position"
  end
end
