# frozen_string_literal: true

module Grid
  # Shared item-granting logic for services that add items to a hackr's
  # inventory. Stacks into an existing item row if the hackr already owns
  # one with the same definition; otherwise creates a new GridItem from
  # the definition's template attributes.
  #
  # Enforces inventory capacity (slot count) and per-definition stack limits.
  # Splits grants across existing stack + new slot when necessary.
  #
  # Usage:
  #   Grid::Inventory.grant_item!(hackr: h, definition: d, quantity: 2)
  module Inventory
    module_function

    # Raises Grid::InventoryErrors::InventoryFull if adding a new slot
    # would exceed the hackr's effective capacity.
    # Acquires an exclusive lock on the hackr row to serialize concurrent grants.
    def check_capacity!(hackr)
      hackr.lock!
      used = GridItem.where(grid_hackr_id: hackr.id, grid_mining_rig_id: nil, container_id: nil, equipped_slot: nil, grid_impound_record_id: nil, deck_id: nil).count
      if used >= hackr.inventory_capacity
        raise Grid::InventoryErrors::InventoryFull,
          "Inventory full (#{used}/#{hackr.inventory_capacity} slots). Drop, sell, or store items to make room."
      end
    end

    def grant_item!(hackr:, definition:, quantity: 1)
      unless ActiveRecord::Base.connection.transaction_open?
        raise "Grid::Inventory.grant_item! must be called inside a transaction"
      end

      existing_stacks = hackr.grid_items
        .where(grid_item_definition_id: definition.id)
        .in_inventory(hackr)
        .lock.order(:id)

      remaining = quantity

      # Fill existing stacks first
      existing_stacks.each do |stack|
        break if remaining <= 0
        space = stack_space(definition, stack.quantity)
        next if space <= 0

        add = [space, remaining].min
        stack.update!(quantity: stack.quantity + add)
        remaining -= add
      end

      return existing_stacks.last if remaining <= 0

      # Remaining needs new slot(s) — create as many as needed
      last_item = nil
      while remaining > 0
        check_capacity!(hackr)
        batch = definition.max_stack ? [remaining, definition.max_stack].min : remaining
        last_item = create_stack!(hackr: hackr, definition: definition, quantity: batch)
        remaining -= batch
      end
      last_item
    end

    # How many more items can fit in the existing stack.
    # Returns Float::INFINITY when max_stack is nil (unlimited).
    def stack_space(definition, current_quantity)
      return Float::INFINITY unless definition.max_stack
      [definition.max_stack - current_quantity, 0].max
    end

    def create_stack!(hackr:, definition:, quantity:)
      GridItem.create!(
        definition.item_attributes.merge(
          grid_hackr: hackr,
          quantity: quantity
        )
      )
    end

    private_class_method :stack_space, :create_stack!
  end
end
