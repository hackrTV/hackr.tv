class CreateGridDenInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_den_invites do |t|
      t.integer :hackr_id, null: false
      t.integer :guest_id, null: false
      t.integer :den_id, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :grid_den_invites, [:hackr_id, :guest_id, :den_id], name: "index_den_invites_unique", unique: true
    add_index :grid_den_invites, :guest_id
    add_index :grid_den_invites, :den_id
    add_index :grid_den_invites, :expires_at

    add_foreign_key :grid_den_invites, :grid_hackrs, column: :hackr_id
    add_foreign_key :grid_den_invites, :grid_hackrs, column: :guest_id
    add_foreign_key :grid_den_invites, :grid_rooms, column: :den_id
  end
end
