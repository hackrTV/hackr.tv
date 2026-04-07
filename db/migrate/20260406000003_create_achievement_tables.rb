class CreateAchievementTables < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_achievements do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.string :badge_icon
      t.string :trigger_type, null: false
      t.json :trigger_data, default: {}
      t.integer :xp_reward, default: 0, null: false
      t.boolean :hidden, default: false, null: false
      t.timestamps
    end
    add_index :grid_achievements, :slug, unique: true
    add_index :grid_achievements, :trigger_type

    create_table :grid_hackr_achievements do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :grid_achievement, null: false, foreign_key: true
      t.datetime :awarded_at, null: false
      t.timestamps
    end
    add_index :grid_hackr_achievements, [:grid_hackr_id, :grid_achievement_id],
      unique: true, name: "index_hackr_achievements_unique"
  end
end
