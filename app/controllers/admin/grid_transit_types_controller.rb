# frozen_string_literal: true

class Admin::GridTransitTypesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridTransitType, find_by: :slug

  before_action :set_transit_type, only: %i[edit update destroy]

  def index
    @transit_types = GridTransitType.ordered
  end

  def new
    @transit_type = GridTransitType.new(
      category: "public",
      base_fare: 0,
      min_clearance: 0,
      published: false,
      position: (GridTransitType.maximum(:position) || 0) + 1
    )
  end

  def create
    @transit_type = GridTransitType.new(transit_type_params)
    if @transit_type.save
      set_flash_success("Transit type '#{@transit_type.name}' created.")
      redirect_to edit_admin_grid_transit_type_path(@transit_type)
    else
      flash.now[:error] = @transit_type.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @transit_type.update(transit_type_params)
      set_flash_success("Transit type '#{@transit_type.name}' updated.")
      redirect_to edit_admin_grid_transit_type_path(@transit_type)
    else
      flash.now[:error] = @transit_type.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @transit_type.name
    if @transit_type.grid_transit_routes.exists?
      flash[:error] = "Cannot delete '#{name}' — transit routes reference this type."
    else
      @transit_type.destroy!
      set_flash_success("Transit type '#{name}' deleted.")
    end
    redirect_to admin_grid_transit_types_path
  end

  private

  def set_transit_type
    @transit_type = GridTransitType.find_by!(slug: params[:id])
  end

  def transit_type_params
    params.require(:grid_transit_type).permit(
      :slug, :name, :category, :description, :icon_key,
      :base_fare, :min_clearance, :published, :position
    )
  end
end
