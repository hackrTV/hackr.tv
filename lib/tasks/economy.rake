namespace :data do
  desc "Seed CRED economy: system caches and genesis transactions"
  task economy: :environment do
    puts "\n" + "-" * 60
    puts "SEEDING CRED ECONOMY"
    puts "-" * 60 + "\n"

    # Create system caches (idempotent)
    system_caches = [
      {address: "CACHE-GNSS-0000", system_type: "genesis", label: "Genesis"},
      {address: "CACHE-MINE-POOL", system_type: "mining_pool", label: "Mining Pool"},
      {address: "CACHE-PLAY-POOL", system_type: "gameplay_pool", label: "Gameplay Pool"},
      {address: "CACHE-BURN-0000", system_type: "burn", label: "Burn"},
      {address: "CACHE-REDM-0000", system_type: "redemption", label: "Redemption"}
    ]

    system_caches.each do |attrs|
      cache = GridCache.find_or_create_by!(address: attrs[:address]) do |c|
        c.status = "active"
        c.system_type = attrs[:system_type]
      end
      puts "  #{attrs[:label]}: #{cache.address} (#{cache.system_type})"
    end

    # Genesis transactions (only if no transactions exist yet)
    if GridTransaction.none?
      puts "\n  Creating genesis transactions..."

      genesis = GridCache.genesis
      mining_pool = GridCache.mining_pool
      gameplay_pool = GridCache.gameplay_pool

      mining_amount = Grid::EconomyConfig::MINING_POOL_TOTAL
      gameplay_amount = Grid::EconomyConfig::GAMEPLAY_POOL_TOTAL

      # Genesis: distribute supply from the genesis cache to the two pools.
      # Genesis balance will be -1B (it created 1B from nothing). This is correct.
      now = Time.current

      # 1. Mining pool allocation (70%)
      mining_tx = GridTransaction.new(
        from_cache: genesis,
        to_cache: mining_pool,
        amount: mining_amount,
        tx_type: "genesis",
        memo: "Mining pool allocation (70%)",
        previous_tx_hash: nil,
        created_at: now
      )
      mining_tx.tx_hash = mining_tx.compute_hash
      mining_tx.save!
      puts "    TX 1: Genesis → Mining pool #{mining_amount} CRED (#{mining_tx.short_hash})"

      # 2. Gameplay pool allocation (30%)
      gameplay_tx = GridTransaction.new(
        from_cache: genesis,
        to_cache: gameplay_pool,
        amount: gameplay_amount,
        tx_type: "genesis",
        memo: "Gameplay pool allocation (30%)",
        previous_tx_hash: mining_tx.tx_hash,
        created_at: now + 0.001.seconds
      )
      gameplay_tx.tx_hash = gameplay_tx.compute_hash
      gameplay_tx.save!
      puts "    TX 2: Genesis → Gameplay pool #{gameplay_amount} CRED (#{gameplay_tx.short_hash})"

      puts "\n  Genesis complete. Ledger initialized with 2 transactions."
    else
      puts "\n  Ledger already has #{GridTransaction.count} transactions — skipping genesis."
    end

    # Provision economy for existing hackrs who don't have caches
    unprovisioned = GridHackr.left_joins(:grid_caches).where(grid_caches: {id: nil})
    if unprovisioned.any?
      puts "\n  Provisioning #{unprovisioned.count} existing hackrs..."
      unprovisioned.find_each do |hackr|
        hackr.provision_economy!
        puts "    #{hackr.hackr_alias}: cache + rig provisioned"
      end
    end

    # Ensure all rigs have full base components (backfill from single-GPU era)
    incomplete_rigs = GridMiningRig.includes(:grid_items, :grid_hackr).select { |rig| !rig.functional? }
    if incomplete_rigs.any?
      puts "\n  Backfilling #{incomplete_rigs.count} incomplete rigs..."
      base_slugs = %w[basic-motherboard basic-psu basic-cpu basic-gpu basic-ram]
      definitions = GridItemDefinition.where(slug: base_slugs).index_by(&:slug)

      incomplete_rigs.each do |rig|
        installed_slots = rig.components.map(&:slot)
        base_slugs.each do |slug|
          defn = definitions[slug]
          next unless defn
          next if installed_slots.include?(defn.properties["slot"])
          GridItem.create!(defn.item_attributes.merge(grid_mining_rig: rig))
        end
        puts "    #{rig.grid_hackr.hackr_alias}: backfilled to #{rig.reload.components.count} components (functional=#{rig.functional?})"
      end
    end

    puts "\n" + "-" * 60
    puts "CRED ECONOMY SEEDED"
    puts "-" * 60 + "\n"
  end
end
