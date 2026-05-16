# frozen_string_literal: true

module Grid
  class RestPodService
    Result = Data.define(:allocations, :total_cred_paid, :display)

    class NotAtRestPod < StandardError; end
    class InvalidAllocation < StandardError; end
    class InsufficientBalance < StandardError; end
    class NothingToRestore < StandardError; end

    VITALS = %w[health energy psyche].freeze
    CL_THRESHOLD = 30
    RATE_DISCOUNTED = 2 # points per CRED (CL < 30)
    RATE_STANDARD = 1   # points per CRED (CL >= 30)

    # allocs: Array of { vital: "health"|"energy"|"psyche", points: Integer }
    def self.restore!(hackr:, allocs:)
      new(hackr).restore!(allocs)
    end

    def self.rate_for(hackr)
      (hackr.stat("clearance").to_i >= CL_THRESHOLD) ? RATE_STANDARD : RATE_DISCOUNTED
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def restore!(allocs)
      room = @hackr.current_room
      raise NotAtRestPod, "There's no Rest Pod here." unless room&.room_type == "rest_pod"
      raise InvalidAllocation, "No allocation specified." if allocs.empty?

      allocs.each do |a|
        raise InvalidAllocation, "Unknown vital: #{a[:vital]}" unless VITALS.include?(a[:vital])
        raise InvalidAllocation, "Points must be positive." unless a[:points].to_i > 0
      end

      rate = self.class.rate_for(@hackr)

      # Pre-check balance (fast-fail before locking)
      cache = @hackr.default_cache
      max_points = allocs.sum { |a| a[:points].to_i }
      max_cost = (max_points.to_f / rate).ceil
      raise InsufficientBalance, "Insufficient CRED." unless cache&.balance.to_i >= max_cost

      final_allocs = nil
      total_cred = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!

        # Snapshot vitals under lock for deficit computation
        prior_vitals = VITALS.each_with_object({}) { |v, h| h[v] = @hackr.stat(v).to_i }

        # Clamp each allocation to actual deficit under lock
        final_allocs = allocs.filter_map do |a|
          vital = a[:vital]
          current = prior_vitals[vital]
          max = @hackr.effective_max(vital)
          deficit = max - current
          next nil if deficit <= 0

          clamped = [a[:points].to_i, deficit].min
          {vital: vital, points: clamped, new_val: current + clamped, max_val: max}
        end

        raise NothingToRestore, "Your vitals are already full." if final_allocs.empty?

        total_points = final_allocs.sum { |a| a[:points] }
        total_cred = (total_points.to_f / rate).ceil

        # Re-fetch balance after lock (TOCTOU guard)
        cache = @hackr.default_cache
        raise InsufficientBalance, "Need #{total_cred} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= total_cred

        # Apply vital restorations (adjust_vital! re-clamps, belt-and-suspenders
        # with the deficit clamp above — both safe because lock prevents changes)
        final_allocs.each do |a|
          @hackr.adjust_vital!(a[:vital], a[:points])
        end
      end

      # CRED payment outside transaction (TransactionService has its own mutex).
      # If payment fails, subtract what we added — preserves any concurrent changes.
      begin
        split_payment!(from_cache: cache, amount: total_cred)
      rescue => e
        final_allocs.each { |a| @hackr.adjust_vital!(a[:vital], -a[:points]) }
        raise InsufficientBalance, "Payment failed — restoration reversed. #{e.message}"
      end

      display = render_result(final_allocs, total_cred, rate)
      Result.new(allocations: final_allocs, total_cred_paid: total_cred, display: display)
    end

    private

    def split_payment!(from_cache:, amount:)
      burn_amt = (amount * EconomyConfig::SHOP_BURN_RATIO).floor
      recycle_amt = amount - burn_amt

      if burn_amt > 0
        Grid::TransactionService.burn!(
          from_cache: from_cache,
          amount: burn_amt,
          memo: "Rest Pod restoration"
        )
      end

      if recycle_amt > 0
        Grid::TransactionService.recycle!(
          from_cache: from_cache,
          amount: recycle_amt,
          memo: "Rest Pod restoration"
        )
      end
    end

    def render_result(allocs, total_cred, rate)
      vital_colors = {"health" => "#34d399", "energy" => "#60a5fa", "psyche" => "#c084fc"}
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>[ REST POD — VITALS RESTORED ]</span>"
      allocs.each do |a|
        color = vital_colors.fetch(a[:vital], "#d0d0d0")
        lines << "<span style='color: #{color};'>  #{a[:vital].upcase}: +#{a[:points]} (#{a[:new_val]}/#{a[:max_val]})</span>"
      end
      rate_label = (rate == RATE_DISCOUNTED) ? "discounted" : "standard"
      lines << "<span style='color: #fbbf24;'>  Cost: #{total_cred} CRED (#{rate_label} rate: #{rate} pts/CRED)</span>"
      lines.join("\n")
    end
  end
end
