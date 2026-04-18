class Admin::GridMissionArcsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridMissionArc, find_by: :slug

  before_action :set_arc, only: %i[edit update destroy]

  def index
    @arcs = GridMissionArc.ordered
  end

  def new
    @arc = GridMissionArc.new(position: (GridMissionArc.maximum(:position) || 0) + 1, published: true)
  end

  def create
    @arc = GridMissionArc.new(arc_params)
    if @arc.save
      set_flash_success("Mission arc '#{@arc.name}' created.")
      redirect_to admin_grid_mission_arcs_path
    else
      flash.now[:error] = @arc.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @arc.update(arc_params)
      set_flash_success("Mission arc '#{@arc.name}' updated.")
      redirect_to admin_grid_mission_arcs_path
    else
      flash.now[:error] = @arc.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @arc.name
    @arc.destroy!
    set_flash_success("Mission arc '#{name}' deleted.")
    redirect_to admin_grid_mission_arcs_path
  end

  private

  def set_arc
    # GridMissionArc overrides to_param to return slug — look up by slug.
    @arc = GridMissionArc.find_by!(slug: params[:id])
  end

  def arc_params
    params.require(:grid_mission_arc).permit(:slug, :name, :description, :position, :published)
  end
end
