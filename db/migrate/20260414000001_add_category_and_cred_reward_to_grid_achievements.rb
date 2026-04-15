class AddCategoryAndCredRewardToGridAchievements < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_achievements, :cred_reward, :integer, default: 0, null: false
    add_column :grid_achievements, :category, :string, default: "grid", null: false
    add_index :grid_achievements, :category
  end
end
