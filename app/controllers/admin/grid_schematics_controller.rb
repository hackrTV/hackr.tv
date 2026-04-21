# frozen_string_literal: true

class Admin::GridSchematicsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridSchematic, find_by: :slug, children: [:ingredients]

  before_action :set_schematic, only: %i[edit update destroy]

  def index
    @schematics = GridSchematic.ordered
      .includes(:output_definition, ingredients: :input_definition)
  end

  def new
    @schematic = GridSchematic.new(
      published: false, xp_reward: 0, output_quantity: 1,
      required_clearance: 0,
      position: (GridSchematic.maximum(:position) || 0) + 1
    )
    @schematic.ingredients.build(position: 0)
    load_selects
  end

  def create
    @schematic = GridSchematic.new(schematic_params)
    if @schematic.save
      set_flash_success("Schematic '#{@schematic.name}' created.")
      redirect_to edit_admin_grid_schematic_path(@schematic)
    else
      flash.now[:error] = @schematic.errors.full_messages.join(", ")
      load_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sorted_ingredients = @schematic.ingredients.ordered.to_a
    @sorted_ingredients << @schematic.ingredients.build
    load_selects
  end

  def update
    if @schematic.update(schematic_params)
      set_flash_success("Schematic '#{@schematic.name}' updated.")
      redirect_to edit_admin_grid_schematic_path(@schematic)
    else
      flash.now[:error] = @schematic.errors.full_messages.join(", ")
      load_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @schematic.name
    @schematic.destroy!
    set_flash_success("Schematic '#{name}' deleted.")
    redirect_to admin_grid_schematics_path
  end

  private

  def set_schematic
    @schematic = GridSchematic.find_by!(slug: params[:id])
  end

  def load_selects
    @all_definitions = GridItemDefinition.ordered
  end

  def schematic_params
    params.require(:grid_schematic).permit(
      :slug, :name, :description, :output_definition_id, :output_quantity,
      :xp_reward, :required_clearance, :published, :position,
      :required_mission_slug, :required_achievement_slug, :required_room_type,
      ingredients_attributes: %i[id input_definition_id quantity position _destroy]
    )
  end
end
