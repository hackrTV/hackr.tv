class Admin::GridRegionsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridRegion

  before_action :set_region, only: %i[edit update destroy]
  before_action :load_selects, only: %i[edit update]

  def index
    @regions = GridRegion.includes(:grid_zones).order(:name)
  end

  def new
    @region = GridRegion.new
    load_selects
  end

  def create
    @region = GridRegion.new(region_params)
    if @region.save
      set_flash_success("Region '#{@region.name}' created.")
      redirect_to admin_grid_regions_path
    else
      load_selects
      flash.now[:error] = @region.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @region.update(region_params)
      set_flash_success("Region '#{@region.name}' updated.")
      redirect_to admin_grid_regions_path
    else
      flash.now[:error] = @region.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @region.name
    if @region.grid_zones.any?
      set_flash_error("Can't delete '#{name}' — zones still reference it.")
    else
      @region.destroy
      set_flash_success("Region '#{name}' deleted.")
    end
    redirect_to admin_grid_regions_path
  end

  private

  def set_region
    @region = GridRegion.find(params[:id])
  end

  def load_selects
    @rooms = if @region&.persisted?
      @region.grid_rooms.includes(grid_zone: :grid_region).joins(:grid_zone).order("grid_zones.name, grid_rooms.name")
    else
      GridRoom.none
    end
  end

  def region_params
    params.require(:grid_region).permit(:name, :slug, :description,
      :hospital_room_id, :containment_room_id, :cell_block_room_id, :sally_port_room_id,
      :facility_exit_room_id, :facility_bribe_exit_room_id)
  end
end
