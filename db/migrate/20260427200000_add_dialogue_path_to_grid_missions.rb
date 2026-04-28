class AddDialoguePathToGridMissions < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_missions, :dialogue_path, :json
  end
end
