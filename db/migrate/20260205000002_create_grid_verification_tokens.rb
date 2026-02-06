class CreateGridVerificationTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_verification_tokens do |t|
      t.integer :grid_hackr_id, null: false
      t.string :purpose, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :ip_address

      t.timestamps
    end

    add_index :grid_verification_tokens, :token, unique: true
    add_index :grid_verification_tokens, :grid_hackr_id
    add_index :grid_verification_tokens, [:grid_hackr_id, :purpose]
    add_foreign_key :grid_verification_tokens, :grid_hackrs
  end
end
