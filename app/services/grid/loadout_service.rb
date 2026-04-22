# frozen_string_literal: true

module Grid
  class LoadoutService
    EquipResult = Data.define(:item, :slot, :swapped_item)
    UnequipResult = Data.define(:item, :slot, :vitals_clamped)

    class NotGear < StandardError; end
    class NoGearSlot < StandardError; end
    class ClearanceBlocked < StandardError; end
    class ZoneRestricted < StandardError; end
    class NotEquipped < StandardError; end

    VITAL_KEYS = %w[health energy psyche inspiration].freeze

    def self.equip!(hackr:, item:)
      new(hackr).equip!(item)
    end

    def self.unequip!(hackr:, item:)
      new(hackr).unequip!(item)
    end

    def self.unequip_by_slot!(hackr:, slot:)
      new(hackr).unequip_by_slot!(slot)
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def equip!(item)
      raise ArgumentError, "Item does not belong to this hackr." unless item.grid_hackr_id == @hackr.id
      raise NotGear, "#{item.name} is not gear." unless item.gear?

      slot = item.gear_slot
      raise NoGearSlot, "#{item.name} has no gear slot defined." if slot.blank?

      cl = @hackr.stat("clearance")
      if item.required_clearance > cl
        raise ClearanceBlocked, "Requires CLEARANCE #{item.required_clearance}. You are CLEARANCE #{cl}."
      end

      swapped_item = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!
        validate_zone!

        existing = @hackr.grid_items.equipped_by(@hackr).find_by(equipped_slot: slot)
        if existing
          existing.update!(equipped_slot: nil)
          swapped_item = existing
        end

        item.update!(equipped_slot: slot)
        @hackr.reset_loadout_cache!
      end

      EquipResult.new(item: item, slot: slot, swapped_item: swapped_item)
    rescue ActiveRecord::RecordNotUnique
      raise ArgumentError, "That slot is already occupied. Try again."
    end

    def unequip!(item)
      raise NotEquipped, "#{item.name} is not equipped." unless item.equipped?

      slot = item.equipped_slot
      vitals_clamped = []

      ActiveRecord::Base.transaction do
        @hackr.lock!
        validate_zone!
        item.update!(equipped_slot: nil)
        @hackr.reset_loadout_cache!
        vitals_clamped = clamp_vitals!
      end

      UnequipResult.new(item: item, slot: slot, vitals_clamped: vitals_clamped)
    end

    def unequip_by_slot!(slot)
      item = @hackr.grid_items.equipped_by(@hackr).find_by(equipped_slot: slot)
      raise NotEquipped, "Nothing equipped in #{slot} slot." unless item
      unequip!(item)
    end

    private

    def validate_zone!
      room = @hackr.current_room
      return unless room
      if room.respond_to?(:room_type) && room.room_type == "danger_zone"
        raise ZoneRestricted, "You can't manage equipment in a danger zone."
      end
    end

    def clamp_vitals!
      clamped = []
      VITAL_KEYS.each do |key|
        cap = @hackr.effective_max(key)
        current = @hackr.stat(key)
        if current > cap
          @hackr.set_stat!(key, cap)
          clamped << {vital: key, old_value: current, new_value: cap}
        end
      end
      clamped
    end
  end
end
