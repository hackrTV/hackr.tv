class Admin::OverlaySceneGroupsController < Admin::ApplicationController
  include Admin::Versionable

  versionable OverlaySceneGroup, find_by: :slug

  before_action :set_group, only: %i[show edit update destroy add_scene remove_scene]

  def index
    @scene_groups = OverlaySceneGroup.ordered.includes(:overlay_scenes)
  end

  def show
    @group_scenes = @scene_group.overlay_scene_group_scenes.includes(:overlay_scene).order(position: :asc)
  end

  def new
    @scene_group = OverlaySceneGroup.new
  end

  def create
    @scene_group = OverlaySceneGroup.new(group_params)
    if @scene_group.save
      set_flash_success("Scene group '#{@scene_group.name}' created.")
      redirect_to admin_overlay_scene_groups_path
    else
      flash.now[:error] = @scene_group.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_group_scenes
  end

  def update
    if @scene_group.update(group_params)
      set_flash_success("Scene group '#{@scene_group.name}' updated.")
      redirect_to edit_admin_overlay_scene_group_path(@scene_group)
    else
      load_group_scenes
      flash.now[:error] = @scene_group.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @scene_group.name
    @scene_group.destroy!
    set_flash_success("Scene group '#{name}' deleted.")
    redirect_to admin_overlay_scene_groups_path
  end

  def add_scene
    group_scene = @scene_group.overlay_scene_group_scenes.build(group_scene_params)
    if group_scene.save
      set_flash_success("Scene added to group.")
    else
      set_flash_error(group_scene.errors.full_messages.join(", "))
    end
    redirect_to edit_admin_overlay_scene_group_path(@scene_group)
  end

  def remove_scene
    group_scene = @scene_group.overlay_scene_group_scenes.find(params[:group_scene_id])
    group_scene.destroy!
    set_flash_success("Scene removed from group.")
    redirect_to edit_admin_overlay_scene_group_path(@scene_group)
  end

  private

  def set_group
    @scene_group = OverlaySceneGroup.find_by!(slug: params[:id])
  end

  def load_group_scenes
    @group_scenes = @scene_group.overlay_scene_group_scenes.includes(:overlay_scene).order(position: :asc)
    @available_scenes = OverlayScene.where.not(id: @scene_group.overlay_scenes.pluck(:id)).ordered
  end

  def group_params
    params.require(:overlay_scene_group).permit(:name, :slug)
  end

  def group_scene_params
    params.require(:overlay_scene_group_scene).permit(:overlay_scene_id, :position)
  end
end
