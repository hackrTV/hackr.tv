# frozen_string_literal: true

module Grid
  class FabricationService
    Result = Data.define(:xp_awarded, :xp_result, :output_item_name, :output_quantity, :schematic_name)

    class IngredientsInsufficient < StandardError; end

    def self.fabricate!(hackr:, schematic:)
      new(hackr, schematic).fabricate!
    end

    def initialize(hackr, schematic)
      @hackr = hackr
      @schematic = schematic
    end

    def fabricate!
      ingredients = @schematic.ingredients.ordered.includes(:input_definition)

      ActiveRecord::Base.transaction do
        # Pre-flight check inside the transaction: lock ingredient rows
        # to prevent a concurrent fabrication from passing the check and
        # then racing on consumption.
        ingredients.each do |ing|
          owned = @hackr.grid_items
            .where(grid_item_definition_id: ing.input_definition_id)
            .lock.sum(:quantity)
          if owned < ing.quantity
            raise IngredientsInsufficient,
              "Missing: #{ing.input_definition.name} (need #{ing.quantity}, have #{owned})"
          end
        end

        # Consume ingredients
        ingredients.each { |ing| consume_ingredient!(ing) }

        # Grant output item (stacking via shared module)
        output_def = @schematic.output_definition
        Grid::Inventory.grant_item!(
          hackr: @hackr,
          definition: output_def,
          quantity: @schematic.output_quantity
        )

        # Grant XP
        xp_result = if @schematic.xp_reward.positive?
          @hackr.grant_xp!(@schematic.xp_reward)
        else
          {leveled_up: false}
        end

        # Increment stat inside the transaction so it rolls back with
        # everything else if a later step fails.
        current = @hackr.stat("fabricate_count") || 0
        @hackr.set_stat!("fabricate_count", current + 1)

        Result.new(
          xp_awarded: @schematic.xp_reward,
          xp_result: xp_result,
          output_item_name: output_def.name,
          output_quantity: @schematic.output_quantity,
          schematic_name: @schematic.name
        )
      end
    end

    private

    # Consume the required quantity from hackr's inventory stacks.
    # Handles fragmented stacks (multiple rows for the same definition)
    # by consuming in ID order until the required quantity is met.
    def consume_ingredient!(ingredient)
      remaining = ingredient.quantity
      @hackr.grid_items
        .where(grid_item_definition_id: ingredient.input_definition_id)
        .order(:id).lock
        .each do |stack|
          break if remaining <= 0
          if stack.quantity <= remaining
            remaining -= stack.quantity
            stack.destroy!
          else
            stack.update!(quantity: stack.quantity - remaining)
            remaining = 0
          end
        end
    end
  end
end
