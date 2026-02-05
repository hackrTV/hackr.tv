class CreateGridHackrs < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_hackrs do |t|
      t.string :hackr_alias
      t.string :email
      t.string :password_digest
      t.integer :current_room_id
      t.string :role

      t.timestamps
    end
    add_index :grid_hackrs, :role
    add_index :grid_hackrs, :hackr_alias, unique: true
    add_index :grid_hackrs, :email, unique: true
  end
end
