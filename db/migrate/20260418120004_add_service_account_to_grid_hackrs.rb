class AddServiceAccountToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :service_account, :boolean, null: false, default: false
  end
end
