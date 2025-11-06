class CreateGridMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_messages do |t|
      t.integer :grid_hackr_id
      t.integer :room_id
      t.string :message_type
      t.text :content
      t.integer :target_hackr_id

      t.timestamps
    end
  end
end
