class AddPuzzleGatesToGridBreachTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_breach_templates, :puzzle_gates, :json, null: false, default: []
  end
end
