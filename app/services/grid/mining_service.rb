# frozen_string_literal: true

module Grid
  class MiningService
    def self.tick!
      pool = begin
        GridCache.mining_pool
      rescue ActiveRecord::RecordNotFound
        Rails.logger.warn("[MINING] Mining pool cache not found — skipping tick")
        return
      end

      return if pool.balance.zero?

      stream_live = HackrStream.current_live.present?
      live_channel = ChatChannel.find_by(slug: "live") if stream_live
      halving = EconomyConfig.halving_factor

      # Auto-shutoff: deactivate rigs for hackrs inactive > 7 days
      GridMiningRig
        .joins(:grid_hackr)
        .where(active: true)
        .where("grid_hackrs.last_activity_at < ?", EconomyConfig::INACTIVITY_SHUTOFF.ago)
        .update_all(active: false)

      # Collect earnings per hackr: { hackr_id => { amount:, rig: } }
      earnings = {}

      # 1. Active rig mining (rate × 1)
      active_rigs = GridMiningRig
        .where(active: true)
        .includes(:grid_hackr, grid_items: [])
        .joins(:grid_hackr)
        .where("grid_hackrs.last_activity_at >= ?", EconomyConfig::INACTIVITY_SHUTOFF.ago)

      active_rigs.each do |rig|
        rate = (rig.effective_rate * halving).floor
        next if rate.zero?
        earnings[rig.grid_hackr_id] = {amount: rate, rig: rig}
      end

      # 2 & 3. Stream presence bonus + chat bonus (only when stream is live)
      if stream_live && live_channel
        present_hackr_ids = GridUplinkPresence.valid.in_channel(live_channel).pluck(:grid_hackr_id)

        if present_hackr_ids.any?
          rigs_for_present = GridMiningRig
            .includes(:grid_hackr, grid_items: [])
            .where(grid_hackr_id: present_hackr_ids)

          rigs_for_present.each do |rig|
            # Presence bonus: rate × 2 (based on rig rate, regardless of active status)
            rate = (rig.effective_rate * halving * 2).floor
            next if rate.zero?
            earnings[rig.grid_hackr_id] ||= {amount: 0, rig: rig}
            earnings[rig.grid_hackr_id][:amount] += rate
          end

          # Chat activity bonus: flat bonus for hackrs who chatted in #live this tick
          chatted_hackr_ids = ChatMessage
            .where(chat_channel: live_channel)
            .where("created_at > ?", EconomyConfig::TICK_INTERVAL.ago)
            .distinct.pluck(:grid_hackr_id)

          rigs_by_hackr = rigs_for_present.index_by(&:grid_hackr_id)
          (chatted_hackr_ids & present_hackr_ids).each do |hackr_id|
            chat_bonus = [EconomyConfig::CHAT_BONUS * halving, 1].max.floor
            earnings[hackr_id] ||= {amount: 0, rig: rigs_by_hackr[hackr_id]}
            earnings[hackr_id][:amount] += chat_bonus
          end
        end
      end

      # Mint all earnings from mining pool
      remaining = pool.balance
      earnings.each do |hackr_id, data|
        amount = data[:amount]
        next if amount.zero?

        # Don't exceed remaining pool
        amount = [amount, remaining].min
        break if amount.zero?

        hackr = GridHackr.find_by(id: hackr_id)
        next unless hackr

        cache = hackr.default_cache
        next unless cache&.active?

        begin
          TransactionService.mint_mining!(to_cache: cache, amount: amount)
          remaining -= amount
          data[:rig]&.update_column(:last_tick_at, Time.current)
        rescue TransactionService::InsufficientBalance
          break # Pool exhausted
        end
      end

      # Cleanup stale presences
      GridUplinkPresence.cleanup_stale!

      log_anti_abuse_flags
    end

    # Log IPs with multiple mining accounts for admin visibility
    def self.log_anti_abuse_flags
      flagged = GridHackr
        .joins(:grid_mining_rig)
        .where(grid_mining_rigs: {active: true})
        .where.not(registration_ip: nil)
        .group(:registration_ip)
        .having("COUNT(*) > 1")
        .count

      flagged.each do |ip, count|
        Rails.logger.warn("[MINING] Anti-abuse flag: IP #{ip} has #{count} active mining rigs")
      end
    end
  end
end
