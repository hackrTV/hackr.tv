class AddLastActivityAtToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :last_activity_at, :datetime
  end
end
