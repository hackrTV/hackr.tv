class CreateGridEconomyTables < ActiveRecord::Migration[8.1]
  def change
    # Caches (wallets) — player-owned or system (mining pool, gameplay pool, burn, redemption, genesis)
    create_table :grid_caches do |t|
      t.string :address, null: false
      t.integer :grid_hackr_id
      t.string :status, null: false, default: "active"
      t.boolean :is_default, default: false, null: false
      t.string :system_type # null = player, "mining_pool", "gameplay_pool", "burn", "redemption", "genesis"
      t.string :nickname
      t.datetime :archived_at
      t.timestamps
    end

    add_index :grid_caches, :address, unique: true
    add_index :grid_caches, :grid_hackr_id
    add_index :grid_caches, :system_type
    add_index :grid_caches, [:grid_hackr_id, :nickname], unique: true, where: "nickname IS NOT NULL", name: "index_grid_caches_on_hackr_nickname"

    # Transactions — append-only ledger, global hash chain
    create_table :grid_transactions do |t|
      t.integer :from_cache_id, null: false
      t.integer :to_cache_id, null: false
      t.integer :amount, null: false
      t.string :tx_type, null: false # transfer, mining_reward, gameplay_reward, burn, redemption, genesis
      t.string :memo
      t.string :tx_hash, null: false
      t.string :previous_tx_hash
      t.datetime :created_at, null: false
    end

    add_index :grid_transactions, :tx_hash, unique: true
    add_index :grid_transactions, :from_cache_id
    add_index :grid_transactions, :to_cache_id
    add_index :grid_transactions, :created_at
    add_index :grid_transactions, :tx_type

    # Mining rigs — one per hackr
    create_table :grid_mining_rigs do |t|
      t.integer :grid_hackr_id, null: false
      t.boolean :active, default: false, null: false
      t.datetime :last_tick_at
      t.timestamps
    end

    add_index :grid_mining_rigs, :grid_hackr_id, unique: true

    # Uplink presence tracking — TTL-based for stream viewing bonus
    create_table :grid_uplink_presences do |t|
      t.integer :grid_hackr_id, null: false
      t.integer :chat_channel_id, null: false
      t.datetime :last_seen_at, null: false
    end

    add_index :grid_uplink_presences, [:grid_hackr_id, :chat_channel_id], unique: true, name: "index_grid_uplink_presences_unique"
    add_index :grid_uplink_presences, :last_seen_at

    # Add mining rig reference to grid_items (component installation)
    add_column :grid_items, :grid_mining_rig_id, :integer
    add_index :grid_items, :grid_mining_rig_id

    # Add registration IP to grid_hackrs for anti-abuse tracking
    add_column :grid_hackrs, :registration_ip, :string
  end
end
