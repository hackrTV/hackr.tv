# frozen_string_literal: true

class Admin::GridHackrItemsController < Admin::ApplicationController
  before_action :set_hackr

  # GET /root/grid_hackrs/:hackr_id/items
  def index
    @inventory = GridItem.in_inventory(@hackr).includes(:grid_item_definition).order(:name)
    @equipped = GridItem.equipped_by(@hackr).includes(:grid_item_definition)
    @definitions = GridItemDefinition.ordered
  end

  # POST /root/grid_hackrs/:hackr_id/items/grant
  def grant
    definition = GridItemDefinition.find_by(id: params[:definition_id])
    unless definition
      set_flash_error("Item definition not found.")
      return redirect_to admin_grid_hackr_items_path(@hackr)
    end

    quantity = [params[:quantity].to_i, 1].max

    ApplicationRecord.transaction do
      Grid::Inventory.grant_item!(hackr: @hackr, definition: definition, quantity: quantity)
    end

    set_flash_success("Granted #{quantity}x #{definition.name} to #{@hackr.hackr_alias}.")
    redirect_to admin_grid_hackr_items_path(@hackr)
  rescue Grid::InventoryErrors::InventoryFull, Grid::InventoryErrors::StackLimitExceeded => e
    set_flash_error("Could not grant item: #{e.message}")
    redirect_to admin_grid_hackr_items_path(@hackr)
  end

  # DELETE /root/grid_hackrs/:hackr_id/items/:id
  def remove
    item = @hackr.grid_items.find_by(id: params[:id])
    unless item
      set_flash_error("Item not found in this hackr's possession.")
      return redirect_to admin_grid_hackr_items_path(@hackr)
    end

    if item.equipped?
      set_flash_error("Cannot remove equipped item '#{item.name}'. Hackr must unequip it first.")
      return redirect_to admin_grid_hackr_items_path(@hackr)
    end

    if item.grid_mining_rig_id.present?
      set_flash_error("Cannot remove installed rig component '#{item.name}' via item admin.")
      return redirect_to admin_grid_hackr_items_path(@hackr)
    end

    name = item.name
    item.destroy!
    set_flash_success("Removed #{name} from #{@hackr.hackr_alias}.")
    redirect_to admin_grid_hackr_items_path(@hackr)
  end

  private

  def set_hackr
    @hackr = GridHackr.find(params[:hackr_id])
  end
end
