class CreateOverlayTickers < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_tickers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :content, null: false
      t.integer :speed, default: 50
      t.string :direction, default: "left"
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :overlay_tickers, :slug, unique: true
    add_index :overlay_tickers, :active
  end
end
