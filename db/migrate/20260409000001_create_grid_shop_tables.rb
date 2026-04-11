class CreateGridShopTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_shop_listings do |t|
      t.references :grid_mob, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.string :item_type
      t.string :rarity
      t.json :properties, default: {}
      t.integer :base_price, null: false
      t.integer :sell_price, null: false
      t.integer :stock           # nil = unlimited
      t.integer :max_stock       # nil = unlimited
      t.integer :restock_amount, default: 1, null: false
      t.integer :restock_interval_hours, default: 24, null: false
      t.datetime :next_restock_at
      t.boolean :active, default: true, null: false
      t.boolean :rotation_pool, default: false, null: false
      t.integer :min_clearance, default: 0, null: false
      t.timestamps
    end

    add_index :grid_shop_listings, [:grid_mob_id, :active]
    add_index :grid_shop_listings, :next_restock_at

    create_table :grid_shop_transactions do |t|
      t.references :grid_hackr, null: true, index: true
      t.references :grid_shop_listing, null: true, index: true
      t.references :grid_mob, null: true, index: true
      t.string :transaction_type, null: false
      t.integer :quantity, default: 1, null: false
      t.integer :price_paid, null: false
      t.integer :burn_amount, null: false, default: 0
      t.integer :recycle_amount, null: false, default: 0
      t.datetime :created_at, null: false
    end

    add_index :grid_shop_transactions, [:grid_hackr_id, :created_at]
  end
end
