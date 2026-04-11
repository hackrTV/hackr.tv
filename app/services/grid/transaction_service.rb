# frozen_string_literal: true

module Grid
  class TransactionService
    class InsufficientBalance < StandardError; end
    class InvalidTransfer < StandardError; end

    # Serialize all ledger writes. SQLite uses BEGIN DEFERRED by default,
    # which only acquires the write lock on the first write statement —
    # meaning two concurrent transactions can both read stale balances
    # and the same previous_tx_hash before either writes. This mutex
    # ensures all reads + writes in execute! are atomic.
    LEDGER_MUTEX = Mutex.new

    # Player-to-player transfer
    def self.transfer!(from_cache:, to_cache:, amount:, memo: nil)
      raise InvalidTransfer, "Amount must be a positive integer" unless amount.is_a?(Integer) && amount.positive?
      raise InvalidTransfer, "Cannot transfer to the same cache" if from_cache.id == to_cache.id
      raise InvalidTransfer, "Source cache is not active" unless from_cache.active?
      raise InvalidTransfer, "Target cache is not active" unless to_cache.active?

      execute!(from_cache: from_cache, to_cache: to_cache, amount: amount, tx_type: "transfer", memo: memo)
    end

    # Mining reward (mining pool → hackr's cache)
    def self.mint_mining!(to_cache:, amount:)
      execute!(from_cache: GridCache.mining_pool, to_cache: to_cache, amount: amount, tx_type: "mining_reward", memo: "Mining reward")
    end

    # Gameplay reward (gameplay pool → hackr's cache)
    def self.mint_gameplay!(to_cache:, amount:, memo: "Gameplay reward")
      execute!(from_cache: GridCache.gameplay_pool, to_cache: to_cache, amount: amount, tx_type: "gameplay_reward", memo: memo)
    end

    # General burn (hackr cache → burn address)
    def self.burn!(from_cache:, amount:, memo: nil)
      execute!(from_cache: from_cache, to_cache: GridCache.burn, amount: amount, tx_type: "burn", memo: memo)
    end

    # Redemption (hackr cache → redemption sink)
    def self.redeem!(from_cache:, amount:, memo:)
      execute!(from_cache: from_cache, to_cache: GridCache.redemption, amount: amount, tx_type: "redemption", memo: memo)
    end

    # Purchase recycle (player cache → gameplay pool)
    def self.recycle!(from_cache:, amount:, memo: nil)
      execute!(from_cache: from_cache, to_cache: GridCache.gameplay_pool, amount: amount, tx_type: "purchase_recycle", memo: memo)
    end

    # Genesis mint (genesis cache → genesis cache, then distribute)
    def self.genesis!(to_cache:, amount:, memo:)
      execute!(from_cache: GridCache.genesis, to_cache: to_cache, amount: amount, tx_type: "genesis", memo: memo)
    end

    private_class_method def self.execute!(from_cache:, to_cache:, amount:, tx_type:, memo: nil)
      raise InvalidTransfer, "Amount must be positive" unless amount.positive?

      LEDGER_MUTEX.synchronize do
        ActiveRecord::Base.transaction do
          # Balance check inside the lock — no stale reads
          unless tx_type == "genesis"
            balance = from_cache.reload.balance
            raise InsufficientBalance, "Insufficient balance" if balance < amount
          end

          last_tx = GridTransaction.recent.first
          now = Time.current

          tx = GridTransaction.new(
            from_cache: from_cache,
            to_cache: to_cache,
            amount: amount,
            tx_type: tx_type,
            memo: memo,
            previous_tx_hash: last_tx&.tx_hash,
            created_at: now
          )
          tx.tx_hash = tx.compute_hash
          tx.save!
          tx
        end
      end
    end
  end
end
