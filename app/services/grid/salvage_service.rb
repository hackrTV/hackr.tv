# frozen_string_literal: true

module Grid
  class SalvageService
    Result = Data.define(:xp_awarded, :xp_result, :yielded_items, :item_name, :quantity_salvaged)

    def self.salvage!(hackr:, item:, quantity: 1)
      new(hackr, item, quantity).salvage!
    end

    def initialize(hackr, item, quantity)
      @hackr = hackr
      @item = item
      @quantity = quantity
    end

    def salvage!
      raise ArgumentError, "UNICORN items cannot be salvaged" if @item.rarity == "unicorn"

      item_name = @item.name
      definition = @item.grid_item_definition
      xp_per_unit = [@item.value, 1].max
      yielded_items = {}
      qty = nil
      total_xp = nil

      ActiveRecord::Base.transaction do
        @item.lock!
        qty = (@quantity == :all) ? @item.quantity : @quantity.to_i
        if qty > @item.quantity
          raise ArgumentError, "You only have #{@item.quantity} (requested #{qty})."
        end
        total_xp = xp_per_unit * qty
        remaining = @item.quantity - qty
        if remaining > 0
          @item.update!(quantity: remaining)
        else
          @item.destroy!
        end

        xp_result = @hackr.grant_xp!(total_xp)

        definition.salvage_yields.ordered.includes(:output_definition).each do |yield_row|
          total_yield_qty = yield_row.quantity * qty
          granted = grant_yield!(yield_row, total_yield_qty)
          yielded_items[granted.name] = (yielded_items[granted.name] || 0) + total_yield_qty
        end

        Result.new(
          xp_awarded: total_xp,
          xp_result: xp_result,
          yielded_items: yielded_items.map { |name, q| {name: name, quantity: q} },
          item_name: item_name,
          quantity_salvaged: qty
        )
      end
    end

    private

    def grant_yield!(yield_row, total_quantity)
      Grid::Inventory.grant_item!(
        hackr: @hackr,
        definition: yield_row.output_definition,
        quantity: total_quantity
      )
    end
  end
end
