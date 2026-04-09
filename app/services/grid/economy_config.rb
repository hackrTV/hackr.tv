# frozen_string_literal: true

module Grid
  module EconomyConfig
    TOTAL_SUPPLY        = 1_000_000_000
    MINING_POOL_SHARE   = 0.70  # 700,000,000
    GAMEPLAY_POOL_SHARE = 0.30  # 300,000,000
    BASE_MINING_RATE    = 1     # CRED per tick at base level
    TICK_INTERVAL       = 5.minutes
    INACTIVITY_SHUTOFF  = 7.days
    PRESENCE_TTL        = 10.minutes
    CHAT_BONUS          = 1     # flat CRED per tick for chatting during live stream

    MINING_POOL_TOTAL   = (TOTAL_SUPPLY * MINING_POOL_SHARE).to_i
    GAMEPLAY_POOL_TOTAL = (TOTAL_SUPPLY * GAMEPLAY_POOL_SHARE).to_i

    # Halving milestones: rate halves each time this cumulative % of the mining pool is mined.
    # 0–50% mined → 1.0x, 50–75% → 0.5x, 75–87.5% → 0.25x, etc.
    HALVING_THRESHOLDS = [0.50, 0.75, 0.875, 0.9375, 0.96875, 0.984375, 0.9921875].freeze

    # Calculate the current halving factor based on how much of the mining pool has been mined.
    # Returns a float between 0 and 1.0 (e.g., 1.0, 0.5, 0.25, 0.125...)
    def self.halving_factor
      mined = mining_pool_mined
      fraction_mined = mined.to_f / MINING_POOL_TOTAL

      halvings = HALVING_THRESHOLDS.count { |threshold| fraction_mined >= threshold }
      1.0 / (2**halvings)
    end

    # How much CRED has been mined from the mining pool
    def self.mining_pool_mined
      MINING_POOL_TOTAL - mining_pool_balance
    end

    # Current balance of the mining pool cache
    def self.mining_pool_balance
      GridCache.mining_pool.balance
    rescue ActiveRecord::RecordNotFound
      MINING_POOL_TOTAL # Not seeded yet
    end

    # Current balance of the gameplay pool cache
    def self.gameplay_pool_balance
      GridCache.gameplay_pool.balance
    rescue ActiveRecord::RecordNotFound
      GAMEPLAY_POOL_TOTAL
    end

    def self.total_mined
      mining_pool_mined
    end

    def self.total_gameplay_awarded
      GAMEPLAY_POOL_TOTAL - gameplay_pool_balance
    end

    def self.total_burned
      GridCache.burn.balance
    rescue ActiveRecord::RecordNotFound
      0
    end

    def self.total_redeemed
      GridCache.redemption.balance
    rescue ActiveRecord::RecordNotFound
      0
    end
  end
end
