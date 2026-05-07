# frozen_string_literal: true

class Admin::GridSlipstreamRoutesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridSlipstreamRoute, find_by: :slug, children: [:grid_slipstream_legs]

  before_action :set_route, only: %i[show edit update destroy]
  before_action :load_selects, only: %i[new edit create update]

  def index
    @routes = GridSlipstreamRoute.includes(:origin_region, :destination_region).ordered
  end

  def show
    @legs = @route.grid_slipstream_legs.order(:position)
  end

  def new
    @route = GridSlipstreamRoute.new(
      min_clearance: 15,
      base_heat_cost: 10,
      detection_risk_base: 15,
      active: true,
      position: (GridSlipstreamRoute.maximum(:position) || 0) + 1
    )
  end

  def create
    @route = GridSlipstreamRoute.new(route_params)
    if @route.save
      set_flash_success("Slipstream route '#{@route.name}' created.")
      redirect_to edit_admin_grid_slipstream_route_path(@route)
    else
      flash.now[:error] = @route.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @legs = @route.grid_slipstream_legs.order(:position)
  end

  def update
    @route.assign_attributes(route_params)
    unless parse_json_fields!
      flash.now[:error] = @route.errors.full_messages.join(", ")
      @legs = @route.grid_slipstream_legs.order(:position)
      load_selects
      return render :edit, status: :unprocessable_entity
    end

    if @route.save
      set_flash_success("Slipstream route '#{@route.name}' updated.")
      redirect_to edit_admin_grid_slipstream_route_path(@route)
    else
      flash.now[:error] = @route.errors.full_messages.join(", ")
      @legs = @route.grid_slipstream_legs.order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @route.name
    if @route.grid_transit_journeys.exists?
      flash[:error] = "Cannot delete '#{name}' — journeys reference this route."
    else
      @route.destroy!
      set_flash_success("Slipstream route '#{name}' deleted.")
    end
    redirect_to admin_grid_slipstream_routes_path
  end

  private

  def set_route
    @route = GridSlipstreamRoute.find_by!(slug: params[:id])
  end

  def load_selects
    @regions = GridRegion.order(:name)
    @rooms = GridRoom.includes(:grid_zone).order(:name)
    @breach_templates = GridBreachTemplate.published.ordered
  end

  def route_params
    params.require(:grid_slipstream_route).permit(
      :slug, :name, :origin_region_id, :destination_region_id,
      :origin_room_id, :destination_room_id,
      :min_clearance, :base_heat_cost, :detection_risk_base,
      :active, :description, :position
    )
  end

  def parse_json_fields!
    true
  end
end
