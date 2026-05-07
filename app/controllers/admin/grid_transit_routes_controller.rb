# frozen_string_literal: true

class Admin::GridTransitRoutesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridTransitRoute, find_by: :slug, children: [:grid_transit_stops]

  before_action :set_route, only: %i[show edit update destroy add_stop remove_stop]
  before_action :load_selects, only: %i[new edit create update add_stop]

  def index
    @routes = GridTransitRoute.includes(:grid_transit_type, :grid_region, :grid_transit_stops).ordered
  end

  def show
    @stops = @route.grid_transit_stops.includes(:grid_room).order(:position)
  end

  def new
    @route = GridTransitRoute.new(active: true, position: (GridTransitRoute.maximum(:position) || 0) + 1)
  end

  def create
    @route = GridTransitRoute.new(route_params)
    if @route.save
      set_flash_success("Transit route '#{@route.name}' created.")
      redirect_to edit_admin_grid_transit_route_path(@route)
    else
      flash.now[:error] = @route.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @stops = @route.grid_transit_stops.includes(:grid_room).order(:position)
  end

  def update
    if @route.update(route_params)
      set_flash_success("Transit route '#{@route.name}' updated.")
      redirect_to edit_admin_grid_transit_route_path(@route)
    else
      flash.now[:error] = @route.errors.full_messages.join(", ")
      @stops = @route.grid_transit_stops.includes(:grid_room).order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def add_stop
    next_pos = (@route.grid_transit_stops.maximum(:position) || -1) + 1
    stop = @route.grid_transit_stops.new(stop_params.merge(position: next_pos))
    if stop.save
      set_flash_success("Stop '#{stop.display_name}' added at position #{stop.position}.")
    else
      flash[:error] = stop.errors.full_messages.join(", ")
    end
    redirect_to edit_admin_grid_transit_route_path(@route)
  end

  def remove_stop
    stop = @route.grid_transit_stops.find(params[:stop_id])
    name = stop.display_name
    stop.destroy!
    set_flash_success("Stop '#{name}' removed.")
    redirect_to edit_admin_grid_transit_route_path(@route)
  end

  def destroy
    name = @route.name
    if @route.grid_transit_journeys.exists?
      flash[:error] = "Cannot delete '#{name}' — journeys reference this route."
    else
      @route.destroy!
      set_flash_success("Transit route '#{name}' deleted.")
    end
    redirect_to admin_grid_transit_routes_path
  end

  private

  def set_route
    @route = GridTransitRoute.find_by!(slug: params[:id])
  end

  def load_selects
    @transit_types = GridTransitType.ordered
    @regions = GridRegion.order(:name)
    # For stop management: transit rooms scoped to route's region
    @region_rooms = if @route&.persisted? && @route.grid_region_id
      GridRoom.where(room_type: "transit")
        .joins(:grid_zone).where(grid_zones: {grid_region_id: @route.grid_region_id})
        .includes(:grid_zone).order(:name)
    else
      GridRoom.none
    end
  end

  def route_params
    params.require(:grid_transit_route).permit(
      :slug, :name, :grid_transit_type_id, :grid_region_id,
      :loop_route, :active, :description, :position
    )
  end

  def stop_params
    params.require(:grid_transit_stop).permit(:grid_room_id, :label, :is_terminus)
  end
end
