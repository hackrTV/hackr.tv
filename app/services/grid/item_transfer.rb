# frozen_string_literal: true

module Grid
  # Atomically moves N units of a GridItem from its current location to a
  # destination. Handles source-row split (decrement or destroy), destination
  # stack merge, overflow into new rows, and capacity pre-checks.
  #
  # Must be called inside an open ActiveRecord transaction.
  #
  # Destination types:
  #   :inventory — hackr's inventory (slot-capped by inventory_capacity)
  #   :room      — a room's floor (capped by DEN_STORAGE_CAP for dens, uncapped otherwise)
  #   :fixture   — a placed fixture (capped by storage_capacity)
  module ItemTransfer
    class InsufficientQuantity < StandardError; end
    class DestinationFull < StandardError; end

    module_function

    # Move `quantity` units of `source_item` to the described destination.
    #
    # source_item:      GridItem row to take units from
    # quantity:         Integer or :all
    # destination_type: :inventory | :room | :fixture
    # destination:      GridHackr (for :inventory), GridRoom (for :room), GridItem (for :fixture)
    #
    # Returns Integer — actual quantity moved.
    def move!(source_item:, quantity:, destination_type:, destination:)
      unless ActiveRecord::Base.connection.transaction_open?
        raise "Grid::ItemTransfer.move! must be called inside a transaction"
      end

      source_item.lock!
      qty = (quantity == :all) ? source_item.quantity : quantity.to_i

      if qty > source_item.quantity
        raise InsufficientQuantity,
          "You only have #{source_item.quantity} (requested #{qty})."
      end

      definition = source_item.grid_item_definition
      max_stack = definition.max_stack

      # --- Pre-flight capacity check (refuse entirely if can't hold full amount) ---
      moving_whole_stack = (qty == source_item.quantity)
      # When moving a whole stack, check if there's an existing destination stack
      # to merge into. If so, go through the full deposit path instead of relocating.
      existing_dest = moving_whole_stack ? find_existing_at_destination(definition, destination_type, destination) : nil
      can_relocate = moving_whole_stack && existing_dest.nil?

      check_destination_capacity!(qty, definition, max_stack, destination_type, destination,
        skip_existing_merge: can_relocate)

      if can_relocate
        # Optimization: relocate the source row directly to avoid destroy+create.
        # This preserves the row ID, which is important for callers that hold a
        # reference and expect to reload the item after the transfer.
        relocate_source!(source_item, destination_type, destination)
      else
        # Partial stack or merge needed: decrement/destroy source, deposit at destination
        remaining_on_source = source_item.quantity - qty
        if remaining_on_source > 0
          source_item.update!(quantity: remaining_on_source)
        else
          source_item.destroy!
        end
        deposit!(qty, definition, max_stack, destination_type, destination)
      end

      qty
    end

    # --- Private helpers ---

    def relocate_source!(source_item, destination_type, destination)
      attrs = case destination_type
      when :inventory
        {grid_hackr: destination, room: nil, container: nil}
      when :room
        {room: destination, grid_hackr: nil, container: nil}
      when :fixture
        {container: destination, grid_hackr: nil, room: nil}
      end
      source_item.update!(attrs)
    end

    def check_destination_capacity!(qty, definition, max_stack, destination_type, destination, skip_existing_merge: false)
      case destination_type
      when :inventory
        hackr = destination
        hackr.lock! # Serialize concurrent inventory modifications
        if skip_existing_merge
          # Whole-stack relocate: 1 row incoming, no merge needed
          current_used = hackr.grid_items.in_inventory(hackr).count
          free_slots = hackr.inventory_capacity - current_used
          if free_slots < 1
            raise Grid::InventoryErrors::InventoryFull,
              "Inventory full (#{current_used}/#{hackr.inventory_capacity} slots). Drop, sell, or store items to make room."
          end
        else
          inv_items = hackr.grid_items.in_inventory(hackr)
          existing = inv_items.where(grid_item_definition_id: definition.id).lock.first
          space_in_existing = existing ? stack_space(max_stack, existing.quantity) : 0
          overflow = [qty - space_in_existing, 0].max
          new_slots_needed = slots_for(overflow, max_stack)
          current_used = inv_items.count
          free_slots = hackr.inventory_capacity - current_used
          if new_slots_needed > free_slots
            raise Grid::InventoryErrors::InventoryFull,
              "Inventory full. Need #{new_slots_needed} slot(s) but only #{free_slots} free."
          end
        end

      when :room
        room = destination
        if room.den?
          room.lock! # Serialize concurrent drops into this den
          if skip_existing_merge
            floor_count = room.den_floor_count
            free = Grid::DenService::DEN_STORAGE_CAP - floor_count
            if free < 1
              raise DestinationFull,
                "Den floor full (#{floor_count}/#{Grid::DenService::DEN_STORAGE_CAP} slots)."
            end
          else
            existing = room.grid_items.on_floor(room)
              .where(grid_item_definition_id: definition.id).lock.first
            space_in_existing = existing ? stack_space(max_stack, existing.quantity) : 0
            overflow = [qty - space_in_existing, 0].max
            new_rows = slots_for(overflow, max_stack)
            floor_count = room.den_floor_count
            free = Grid::DenService::DEN_STORAGE_CAP - floor_count
            if new_rows > free
              raise DestinationFull,
                "Den floor full (#{floor_count}/#{Grid::DenService::DEN_STORAGE_CAP} slots)."
            end
          end
        end
        # Non-den rooms: no cap

      when :fixture
        fixture = destination
        fixture.lock!
        cap = fixture.storage_capacity
        used = fixture.stored_items.count
        if skip_existing_merge
          if used >= cap
            raise DestinationFull,
              "#{fixture.name} is full (#{used}/#{cap} slots)."
          end
        else
          existing = fixture.stored_items
            .where(grid_item_definition_id: definition.id).lock.first
          space_in_existing = existing ? stack_space(max_stack, existing.quantity) : 0
          overflow = [qty - space_in_existing, 0].max
          new_rows = slots_for(overflow, max_stack)
          free = cap - used
          if new_rows > free
            raise DestinationFull,
              "#{fixture.name} is full (#{used}/#{cap} slots)."
          end
        end
      end
    end

    def deposit!(qty, definition, max_stack, destination_type, destination)
      remaining = qty

      # Try to merge into existing stack at destination
      existing = find_existing_at_destination(definition, destination_type, destination)
      if existing
        space = stack_space(max_stack, existing.quantity)
        fill = [space, remaining].min
        if fill > 0
          existing.update!(quantity: existing.quantity + fill)
          remaining -= fill
        end
      end

      # Spill overflow into new rows
      while remaining > 0
        batch = max_stack ? [remaining, max_stack].min : remaining
        create_at_destination!(definition, batch, destination_type, destination)
        remaining -= batch
      end
    end

    def find_existing_at_destination(definition, destination_type, destination)
      scope = case destination_type
      when :inventory
        destination.grid_items.in_inventory(destination)
      when :room
        destination.grid_items.on_floor(destination)
      when :fixture
        destination.stored_items
      end
      scope.where(grid_item_definition_id: definition.id).lock.first
    end

    def create_at_destination!(definition, quantity, destination_type, destination)
      attrs = definition.item_attributes.merge(quantity: quantity)
      case destination_type
      when :inventory
        attrs[:grid_hackr] = destination
      when :room
        attrs[:room] = destination
      when :fixture
        attrs[:container] = destination
      end
      GridItem.create!(attrs)
    end

    # How many units can still fit in the existing stack.
    def stack_space(max_stack, current_quantity)
      return Float::INFINITY unless max_stack
      [max_stack - current_quantity, 0].max
    end

    # How many new rows are needed to hold `overflow` units.
    def slots_for(overflow, max_stack)
      return 0 if overflow <= 0
      max_stack ? (overflow.to_f / max_stack).ceil : 1
    end

    private_class_method :check_destination_capacity!, :relocate_source!,
      :deposit!, :find_existing_at_destination, :create_at_destination!,
      :stack_space, :slots_for
  end
end
