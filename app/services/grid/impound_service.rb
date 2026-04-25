# frozen_string_literal: true

module Grid
  # Manages gear confiscation during BREACH failure (tiers 5+6).
  # Items move to an impound record — recoverable via bribe or forfeitable.
  # All formula values are named constants for future admin abstraction.
  class ImpoundService
    ImpoundResult = Data.define(:impound_record, :items_seized, :bribe_cost, :display)
    RecoverResult = Data.define(:impound_record, :items_returned, :cred_paid, :display)
    ForfeitResult = Data.define(:impound_record, :items_destroyed, :display)

    class NoEquippedGear < StandardError; end
    class RecordNotImpounded < StandardError; end
    class InsufficientBalance < StandardError; end
    class NotOwner < StandardError; end

    # Gear recovery bribe constants
    GEAR_BRIBE_BASE_FEE = 500
    GEAR_BRIBE_CL_MULT = 25
    GEAR_BRIBE_VALUE_MULT = 0.10

    def self.impound_gear!(hackr:, breach:)
      new(hackr).impound_gear!(breach)
    end

    def self.recover_gear!(hackr:, impound_record:)
      new(hackr).recover_gear!(impound_record)
    end

    def self.forfeit!(impound_record:)
      new(impound_record.grid_hackr).forfeit!(impound_record)
    end

    def self.compute_bribe(hackr:, items:)
      clearance = hackr.stat("clearance")
      gear_value = items.sum(&:value)
      (GEAR_BRIBE_BASE_FEE + clearance * GEAR_BRIBE_CL_MULT + (gear_value * GEAR_BRIBE_VALUE_MULT).floor).to_i
    end

    def initialize(hackr)
      @hackr = hackr
    end

    # Confiscate all equipped gear (including DECK with loaded software intact).
    # Called from BreachService#resolve_failure! for tier 6 failures.
    def impound_gear!(breach)
      record = nil
      items = []
      bribe = 0

      ActiveRecord::Base.transaction do
        @hackr.lock!

        items = @hackr.grid_items.equipped_by(@hackr).to_a
        raise NoEquippedGear, "No equipped gear to confiscate." if items.empty?

        bribe = self.class.compute_bribe(hackr: @hackr, items: items)

        record = GridImpoundRecord.create!(
          grid_hackr: @hackr,
          grid_hackr_breach: breach,
          status: "impounded",
          bribe_cost: bribe
        )

        items.each do |item|
          item.update!(
            equipped_slot: nil,
            grid_impound_record_id: record.id
          )

          # Impound software loaded in DECK and modules installed in DECK.
          # They travel with the DECK as a unit — not destroyed, recoverable.
          if item.deck_item?
            item.loaded_software.update_all(grid_impound_record_id: record.id)
            item.installed_modules.update_all(grid_impound_record_id: record.id)
          end
        end

        @hackr.reset_loadout_cache!
        clamp_vitals!
      end

      display = render_impound(items, bribe)
      ImpoundResult.new(
        impound_record: record,
        items_seized: items,
        bribe_cost: bribe,
        display: display
      )
    end

    # Pay bribe to recover a specific impound set. Items return to inventory
    # (unequipped — player must re-equip manually via LoadoutService).
    def recover_gear!(impound_record)
      raise NotOwner, "That impound record doesn't belong to you." unless impound_record.grid_hackr_id == @hackr.id
      raise RecordNotImpounded, "This impound set has already been resolved." unless impound_record.impounded?

      cost = impound_record.bribe_cost
      cache = @hackr.default_cache
      raise InsufficientBalance, "Need #{cost} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= cost

      items = []

      ActiveRecord::Base.transaction do
        @hackr.lock!
        impound_record.lock!

        raise RecordNotImpounded, "This impound set has already been resolved." unless impound_record.impounded?

        cache = @hackr.default_cache
        raise InsufficientBalance, "Need #{cost} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= cost

        items = impound_record.impounded_items.to_a

        items.each do |item|
          item.update!(grid_impound_record_id: nil)
        end

        impound_record.update!(status: "recovered")
        @hackr.reset_loadout_cache!
      end

      # CRED payment outside transaction (TransactionService has its own mutex).
      # If payment fails, roll back recovery to prevent free gear.
      begin
        split_bribe_payment!(from_cache: cache, amount: cost, record_id: impound_record.id)
      rescue => e
        begin
          ActiveRecord::Base.transaction do
            items.each { |item| item.update!(grid_impound_record_id: impound_record.id) }
            impound_record.update!(status: "impounded")
            @hackr.reset_loadout_cache!
          end
        rescue => rollback_error
          Rails.logger.error("[ImpoundService] CRITICAL: payment failed AND rollback failed for record #{impound_record.id}: #{rollback_error.message}")
        end
        raise InsufficientBalance, "Payment failed — gear re-impounded. #{e.message}"
      end

      display = render_recovery(items, cost)
      RecoverResult.new(
        impound_record: impound_record,
        items_returned: items,
        cred_paid: cost,
        display: display
      )
    end

    # Permanently destroy all items in an impound set.
    # Called when hackr bribes agent for direct exit (forfeit path).
    def forfeit!(impound_record)
      raise NotOwner, "That impound record doesn't belong to you." unless impound_record.grid_hackr_id == @hackr.id
      raise RecordNotImpounded, "This impound set has already been resolved." unless impound_record.impounded?

      items_destroyed = 0

      ActiveRecord::Base.transaction do
        @hackr.lock!
        impound_record.lock!
        raise RecordNotImpounded, "This impound set has already been resolved." unless impound_record.impounded?

        items_destroyed = impound_record.impounded_items.count
        impound_record.impounded_items.destroy_all
        impound_record.update!(status: "forfeited")
      end

      display = render_forfeit(items_destroyed)
      ForfeitResult.new(
        impound_record: impound_record,
        items_destroyed: items_destroyed,
        display: display
      )
    end

    private

    def split_bribe_payment!(from_cache:, amount:, record_id:)
      burn_amt = (amount * EconomyConfig::SHOP_BURN_RATIO).floor
      recycle_amt = amount - burn_amt

      if burn_amt > 0
        Grid::TransactionService.burn!(
          from_cache: from_cache,
          amount: burn_amt,
          memo: "IMPOUND bribe: record ##{record_id}"
        )
      end

      if recycle_amt > 0
        Grid::TransactionService.recycle!(
          from_cache: from_cache,
          amount: recycle_amt,
          memo: "IMPOUND bribe: record ##{record_id}"
        )
      end
    end

    # Clamp vitals to new effective max after gear bonuses removed.
    def clamp_vitals!
      %w[health energy psyche].each do |key|
        cap = @hackr.effective_max(key)
        current = @hackr.stat(key)
        @hackr.set_stat!(key, cap) if current > cap
      end
    end

    def render_impound(items, bribe)
      h = method(:h)
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #ef4444;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2551  GEAR CONFISCATED \u2014 GovCorp Impound Notice               \u2551</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>GovCorp Compliance Division has seized your loadout.</span>"
      lines << border
      items.each do |item|
        lines << "#{border}  <span style='color: #f87171;'>\u2717 #{h.call(item.name)}</span>"
      end
      lines << border
      lines << "#{border}  <span style='color: #fbbf24;'>Recovery bribe: #{bribe} CRED</span>"
      lines << "#{border}  <span style='color: #9ca3af;'>Visit an Impound Bay to negotiate recovery.</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def render_recovery(items, cost)
      h = method(:h)
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #34d399;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2551  GEAR RECOVERED                                            \u2551</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #fbbf24;'>Bribe paid: #{cost} CRED</span>"
      lines << border
      items.each do |item|
        lines << "#{border}  <span style='color: #d0d0d0;'>\u2713 #{h.call(item.name)} \u2014 returned to inventory</span>"
      end
      lines << border
      lines << "#{border}  <span style='color: #9ca3af;'>Re-equip your gear manually.</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def render_forfeit(count)
      lines = []
      lines << ""
      lines << "<span style='color: #6b7280; font-weight: bold;'>[ IMPOUND FORFEITED ]</span>"
      lines << "<span style='color: #6b7280;'>  #{count} item(s) permanently destroyed by GovCorp.</span>"
      lines.join("\n")
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
