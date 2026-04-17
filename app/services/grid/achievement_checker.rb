# frozen_string_literal: true

module Grid
  # Evaluates achievement unlocks for a single hackr. Caller passes a
  # trigger_type (symbol/string) plus context hash; checker queries
  # candidates for that trigger, skips already-earned, delegates the
  # actual award + reward pipeline to AchievementAwarder.
  #
  # Returns an array of inline HTML notification strings — Terminal
  # commands append these to the command output. The AchievementChannel
  # toast broadcast fires from AchievementAwarder (async for the client).
  #
  # Source counts used by `progress` are memoized per-instance — the
  # AchievementsPage endpoint iterates ~40 achievements but many share
  # the same underlying query (e.g. all `hackr_logs_read` tiers read the
  # same `hackr_log_reads.count`). Memoization collapses that to one
  # query per source. Callers should discard the checker after use so
  # counts aren't served stale across requests.
  class AchievementChecker
    def initialize(hackr)
      @hackr = hackr
    end

    def check(trigger_type, context = {})
      return [] unless @hackr

      candidates = GridAchievement.by_trigger(trigger_type.to_s)
      return [] if candidates.none?

      notifications = []

      candidates.each do |achievement|
        next if earned_ids.include?(achievement.id)
        next unless matches?(achievement, context)

        notification = Grid::AchievementAwarder.new(@hackr, achievement).award!
        next unless notification

        # Track the just-awarded id so subsequent check() calls on the
        # same checker instance (login sweep's 18-trigger loop, or the
        # CommandParser firing 3 checks after `take`) don't re-test it.
        # award!() already raises on DB-level duplicate; skipping saves
        # the round-trip.
        earned_ids << achievement.id
        notifications << notification
      end

      notifications
    end

    # Returns {current:, target:, fraction:, completed:} for a cumulative
    # achievement, or nil for event-only triggers (room_visit, take_item,
    # use_item, talk_npc, rarity_owned, salvage_item, manual). Used by
    # the `stat` command, the Handbook achievements page, and the
    # `matches?` dispatch below (cumulative triggers unlock when
    # `progress[:completed]` is true).
    def progress(achievement)
      data = (achievement.trigger_data || {}).with_indifferent_access

      case achievement.trigger_type
      when "rooms_visited"
        derive(@hackr.stat("rooms_visited").to_i, data[:count].to_i)
      when "items_collected"
        derive(items_collected_count, data[:count].to_i)
      when "salvage_count"
        derive(@hackr.stat("salvage_count").to_i, data[:count].to_i)
      when "salvage_yield_count"
        derive(@hackr.stat("salvage_yield_count").to_i, data[:count].to_i)
      when "track_plays_count"
        derive(track_plays_count, data[:count].to_i)
      when "pulse_vault_completed"
        derive(pulse_vault_played_count, pulse_vault_total)
      when "hackr_logs_read"
        derive(hackr_logs_read_count, data[:count].to_i)
      when "hackr_logs_read_all"
        derive(hackr_logs_read_published_count, hackr_logs_published_total)
      when "codex_entries_read"
        derive(codex_entries_read_count, data[:count].to_i)
      when "codex_entries_read_all"
        derive(codex_entries_read_published_count, codex_entries_published_total)
      when "artist_bios_viewed_all"
        derive(bios_viewed_for_bands_count, band_ids.size)
      when "release_indexes_viewed_all"
        derive(release_indexes_viewed_for_bands_count, band_ids.size)
      when "releases_viewed_all"
        derive(releases_viewed_for_released_count, released_release_ids.size)
      when "wire_pulses_count"
        derive(wire_pulses_count, data[:count].to_i)
      when "uplink_packets_count"
        # "Packet" is the in-world, user-facing term for an Uplink
        # message — pure aesthetic naming to preserve the Grid's
        # fourth wall. The underlying model is `ChatMessage`; there
        # is no separate Packet table. Count reads chat_messages.
        derive(uplink_packets_count, data[:count].to_i)
      when "playlists_created"
        derive(populated_playlist_count, data[:count].to_i)
      when "vods_watched"
        derive(vods_watched_count, data[:count].to_i)
      when "radio_stations_tuned"
        derive(radio_stations_tuned_count, data[:count].to_i)
      when "radio_stations_tuned_all"
        derive(radio_stations_tuned_visible_count, radio_stations_visible_total)
      when "clearance_level"
        derive(@hackr.stat("clearance").to_i, data[:level].to_i)
      when "missions_completed_count"
        derive(missions_completed_count, data[:count].to_i)
      end
    end

    private

    # Memoized set of achievement IDs the hackr has already earned.
    # The login sweep job calls check() 18 times on one checker
    # instance — without this memoization each call re-queries the
    # join table. Stays fresh within the instance: check() appends
    # to the set when award!() returns a notification. Refs should
    # not survive past a single request/job (earned set is a snapshot).
    def earned_ids
      @earned_ids ||= @hackr.grid_hackr_achievements.pluck(:grid_achievement_id).to_set
    end

    def derive(current, target)
      return nil if target.to_i <= 0
      current = current.to_i
      clamped = [current, target].min
      {current: current, target: target, fraction: (clamped.to_f / target).round(2), completed: current >= target}
    end

    # --- Memoized source counts -------------------------------------
    # Each method runs its underlying query at most once per checker
    # instance. `defined?` + ||= handles the false/0/nil cases the
    # naive `@x ||= ...` pattern would re-run on. Counts can be 0.

    def items_collected_count
      return @items_collected_count if defined?(@items_collected_count)
      @items_collected_count = @hackr.grid_items.count
    end

    def track_plays_count
      return @track_plays_count if defined?(@track_plays_count)
      @track_plays_count = @hackr.grid_hackr_track_plays.count
    end

    def pulse_vault_total
      return @pulse_vault_total if defined?(@pulse_vault_total)
      @pulse_vault_total = Track.visible_in_pulse_vault.count
    end

    def pulse_vault_played_count
      return @pulse_vault_played_count if defined?(@pulse_vault_played_count)
      @pulse_vault_played_count = @hackr.grid_hackr_track_plays
        .joins(:track).merge(Track.visible_in_pulse_vault).distinct.count
    end

    def hackr_logs_read_count
      return @hackr_logs_read_count if defined?(@hackr_logs_read_count)
      @hackr_logs_read_count = @hackr.hackr_log_reads.count
    end

    def hackr_logs_published_total
      return @hackr_logs_published_total if defined?(@hackr_logs_published_total)
      @hackr_logs_published_total = HackrLog.published.count
    end

    def hackr_logs_read_published_count
      return @hackr_logs_read_published_count if defined?(@hackr_logs_read_published_count)
      @hackr_logs_read_published_count = @hackr.hackr_log_reads
        .joins(:hackr_log).merge(HackrLog.published).count
    end

    def codex_entries_read_count
      return @codex_entries_read_count if defined?(@codex_entries_read_count)
      @codex_entries_read_count = @hackr.codex_entry_reads.count
    end

    def codex_entries_published_total
      return @codex_entries_published_total if defined?(@codex_entries_published_total)
      @codex_entries_published_total = CodexEntry.published.count
    end

    def codex_entries_read_published_count
      return @codex_entries_read_published_count if defined?(@codex_entries_read_published_count)
      @codex_entries_read_published_count = @hackr.codex_entry_reads
        .joins(:codex_entry).merge(CodexEntry.published).count
    end

    def band_ids
      return @band_ids if defined?(@band_ids)
      @band_ids = Artist.bands.pluck(:id)
    end

    def bios_viewed_for_bands_count
      return @bios_viewed_for_bands_count if defined?(@bios_viewed_for_bands_count)
      @bios_viewed_for_bands_count = @hackr.hackr_page_views
        .of_type("bio").where(resource_id: band_ids).count
    end

    def release_indexes_viewed_for_bands_count
      return @release_indexes_viewed_for_bands_count if defined?(@release_indexes_viewed_for_bands_count)
      @release_indexes_viewed_for_bands_count = @hackr.hackr_page_views
        .of_type("release_index").where(resource_id: band_ids).count
    end

    def released_release_ids
      return @released_release_ids if defined?(@released_release_ids)
      @released_release_ids = Release.released.pluck(:id)
    end

    def releases_viewed_for_released_count
      return @releases_viewed_for_released_count if defined?(@releases_viewed_for_released_count)
      @releases_viewed_for_released_count = @hackr.hackr_page_views
        .of_type("release").where(resource_id: released_release_ids).count
    end

    def wire_pulses_count
      return @wire_pulses_count if defined?(@wire_pulses_count)
      @wire_pulses_count = @hackr.pulses.where(parent_pulse_id: nil).count
    end

    # Uplink "packets" are stored as `ChatMessage` rows — "packet" is
    # a pure in-world aesthetic alias, not a separate model. This
    # accessor counts every message the hackr has sent through the
    # Uplink, which is what the `uplink_packets_count` achievement
    # tier ladder advances on.
    def uplink_packets_count
      return @uplink_packets_count if defined?(@uplink_packets_count)
      @uplink_packets_count = @hackr.chat_messages.count
    end

    def populated_playlist_count
      return @populated_playlist_count if defined?(@populated_playlist_count)
      @populated_playlist_count = @hackr.playlists.joins(:playlist_tracks).distinct.count
    end

    def vods_watched_count
      return @vods_watched_count if defined?(@vods_watched_count)
      @vods_watched_count = @hackr.hackr_vod_watches.count
    end

    def radio_stations_tuned_count
      return @radio_stations_tuned_count if defined?(@radio_stations_tuned_count)
      @radio_stations_tuned_count = @hackr.hackr_radio_tunes.count
    end

    def radio_stations_visible_total
      return @radio_stations_visible_total if defined?(@radio_stations_visible_total)
      @radio_stations_visible_total = RadioStation.visible.count
    end

    def radio_stations_tuned_visible_count
      return @radio_stations_tuned_visible_count if defined?(@radio_stations_tuned_visible_count)
      @radio_stations_tuned_visible_count = @hackr.hackr_radio_tunes
        .joins(:radio_station).merge(RadioStation.visible).count
    end

    def missions_completed_count
      return @missions_completed_count if defined?(@missions_completed_count)
      # Turn-ins increment `turn_in_count` on the (possibly repeatable)
      # hackr_mission row. A repeatable mission turned in 3 times should
      # count as 3 completions toward the achievement ladder; a single
      # completed row is at minimum 1 turn-in.
      @missions_completed_count = @hackr.grid_hackr_missions
        .where(status: "completed")
        .sum(:turn_in_count)
    end

    def matches?(achievement, context)
      # Event-only triggers — unlock fires on the specific action, not
      # a cumulative threshold. These are never catch-up swept.
      data = (achievement.trigger_data || {}).with_indifferent_access
      case achievement.trigger_type
      when "room_visit"
        return data[:room_slug].present? && data[:room_slug] == context[:room_slug]
      when "take_item"
        return data[:item_name].blank? || data[:item_name].to_s.downcase == context[:item_name].to_s.downcase
      when "rarity_owned"
        return data[:rarity].present? && @hackr.grid_items.exists?(rarity: data[:rarity])
      when "talk_npc"
        return data[:npc_name].blank? || data[:npc_name].to_s.downcase == context[:npc_name].to_s.downcase
      when "use_item"
        return data[:item_name].blank? || data[:item_name].to_s.downcase == context[:item_name].to_s.downcase
      when "salvage_item"
        return true
      when "salvage_yield_received"
        return true
      when "purchase_item"
        return data[:item_name].blank? || data[:item_name].to_s.downcase == context[:item_name].to_s.downcase
      when "mission_completed"
        # Fires when a specific mission turns in. `mission_slug` in
        # trigger_data pins the achievement to a specific mission;
        # leaving it blank unlocks on ANY mission turn-in (rarely
        # useful — `missions_completed_count` covers the generic case).
        return data[:mission_slug].blank? || data[:mission_slug].to_s == context[:mission_slug].to_s
      when "manual"
        return false
      end

      # Cumulative triggers — delegate to progress so match + progress
      # share a single query. Returns nil for unknown trigger types.
      progress_result = progress(achievement)
      progress_result ? progress_result[:completed] : false
    end
  end
end
