class AddTotpToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :otp_secret, :string
    add_column :grid_hackrs, :otp_required_for_login, :boolean, null: false, default: false
    add_column :grid_hackrs, :otp_backup_code_digests, :json
  end
end
