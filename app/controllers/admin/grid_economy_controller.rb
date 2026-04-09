class Admin::GridEconomyController < Admin::ApplicationController
  def index
    config = Grid::EconomyConfig

    @supply = {
      total: config::TOTAL_SUPPLY,
      mining_pool_total: config::MINING_POOL_TOTAL,
      mining_pool_balance: config.mining_pool_balance,
      mining_pool_mined: config.mining_pool_mined,
      gameplay_pool_total: config::GAMEPLAY_POOL_TOTAL,
      gameplay_pool_balance: config.gameplay_pool_balance,
      gameplay_awarded: config.total_gameplay_awarded,
      total_burned: config.total_burned,
      total_redeemed: config.total_redeemed,
      halving_factor: config.halving_factor
    }

    @caches = GridCache.includes(:grid_hackr).order(:created_at)
    @recent_transactions = GridTransaction.recent.limit(100).includes(:from_cache, :to_cache)
    @active_rigs = GridMiningRig.where(active: true).includes(:grid_hackr, grid_items: [])

    # Anti-abuse: IPs with multiple active mining rigs
    @flagged_ips = GridHackr
      .joins(:grid_mining_rig)
      .where(grid_mining_rigs: {active: true})
      .where.not(registration_ip: nil)
      .group(:registration_ip)
      .having("COUNT(*) > 1")
      .count
  end

  private

  def format_cred(amount)
    amount.to_s.reverse.scan(/\d{1,3}/).join(",").reverse
  end
  helper_method :format_cred
end
