class CreateOverlaySceneGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :overlay_scene_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end

    add_index :overlay_scene_groups, :slug, unique: true
  end
end
