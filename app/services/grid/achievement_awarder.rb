# frozen_string_literal: true

module Grid
  # Applies rewards (join-row insert, XP grant, CRED mint) and pushes the
  # unlock toast to the hackr's AchievementChannel stream. Returns the
  # inline HTML notification string for Terminal commands, or nil when the
  # achievement is already earned (race-guard).
  #
  # Used by:
  #   - Grid::AchievementChecker#check (automatic unlocks)
  #   - Admin::GridAchievementsController#award (manual admin grant)
  class AchievementAwarder
    def initialize(hackr, achievement)
      @hackr = hackr
      @achievement = achievement
    end

    def award!
      xp_result = nil
      minted_cred = false

      ActiveRecord::Base.transaction do
        GridHackrAchievement.create!(
          grid_hackr: @hackr,
          grid_achievement: @achievement,
          awarded_at: Time.current
        )

        xp_result = @hackr.grant_xp!(@achievement.xp_reward) if @achievement.xp_reward.to_i.positive?

        if @achievement.cred_reward.to_i.positive?
          cache = @hackr.default_cache
          if cache&.active?
            Grid::TransactionService.mint_gameplay!(
              to_cache: cache,
              amount: @achievement.cred_reward,
              memo: "Achievement: #{@achievement.name}"
            )
            minted_cred = true
          else
            Rails.logger.warn(
              "[AchievementAwarder] skipped CRED mint for hackr=#{@hackr.id} " \
              "achievement=#{@achievement.slug}: no active default cache"
            )
          end
        end
      end

      broadcast_toast(xp_result, minted_cred)
      build_notification(xp_result, minted_cred)
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid => e
      # RecordInvalid: the uniqueness validator on GridHackrAchievement
      # caught the duplicate at the AR layer. RecordNotUnique: the DB
      # unique index caught it (true race — two transactions committing
      # simultaneously). Both mean "already awarded" — return nil so the
      # checker skips this candidate without surfacing an error.
      raise unless e.is_a?(ActiveRecord::RecordNotUnique) ||
        e.record.is_a?(GridHackrAchievement)
      nil
    end

    private

    def broadcast_toast(xp_result, minted_cred)
      ActionCable.server.broadcast(
        AchievementChannel.stream_name_for(@hackr),
        {
          type: "achievement_unlocked",
          achievement: {
            slug: @achievement.slug,
            name: @achievement.name,
            description: @achievement.description,
            badge_icon: @achievement.badge_icon,
            category: @achievement.category,
            xp_reward: @achievement.xp_reward,
            cred_reward: minted_cred ? @achievement.cred_reward : 0
          },
          leveled_up: xp_result&.dig(:leveled_up) || false,
          new_clearance: xp_result&.dig(:new_clearance)
        }
      )
    rescue => e
      Rails.logger.error("[AchievementAwarder] broadcast failed: #{e.message}")
    end

    def build_notification(xp_result, minted_cred)
      icon = @achievement.badge_icon.present? ? "#{@achievement.badge_icon} " : ""
      xp_line = @achievement.xp_reward.to_i.positive? ? " <span style='color: #34d399;'>+#{@achievement.xp_reward} XP</span>" : ""
      cred_line = minted_cred ? " <span style='color: #fbbf24;'>+#{@achievement.cred_reward} CRED</span>" : ""
      level_line = xp_result&.dig(:leveled_up) ? "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{xp_result[:new_clearance]}!</span>" : ""

      "<div style='border: 1px solid #fbbf24; padding: 8px 12px; margin: 4px 0; background: #111;'>" \
        "<span style='color: #fbbf24; font-weight: bold;'>ACHIEVEMENT UNLOCKED:</span> " \
        "#{icon}<span style='color: #22d3ee;'>#{ERB::Util.html_escape(@achievement.name)}</span>" \
        "#{xp_line}#{cred_line}" \
        "</div>#{level_line}"
    end
  end
end
