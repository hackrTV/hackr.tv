# frozen_string_literal: true

module Grid
  # Transactional reward pipeline for mission turn-in. Mirrors the shape of
  # Grid::AchievementAwarder (one transaction wraps the state change + all
  # reward writes; broadcasts and inline notifications built after commit).
  #
  # Called by Grid::MissionService#turn_in! — not by any other path.
  class MissionRewardGranter
    def initialize(hackr, hackr_mission)
      @hackr = hackr
      @hackr_mission = hackr_mission
      @mission = hackr_mission.grid_mission
    end

    def grant!
      outcome = {
        xp_granted: 0, cred_granted: 0, minted_cred: false,
        leveled_up: false, new_clearance: nil,
        rep_awards: [], items_granted: [], achievements_granted: [],
        # Threshold-tick notifications from OTHER active missions whose
        # reach_clearance / reach_rep objectives advanced because of
        # this turn-in's rewards. Surfaced inline to the player so the
        # cross-mission cascade is visible immediately rather than
        # waiting for an unrelated future event to re-fire the hook.
        progressor_notifs: []
      }

      ActiveRecord::Base.transaction do
        # Lock the row before re-checking status so two concurrent
        # turn_in commands can't both pass the active-check and pay
        # out twice. Second-in-line sees `completed` and aborts.
        @hackr_mission.lock!
        raise Grid::MissionService::NotActive, "Mission is no longer active." unless @hackr_mission.active?

        @hackr_mission.update!(
          status: "completed",
          completed_at: Time.current,
          turn_in_count: @hackr_mission.turn_in_count.to_i + 1
        )

        @mission.grid_mission_rewards.each do |reward|
          apply_reward(reward, outcome)
        end
      end

      # Post-commit: broadcast + fire missions_completed_count achievement
      # sweep. These run outside the transaction so a broadcast failure
      # or achievement check error can't roll back the mission completion.
      broadcast_completion(outcome)
      outcome[:achievement_notifs] = fire_post_commit_achievement_checks
      outcome[:notification_html] = build_notification(outcome)
      outcome
    end

    private

    def apply_reward(reward, outcome)
      case reward.reward_type
      when "xp"
        amount = reward.amount.to_i
        return if amount <= 0
        result = @hackr.grant_xp!(amount)
        outcome[:xp_granted] += amount
        if result[:leveled_up]
          outcome[:leveled_up] = true
          outcome[:new_clearance] = result[:new_clearance]
          # The clearance change might satisfy reach_clearance objectives
          # on OTHER active missions. The just-completed mission is
          # already flipped to "completed" and is filtered out by the
          # progressor's active-scope, so firing here is safe.
          outcome[:progressor_notifs].concat(
            mission_progressor.record(:reach_clearance, clearance: result[:new_clearance])
          )
        end
      when "cred"
        amount = reward.amount.to_i
        return if amount <= 0
        cache = @hackr.default_cache
        if cache&.active?
          Grid::TransactionService.mint_gameplay!(
            to_cache: cache, amount: amount,
            memo: "Mission: #{@mission.name}"
          )
          outcome[:cred_granted] += amount
          outcome[:minted_cred] = true
        else
          Rails.logger.warn(
            "[MissionRewardGranter] skipped CRED mint for hackr=#{@hackr.id} " \
            "mission=#{@mission.slug}: no active default cache"
          )
        end
      when "faction_rep"
        faction = GridFaction.find_by(slug: reward.target_slug)
        return unless faction
        amount = reward.amount.to_i
        return if amount.zero?
        begin
          result = reputation_service.adjust!(
            faction, amount,
            reason: "mission:#{@mission.slug}",
            source: @mission.giver_mob
          )
          outcome[:rep_awards] << {faction: faction, applied_delta: result[:applied_delta], tier_after: result[:tier_after]}

          # Rep change might satisfy a reach_rep objective on another
          # active mission. Use the post-adjust value from the result
          # hash — no extra `effective_rep` read needed (the leaf
          # value IS the effective value for leaf factions, which is
          # what `adjust!` writes to).
          outcome[:progressor_notifs].concat(
            mission_progressor.record(
              :reach_rep,
              faction_slug: faction.slug,
              rep_value: result[:new_value]
            )
          )
          # Aggregate factions this leaf contributes to may have also
          # crossed a threshold — fire for each rolled-up aggregate.
          result[:rollups].each do |rollup|
            next if rollup[:faction].nil?
            outcome[:progressor_notifs].concat(
              mission_progressor.record(
                :reach_rep,
                faction_slug: rollup[:faction].slug,
                rep_value: rollup[:new_value]
              )
            )
          end
        rescue Grid::ReputationService::SubjectMissing,
          Grid::ReputationService::AggregateSubjectNotAdjustable => e
          Rails.logger.warn("[MissionRewardGranter] rep grant skipped: #{e.message}")
        end
      when "item_grant"
        item = build_item_grant(reward)
        outcome[:items_granted] << item if item
      when "grant_achievement"
        ach = GridAchievement.find_by(slug: reward.target_slug)
        return unless ach
        # Route through the awarder so XP/CRED/broadcast/join-row semantics
        # match every other achievement path. Duplicate grant returns nil
        # (idempotent) — don't add to outcome if nothing happened.
        notif = Grid::AchievementAwarder.new(@hackr, ach).award!
        outcome[:achievements_granted] << {achievement: ach, notification: notif} if notif
      end
    end

    # Materialize a new GridItem in the hackr's inventory from a
    # GridItemDefinition looked up by reward.target_slug. The definition
    # supplies name/description/type/rarity/properties; reward.amount and
    # reward.quantity override value and stack size.
    def build_item_grant(reward)
      definition = GridItemDefinition.find_by(slug: reward.target_slug)
      unless definition
        Rails.logger.warn("[MissionRewardGranter] item_grant skipped: no definition for slug='#{reward.target_slug}'")
        return nil
      end

      GridItem.create!(
        definition.item_attributes.merge(
          grid_hackr: @hackr,
          value: [reward.amount.to_i, 0].max,
          quantity: reward.quantity.to_i.clamp(1, 9999)
        )
      )
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("[MissionRewardGranter] item grant failed: #{e.message}")
      nil
    end

    def broadcast_completion(outcome)
      ActionCable.server.broadcast(
        AchievementChannel.stream_name_for(@hackr),
        {
          type: "mission_completed",
          mission: {
            slug: @mission.slug,
            name: @mission.name,
            arc_name: @mission.grid_mission_arc&.name
          },
          rewards: {
            xp: outcome[:xp_granted],
            cred: outcome[:minted_cred] ? outcome[:cred_granted] : 0,
            rep: outcome[:rep_awards].map { |r| {faction: r[:faction].display_name, delta: r[:applied_delta]} },
            items: outcome[:items_granted].map { |i| {name: i.name} },
            achievements: outcome[:achievements_granted].map { |a| {slug: a[:achievement].slug, name: a[:achievement].name} }
          },
          leveled_up: outcome[:leveled_up],
          new_clearance: outcome[:new_clearance]
        }
      )
    rescue => e
      Rails.logger.error("[MissionRewardGranter] broadcast failed: #{e.message}")
    end

    # Fire missions_completed_count + mission_completed achievement triggers
    # now that the hackr_mission row is `completed`. Returns notification
    # HTML strings to append to the terminal output.
    def fire_post_commit_achievement_checks
      checker = Grid::AchievementChecker.new(@hackr)
      notifs = []
      notifs += checker.check(:mission_completed, mission_slug: @mission.slug)
      notifs += checker.check(:missions_completed_count)
      notifs
    rescue => e
      Rails.logger.error("[MissionRewardGranter] achievement check failed: #{e.message}")
      []
    end

    def reputation_service
      @reputation_service ||= Grid::ReputationService.new(@hackr)
    end

    def mission_progressor
      @mission_progressor ||= Grid::MissionProgressor.new(@hackr)
    end

    # Build the inline turn-in notification block — appended to the
    # turn_in command's output. Achievement notifications fired during
    # post-commit checks are appended by the caller.
    def build_notification(outcome)
      lines = []
      lines << "<div style='border: 1px solid #fbbf24; padding: 8px 12px; margin: 4px 0; background: #111;'>"
      lines << "  <span style='color: #fbbf24; font-weight: bold;'>▲ MISSION COMPLETE:</span> " \
        "<span style='color: #22d3ee;'>#{ERB::Util.html_escape(@mission.name)}</span>"

      reward_lines = []
      reward_lines << "<span style='color: #34d399;'>+#{outcome[:xp_granted]} XP</span>" if outcome[:xp_granted].positive?
      reward_lines << "<span style='color: #fbbf24;'>+#{outcome[:cred_granted]} CRED</span>" if outcome[:minted_cred]

      outcome[:rep_awards].each do |r|
        sign = (r[:applied_delta].to_i >= 0) ? "+" : ""
        color = (r[:applied_delta].to_i >= 0) ? "#34d399" : "#ef4444"
        reward_lines << "<span style='color: #{color};'>#{sign}#{r[:applied_delta]} rep</span> " \
          "<span style='color: #9ca3af;'>::</span> " \
          "<span style='color: #a78bfa;'>#{ERB::Util.html_escape(r[:faction].display_name)}</span>"
      end
      outcome[:items_granted].each do |item|
        color = item.rarity_color
        reward_lines << "<span style='color: #{color};'>+ #{ERB::Util.html_escape(item.name)}</span>"
      end

      if reward_lines.any?
        lines << "  <span style='color: #6b7280;'>Rewards:</span> #{reward_lines.join(" <span style='color: #4b5563;'>|</span> ")}"
      end

      if outcome[:leveled_up]
        lines << "  <span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{outcome[:new_clearance]}!</span>"
      end

      outcome[:achievements_granted].each do |a|
        lines << "  <span style='color: #fbbf24;'>◆ Achievement unlocked: #{ERB::Util.html_escape(a[:achievement].name)}</span>"
      end

      lines << "</div>"
      lines.join("\n")
    end
  end
end
