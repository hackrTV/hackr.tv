class AddOtpLastUsedAtToGridHackrs < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackrs, :otp_last_used_at, :integer
  end
end
