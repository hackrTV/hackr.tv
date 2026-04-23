# frozen_string_literal: true

module Grid
  # Manages GovCorp debt incurred at RestorePoint™ facilities.
  # Debt is stored as `govcorp_debt` in the hackr's stats JSON.
  # When a hackr has outstanding debt, 50% of all incoming CRED
  # (mining, gameplay rewards) is garnished until the debt is cleared.
  class DebtService
    GARNISHMENT_RATE = 0.50

    class InsufficientFunds < StandardError; end

    # Incur a debt (or add to existing). Attempts to pay from cache first;
    # any shortfall becomes debt.
    # Returns { paid:, debt_incurred:, total_debt: }
    def self.assess!(hackr:, amount:, memo: "GovCorp fee")
      raise ArgumentError, "Amount must be positive" unless amount.is_a?(Integer) && amount.positive?

      cache = hackr.default_cache
      paid = 0

      # Pay what we can from cache
      if cache&.active?
        available = cache.reload.balance
        payable = [available, amount].min
        if payable > 0
          Grid::TransactionService.burn!(from_cache: cache, amount: payable, memo: memo)
          paid = payable
        end
      end

      # Remainder becomes debt
      shortfall = amount - paid
      if shortfall > 0
        current_debt = hackr.stat("govcorp_debt").to_i
        hackr.set_stat!("govcorp_debt", current_debt + shortfall)
      end

      total_debt = hackr.stat("govcorp_debt").to_i
      {paid: paid, debt_incurred: shortfall, total_debt: total_debt}
    end

    # Garnish incoming CRED. Called before minting to a hackr's cache.
    # Returns { net_amount:, garnished:, remaining_debt: }
    # If hackr has no debt, returns full amount with 0 garnished.
    def self.garnish(hackr:, gross_amount:)
      debt = hackr.stat("govcorp_debt").to_i
      return {net_amount: gross_amount, garnished: 0, remaining_debt: 0} if debt <= 0

      garnish_amount = (gross_amount * GARNISHMENT_RATE).ceil
      # Don't garnish more than the remaining debt
      garnish_amount = [garnish_amount, debt].min
      # Don't garnish more than the gross amount
      garnish_amount = [garnish_amount, gross_amount].min

      new_debt = debt - garnish_amount
      hackr.set_stat!("govcorp_debt", new_debt)

      net = gross_amount - garnish_amount
      {net_amount: net, garnished: garnish_amount, remaining_debt: new_debt}
    end

    # Voluntary debt payment from cache.
    # Returns { paid:, remaining_debt: }
    def self.pay!(hackr:, amount: nil)
      debt = hackr.stat("govcorp_debt").to_i
      return {paid: 0, remaining_debt: 0} if debt <= 0

      cache = hackr.default_cache
      raise InsufficientFunds, "No active cache." unless cache&.active?

      available = cache.reload.balance
      # Default: pay as much as possible
      amount ||= [available, debt].min
      amount = [amount, debt].min
      amount = [amount, available].min

      return {paid: 0, remaining_debt: debt} if amount <= 0

      Grid::TransactionService.burn!(from_cache: cache, amount: amount, memo: "GovCorp debt payment")
      new_debt = debt - amount
      hackr.set_stat!("govcorp_debt", new_debt)

      {paid: amount, remaining_debt: new_debt}
    end

    # Check current debt
    def self.debt_for(hackr)
      hackr.stat("govcorp_debt").to_i
    end
  end
end
