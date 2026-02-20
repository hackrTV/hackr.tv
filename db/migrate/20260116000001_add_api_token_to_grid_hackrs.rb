class AddApiTokenToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :api_token_digest, :string
    add_index :grid_hackrs, :api_token_digest, unique: true
  end
end
