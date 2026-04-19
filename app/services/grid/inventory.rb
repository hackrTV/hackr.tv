# frozen_string_literal: true

module Grid
  # Shared item-granting logic for services that add items to a hackr's
  # inventory. Stacks into an existing item row if the hackr already owns
  # one with the same definition; otherwise creates a new GridItem from
  # the definition's template attributes.
  #
  # Usage:
  #   Grid::Inventory.grant_item!(hackr: h, definition: d, quantity: 2)
  module Inventory
    module_function

    def grant_item!(hackr:, definition:, quantity: 1)
      unless ActiveRecord::Base.connection.transaction_open?
        raise "Grid::Inventory.grant_item! must be called inside a transaction"
      end

      existing = hackr.grid_items
        .where(grid_item_definition_id: definition.id)
        .lock.first

      if existing
        existing.update!(quantity: existing.quantity + quantity)
        existing
      else
        GridItem.create!(
          definition.item_attributes.merge(
            grid_hackr: hackr,
            quantity: quantity
          )
        )
      end
    end
  end
end
