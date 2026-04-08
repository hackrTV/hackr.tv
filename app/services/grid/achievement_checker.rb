# frozen_string_literal: true

module Grid
  class AchievementChecker
    def initialize(hackr)
      @hackr = hackr
    end

    # Check achievements for a trigger type. Returns array of notification HTML strings.
    def check(trigger_type, context = {})
      candidates = GridAchievement.by_trigger(trigger_type.to_s)
      return [] if candidates.none?

      earned_ids = @hackr.grid_hackr_achievements.pluck(:grid_achievement_id).to_set
      notifications = []

      candidates.each do |achievement|
        next if earned_ids.include?(achievement.id)
        next unless matches?(achievement, context)

        notification = award!(achievement)
        notifications << notification if notification
      end

      notifications
    end

    private

    def matches?(achievement, context)
      data = (achievement.trigger_data || {}).with_indifferent_access

      case achievement.trigger_type
      when "rooms_visited"
        (@hackr.stat("rooms_visited") || 0) >= data[:count].to_i
      when "room_visit"
        data[:room_slug].present? && data[:room_slug] == context[:room_slug]
      when "items_collected"
        @hackr.grid_items.count >= data[:count].to_i
      when "take_item"
        data[:item_name].blank? || data[:item_name].downcase == context[:item_name]&.downcase
      when "rarity_owned"
        data[:rarity].present? && @hackr.grid_items.exists?(rarity: data[:rarity])
      when "talk_npc"
        data[:npc_name].blank? || data[:npc_name].downcase == context[:npc_name]&.downcase
      when "use_item"
        data[:item_name].blank? || data[:item_name].downcase == context[:item_name]&.downcase
      when "salvage_item"
        true
      when "salvage_count"
        (@hackr.stat("salvage_count") || 0) >= data[:count].to_i
      when "manual"
        false
      else
        false
      end
    end

    def award!(achievement)
      GridHackrAchievement.create!(
        grid_hackr: @hackr,
        grid_achievement: achievement,
        awarded_at: Time.current
      )

      # Award XP for achievement
      xp_result = nil
      if achievement.xp_reward > 0
        xp_result = @hackr.grant_xp!(achievement.xp_reward)
      end

      build_notification(achievement, xp_result)
    rescue ActiveRecord::RecordNotUnique
      nil # Already earned — race condition guard
    end

    def build_notification(achievement, xp_result)
      icon = achievement.badge_icon.present? ? "#{achievement.badge_icon} " : ""
      xp_line = (achievement.xp_reward > 0) ? " <span style='color: #34d399;'>+#{achievement.xp_reward} XP</span>" : ""
      level_line = xp_result&.dig(:leveled_up) ? "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{xp_result[:new_clearance]}!</span>" : ""

      "<div style='border: 1px solid #fbbf24; padding: 8px 12px; margin: 4px 0; background: #111;'>" \
        "<span style='color: #fbbf24; font-weight: bold;'>ACHIEVEMENT UNLOCKED:</span> " \
        "#{icon}<span style='color: #22d3ee;'>#{ERB::Util.html_escape(achievement.name)}</span>" \
        "#{xp_line}" \
        "</div>#{level_line}"
    end
  end
end
