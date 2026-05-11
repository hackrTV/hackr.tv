# frozen_string_literal: true

module Grid
  class TutorialService
    TUTORIAL_HUB_ZONE_SLUG = "bootloader-training-core"
    TUTORIAL_HUB_ROOM_TYPE = "hub"

    class AlreadyInTutorial < StandardError; end
    class NotInTutorial < StandardError; end
    class CannotEnterTutorial < StandardError; end

    def initialize(hackr)
      @hackr = hackr
    end

    # Start tutorial for a brand-new hackr (called during registration).
    def start!
      @hackr.set_stat!("tutorial_active", true)
      @hackr.set_stat!("tutorial_step", 0)
      grant_grid_access!
    end

    # Re-enter tutorial from the live world.
    # Guards: not in BREACH, not captured, not in transit, not already in tutorial.
    def re_enter!
      raise AlreadyInTutorial, "You are already in the tutorial." if active?
      raise CannotEnterTutorial, "Cannot enter tutorial during a BREACH." if @hackr.in_breach?
      raise CannotEnterTutorial, "Cannot enter tutorial while captured." if Grid::ContainmentService.captured?(@hackr)
      raise CannotEnterTutorial, "Cannot enter tutorial while in transit." if @hackr.in_transit?

      hub = tutorial_hub_room
      raise CannotEnterTutorial, "Tutorial zone not available." unless hub

      # Persist return room so we can send them back
      @hackr.set_stat!("tutorial_return_room_id", @hackr.current_room_id)
      @hackr.set_stat!("tutorial_active", true)
      @hackr.set_stat!("tutorial_step", 0)
      @hackr.set_stat!("tutorial_boot_shown", false)
      @hackr.set_stat!("tutorial_granted_steps", [])
      @hackr.update!(current_room: hub)
    end

    # Complete tutorial — hackr chooses a starting room.
    def complete!(starting_room:)
      raise NotInTutorial, "Not in tutorial." unless active?

      strip_tutorial_items!

      @hackr.set_stat!("tutorial_active", false)
      @hackr.set_stat!("tutorial_completed", true)
      @hackr.set_stat!("tutorial_step", nil)
      @hackr.update!(current_room: starting_room)

      # Grant pulse_grid feature if not already granted
      grant_grid_access!

      # Grant den chip (deferred from provision_economy! — DenService needs real zones)
      @hackr.provision_den_chip!

      # Clear return room (not needed after completion)
      @hackr.set_stat!("tutorial_return_room_id", nil)
    end

    # Skip tutorial via code command.
    def skip!(starting_room:)
      complete!(starting_room: starting_room)
    end

    # Return to the room they came from (for re-entry).
    def return_to_world!
      raise NotInTutorial, "Not in tutorial." unless active?

      strip_tutorial_items!

      return_room_id = @hackr.stat("tutorial_return_room_id")
      return_room = return_room_id ? GridRoom.find_by(id: return_room_id) : nil

      # Fall back to a starting room if return room is gone
      return_room ||= GridStartingRoom.ordered.first&.grid_room

      @hackr.set_stat!("tutorial_active", false)
      @hackr.set_stat!("tutorial_step", nil)
      @hackr.set_stat!("tutorial_return_room_id", nil)
      @hackr.set_stat!("tutorial_choosing_start", nil)
      @hackr.update!(current_room: return_room) if return_room
    end

    def active?
      @hackr.stat("tutorial_active") == true
    end

    def completed?
      @hackr.stat("tutorial_completed") == true
    end

    def first_time?
      !completed?
    end

    def tutorial_hub_room
      GridRoom.joins(:grid_zone)
        .where(grid_zones: {slug: TUTORIAL_HUB_ZONE_SLUG})
        .where(room_type: TUTORIAL_HUB_ROOM_TYPE)
        .first
    end

    private

    # Remove all training items from hackr's inventory, equipped slots, and loaded software.
    # Training items are identified by definition slug prefix "training-".
    def strip_tutorial_items!
      training_def_ids = GridItemDefinition.where("slug LIKE ?", "training-%").pluck(:id)
      return if training_def_ids.empty?

      # Find training DECKs to also remove software loaded onto them
      training_decks = @hackr.grid_items.where(grid_item_definition_id: training_def_ids, item_type: "gear")
      training_deck_ids = training_decks.pluck(:id)

      # Destroy software loaded on training DECKs (any definition, not just training-)
      GridItem.where(deck_id: training_deck_ids).destroy_all if training_deck_ids.any?

      # Destroy all training items (inventory, equipped, loaded on deck, etc.)
      @hackr.grid_items.where(grid_item_definition_id: training_def_ids).destroy_all
    end

    def grant_grid_access!
      return if @hackr.admin?
      return if @hackr.feature_grants.exists?(feature: FeatureGrant::PULSE_GRID)

      @hackr.feature_grants.create!(feature: FeatureGrant::PULSE_GRID)
    end
  end
end
