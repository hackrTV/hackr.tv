class CreateGridRegistrationTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_registration_tokens do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.string :ip_address

      t.timestamps
    end

    add_index :grid_registration_tokens, :token, unique: true
    add_index :grid_registration_tokens, :email
  end
end
