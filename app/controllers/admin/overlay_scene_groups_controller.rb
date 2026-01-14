class Admin::OverlaySceneGroupsController < Admin::ApplicationController
  before_action :set_scene_group, only: [:show, :edit, :update, :destroy, :add_scene, :remove_scene, :reorder_scenes]

  def index
    @scene_groups = OverlaySceneGroup.ordered.includes(:overlay_scenes)
  end

  def show
    @available_scenes = OverlayScene.where.not(id: @scene_group.overlay_scenes.pluck(:id)).ordered
  end

  def new
    @scene_group = OverlaySceneGroup.new
  end

  def create
    @scene_group = OverlaySceneGroup.new(scene_group_params)
    if @scene_group.save
      set_flash_success("Scene Group '#{@scene_group.name}' created!")
      redirect_to admin_overlay_scene_group_path(@scene_group)
    else
      flash.now[:error] = @scene_group.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scene_group.update(scene_group_params)
      set_flash_success("Scene Group '#{@scene_group.name}' updated!")
      redirect_to admin_overlay_scene_group_path(@scene_group)
    else
      flash.now[:error] = @scene_group.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @scene_group.name
    @scene_group.destroy
    set_flash_success("Scene Group '#{name}' deleted!")
    redirect_to admin_overlay_scene_groups_path
  end

  def add_scene
    scene = OverlayScene.find_by!(slug: params[:scene_id])
    @scene_group.overlay_scene_group_scenes.create!(overlay_scene: scene)
    redirect_to admin_overlay_scene_group_path(@scene_group), notice: "Scene added to group."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_overlay_scene_group_path(@scene_group), alert: "Failed to add scene: #{e.message}"
  end

  def remove_scene
    scene_group_scene = @scene_group.overlay_scene_group_scenes.find(params[:scene_group_scene_id])
    scene_group_scene.destroy
    redirect_to admin_overlay_scene_group_path(@scene_group), notice: "Scene removed from group."
  end

  def reorder_scenes
    scene_ids = params[:scene_ids] || []
    scene_ids.each_with_index do |scene_id, index|
      sgs = @scene_group.overlay_scene_group_scenes.find_by(overlay_scene_id: scene_id)
      sgs&.update(position: index + 1)
    end
    head :ok
  end

  private

  def set_scene_group
    @scene_group = OverlaySceneGroup.find_by!(slug: params[:id])
  end

  def scene_group_params
    params.require(:overlay_scene_group).permit(:name, :slug)
  end
end
