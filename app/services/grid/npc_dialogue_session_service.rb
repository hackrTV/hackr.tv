# frozen_string_literal: true

module Grid
  # Manages the admin NPC Dialogue Tester session lifecycle:
  # snapshot hackr's original room, warp to mob's room, restore on end.
  #
  # Mirrors how BreachService stores sandbox snapshots in breach.meta —
  # here the snapshot lives in hackr.stats["npc_tester_snapshot"] since
  # there is no breach record involved.
  class NpcDialogueSessionService
    SNAPSHOT_KEY = "npc_tester_snapshot"

    class AlreadyInBreach < StandardError; end

    def initialize(hackr)
      @hackr = hackr
    end

    # Snapshot hackr's current room, then warp them to the mob's room.
    # If a stale snapshot exists (crashed/abandoned session), restore first.
    def start!(mob:)
      # Clean up stale session first so the hackr is in a known state
      restore! if active?

      raise AlreadyInBreach, "#{@hackr.hackr_alias} is in an active BREACH." if @hackr.in_breach?

      snapshot = {
        "origin_room_id" => @hackr.current_room_id,
        "origin_zone_entry_room_id" => @hackr.zone_entry_room_id,
        "mob_id" => mob.id,
        "started_at" => Time.current.iso8601
      }

      new_stats = (@hackr.stats || {}).merge(SNAPSHOT_KEY => snapshot)
      @hackr.update!(
        current_room_id: mob.grid_room_id,
        zone_entry_room_id: mob.grid_room_id,
        stats: new_stats
      )
    end

    # Restore hackr to their original room and clear the snapshot.
    def restore!
      snapshot = @hackr.stats&.dig(SNAPSHOT_KEY)
      return unless snapshot

      origin_room_id = snapshot["origin_room_id"]
      origin_zone_entry = snapshot["origin_zone_entry_room_id"]
      new_stats = (@hackr.stats || {}).except(SNAPSHOT_KEY)

      @hackr.update!(
        current_room_id: origin_room_id,
        zone_entry_room_id: origin_zone_entry,
        stats: new_stats
      )
    end

    # Is there an active tester snapshot on this hackr?
    def active?
      @hackr.stats&.dig(SNAPSHOT_KEY).present?
    end
  end
end
