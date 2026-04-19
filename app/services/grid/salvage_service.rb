# frozen_string_literal: true

module Grid
  class SalvageService
    Result = Data.define(:xp_awarded, :xp_result, :yielded_items, :item_name)

    def self.salvage!(hackr:, item:)
      new(hackr, item).salvage!
    end

    def initialize(hackr, item)
      @hackr = hackr
      @item = item
    end

    def salvage!
      raise ArgumentError, "UNICORN items cannot be salvaged" if @item.rarity == "unicorn"

      item_name = @item.name
      definition = @item.grid_item_definition
      xp_amount = [@item.value, 1].max
      yielded_items = []

      ActiveRecord::Base.transaction do
        if @item.quantity > 1
          @item.update!(quantity: @item.quantity - 1)
        else
          @item.destroy!
        end

        xp_result = @hackr.grant_xp!(xp_amount)

        definition.salvage_yields.ordered.includes(:output_definition).each do |yield_row|
          granted = grant_yield!(yield_row)
          yielded_items << {name: granted.name, quantity: yield_row.quantity}
        end

        Result.new(
          xp_awarded: xp_amount,
          xp_result: xp_result,
          yielded_items: yielded_items,
          item_name: item_name
        )
      end
    end

    private

    def grant_yield!(yield_row)
      Grid::Inventory.grant_item!(
        hackr: @hackr,
        definition: yield_row.output_definition,
        quantity: yield_row.quantity
      )
    end
  end
end
