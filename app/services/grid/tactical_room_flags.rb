# frozen_string_literal: true

module Grid
  # Room-service availability for the tactical surface (the zone_map
  # API's has_vendor/has_transit/has_npc/has_rest_pod flags). Renders the
  # handle/panel region at page load and again per movement via the
  # command bus.
  class TacticalRoomFlags
    attr_reader :room, :vendor_mob, :npc_mobs

    def initialize(hackr)
      @hackr = hackr
      @room = hackr.current_room
      mobs = @room ? @room.grid_mobs.to_a : []
      @vendor_mob = mobs.find(&:vendor?)
      @npc_mobs = mobs.reject(&:vendor?).select { |m| m.dialogue_tree.present? || m.quest_giver? }
    end

    def vendor?
      @vendor_mob.present?
    end

    def npc?
      @npc_mobs.any?
    end

    def rest_pod?
      @room&.room_type == "rest_pod"
    end

    def transit?
      return false unless @room

      @room.room_type == "transit" ||
        GridSlipstreamRoute.active.where(origin_room_id: @room.id).exists? ||
        @hackr.in_transit?
    end

    def in_breach?
      @hackr.active_breach.present?
    end

    # BREACH encounter launch buttons (zone_map API parity).
    def breach_encounters
      @breach_encounters ||= if @room && !in_breach?
        Grid::BreachService.available_encounters(room: @room, hackr: @hackr)
      else
        []
      end
    end

    def deck
      @deck ||= @hackr.equipped_deck
    end

    def deck_ready?
      deck.present? && !deck.deck_fried?
    end
  end
end
