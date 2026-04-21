# frozen_string_literal: true

namespace :grid do
  desc "Grant CRED to a hackr's default cache. Usage: rake grid:grant_cred[AMOUNT,ALIAS,pool]"
  task :grant_cred, [:amount, :alias, :pool] => :environment do |_t, args|
    abort "ERROR: This task can only be run in development." unless Rails.env.development?

    amount = (args[:amount] || abort("ERROR: amount required.")).to_i
    hackr_alias = args[:alias] || "XERAEN"
    abort "ERROR: amount must be positive." unless amount > 0

    pool_key = (args[:pool] || "mine").downcase
    abort "ERROR: pool must be 'play' or 'mine'." unless %w[play mine].include?(pool_key)

    hackr = GridHackr.find_by!(hackr_alias: hackr_alias)
    cache = GridCache.where(grid_hackr: hackr, is_default: true).first ||
      GridCache.where(grid_hackr: hackr).active.first
    abort "ERROR: No active cache found for #{hackr_alias}." unless cache

    pool = (pool_key == "play") ? GridCache.gameplay_pool : GridCache.mining_pool

    prev_hash = GridTransaction.order(created_at: :desc, id: :desc).first&.tx_hash

    tx = GridTransaction.new(
      from_cache: pool,
      to_cache: cache,
      amount: amount,
      tx_type: (pool_key == "play") ? "gameplay_reward" : "mining_reward",
      memo: "Dev grant: #{amount} CRED from #{pool_key} pool",
      previous_tx_hash: prev_hash,
      created_at: Time.current
    )
    tx.tx_hash = tx.compute_hash
    tx.save!

    puts "Granted #{amount} CRED to #{hackr_alias}"
    puts "  From: #{pool.address} (#{pool_key})"
    puts "  To:   #{cache.address}"
    puts "  TX:   #{tx.short_hash}"
    puts "  New balance: #{cache.reload.balance}"
  end
end
