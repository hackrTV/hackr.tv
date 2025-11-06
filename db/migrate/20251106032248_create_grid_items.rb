class CreateGridItems < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_items do |t|
      t.string :name
      t.text :description
      t.string :item_type
      t.integer :room_id
      t.integer :grid_hackr_id
      t.json :properties

      t.timestamps
    end
  end
end
