# frozen_string_literal: true

module Grid
  # Manages the admin PAC Escape Tester session lifecycle:
  # snapshot hackr state, force-capture into PAC, optional gear impound,
  # full restore on end (room, captured state, remaining impound records).
  #
  # Follows NpcDialogueSessionService pattern — snapshot in hackr.stats,
  # no separate DB record for the tester session itself.
  class PacEscapeTesterService
    SNAPSHOT_KEY = "pac_tester_snapshot"

    class AlreadyInBreach < StandardError; end
    class AlreadyCaptured < StandardError; end
    class NoContainmentRoom < StandardError; end

    def initialize(hackr)
      @hackr = hackr
    end

    # Force-capture hackr into PAC containment cell.
    # Optionally impounds all equipped gear.
    def start!(impound: false)
      # Clean up stale session first (crashed/abandoned)
      restore! if active?

      raise AlreadyInBreach, "#{@hackr.hackr_alias} is in an active BREACH." if @hackr.in_breach?
      raise AlreadyCaptured, "#{@hackr.hackr_alias} is already captured." if ContainmentService.captured?(@hackr)

      # Pre-check: region must have a containment facility
      region = @hackr.current_room&.grid_zone&.grid_region
      unless region&.containment_room
        raise NoContainmentRoom, "No PAC facility in #{region&.name || "current region"}. Warp hackr to a region with a facility first."
      end

      # Snapshot current state before capture
      snapshot = {
        "origin_room_id" => @hackr.current_room_id,
        "origin_zone_entry_room_id" => @hackr.zone_entry_room_id,
        "started_at" => Time.current.iso8601
      }

      new_stats = (@hackr.stats || {}).merge(SNAPSHOT_KEY => snapshot)
      @hackr.update!(stats: new_stats)

      # Capture via real ContainmentService (sets captured state, moves to containment cell)
      capture_result = ContainmentService.capture!(hackr: @hackr, breach: nil, impound: false)

      # Optional gear impound (separate from capture).
      # Rescue all errors — impound failure should not abort the session.
      impound_result = nil
      if impound
        begin
          impound_result = ImpoundService.impound_gear!(hackr: @hackr, breach: nil)
        rescue ImpoundService::NoEquippedGear
          # Nothing to impound — no gear equipped
        rescue => e
          Rails.logger.error("[PacEscapeTesterService] impound_gear! failed: #{e.message} — hackr #{@hackr.id} captured without impound")
        end
      end

      {capture_result: capture_result, impound_result: impound_result}
    end

    # Restore hackr to pre-capture state:
    # 1. Jackout active breach if any
    # 2. Free-release remaining impound records
    # 3. Clear captured state
    # 4. Restore original room
    # 5. Clear snapshot
    def restore!
      snapshot = @hackr.stats&.dig(SNAPSHOT_KEY)
      return unless snapshot

      # Jackout active breach first (containment cell, sally port, etc.)
      if @hackr.in_breach?
        begin
          BreachService.jackout!(hackr: @hackr)
        rescue => e
          Rails.logger.error("[PacEscapeTesterService] jackout failed: #{e.message}")
        ensure
          @hackr.reload
        end
      end

      # Free-release any remaining impound records (no payment required)
      @hackr.grid_impound_records.impounded.each do |record|
        ActiveRecord::Base.transaction do
          record.lock!
          next unless record.impounded?
          record.impounded_items.update_all(grid_impound_record_id: nil)
          record.update!(status: "recovered")
        end
      end

      # Restore room and clear captured state + snapshot in one write
      origin_room_id = snapshot["origin_room_id"]
      origin_zone_entry = snapshot["origin_zone_entry_room_id"]

      new_stats = (@hackr.stats || {}).except(SNAPSHOT_KEY)
      new_stats.delete("captured")
      new_stats.delete("captured_origin_room_id")
      new_stats.delete("facility_alert_level")

      @hackr.update!(
        current_room_id: origin_room_id,
        zone_entry_room_id: origin_zone_entry,
        stats: new_stats
      )

      @hackr.reset_loadout_cache!
    end

    # Is there an active tester snapshot on this hackr?
    def active?
      @hackr.stats&.dig(SNAPSHOT_KEY).present?
    end
  end
end
