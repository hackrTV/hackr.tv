class AddApiTokenToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :api_token, :string
    add_index :grid_hackrs, :api_token, unique: true
  end
end
