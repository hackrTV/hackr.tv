class AddLoginDisabledToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :login_disabled, :boolean, null: false, default: false
  end
end
