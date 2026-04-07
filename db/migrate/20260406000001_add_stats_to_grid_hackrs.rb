class AddStatsToGridHackrs < ActiveRecord::Migration[8.0]
  def change
    add_column :grid_hackrs, :stats, :json
  end
end
