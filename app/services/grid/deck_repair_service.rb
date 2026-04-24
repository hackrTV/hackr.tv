# frozen_string_literal: true

module Grid
  class DeckRepairService
    Result = Data.define(:deck_name, :fried_level_cleared, :cred_paid, :display)

    class NoDeckEquipped < StandardError; end
    class DeckNotFried < StandardError; end
    class InsufficientBalance < StandardError; end
    class NotAtRepairService < StandardError; end

    # Quality multiplier based on DECK rarity — better DECKs cost more to repair
    RARITY_QUALITY = {
      "scrap" => 1,
      "ubiquitous" => 1,
      "common" => 2,
      "uncommon" => 3,
      "rare" => 5,
      "ultra_rare" => 8,
      "unicorn" => 12
    }.freeze

    BASE_COST_PER_LEVEL = 150 # CRED — Basic DECK at level 1 = 150 CRED

    def self.repair_at_npc!(hackr:)
      new(hackr).repair_at_npc!
    end

    def self.repair_cost(deck)
      fried = deck.deck_fried_level
      quality = RARITY_QUALITY.fetch(deck.rarity.to_s, 1)
      BASE_COST_PER_LEVEL * fried * quality
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def repair_at_npc!
      room = @hackr.current_room
      raise NotAtRepairService, "There's no repair service here." unless room&.room_type == "repair_service"

      deck = @hackr.equipped_deck
      raise NoDeckEquipped, "No DECK equipped." unless deck
      raise DeckNotFried, "Your DECK is not damaged." unless deck.deck_fried?

      cost = self.class.repair_cost(deck)
      cache = @hackr.default_cache
      raise InsufficientBalance, "Need #{cost} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= cost

      fried_level = nil
      ActiveRecord::Base.transaction do
        @hackr.lock!
        deck.lock!

        # Re-check after lock
        raise DeckNotFried, "Your DECK is not damaged." unless deck.deck_fried?

        # Re-check balance after lock (prevent TOCTOU race)
        cost = self.class.repair_cost(deck)
        cache = @hackr.default_cache
        raise InsufficientBalance, "Need #{cost} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= cost

        fried_level = deck.deck_fried_level
        deck.update!(properties: deck.properties.merge("fried_level" => 0))
      end

      # CRED payment outside transaction (TransactionService has its own mutex).
      # If payment fails, restore the fried_level to prevent free repairs.
      begin
        split_repair_payment!(from_cache: cache, amount: cost, deck_name: deck.name)
      rescue => e
        deck.update!(properties: deck.properties.merge("fried_level" => fried_level))
        raise InsufficientBalance, "Payment failed — DECK damage restored. #{e.message}"
      end

      display = render_repair(deck.name, fried_level, cost)
      Result.new(deck_name: deck.name, fried_level_cleared: fried_level, cred_paid: cost, display: display)
    end

    private

    def split_repair_payment!(from_cache:, amount:, deck_name:)
      burn_amt = (amount * EconomyConfig::SHOP_BURN_RATIO).floor
      recycle_amt = amount - burn_amt

      if burn_amt > 0
        Grid::TransactionService.burn!(
          from_cache: from_cache,
          amount: burn_amt,
          memo: "DECK repair: #{deck_name}"
        )
      end

      if recycle_amt > 0
        Grid::TransactionService.recycle!(
          from_cache: from_cache,
          amount: recycle_amt,
          memo: "DECK repair: #{deck_name}"
        )
      end
    end

    def render_repair(deck_name, fried_level, cost)
      h = ->(text) { ERB::Util.html_escape(text.to_s) }
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>[ DECK REPAIR COMPLETE ]</span>"
      lines << "<span style='color: #d0d0d0;'>  DECK: #{h.call(deck_name)}</span>"
      lines << "<span style='color: #9ca3af;'>  Damage cleared: level #{fried_level}/5</span>"
      lines << "<span style='color: #fbbf24;'>  Cost: #{cost} CRED</span>"
      lines.join("\n")
    end
  end
end
