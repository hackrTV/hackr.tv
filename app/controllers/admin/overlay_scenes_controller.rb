class Admin::OverlayScenesController < Admin::ApplicationController
  include Admin::Versionable

  versionable OverlayScene, find_by: :slug

  before_action :set_scene, only: %i[show edit update destroy add_element remove_element]

  def index
    @scenes = OverlayScene.ordered
  end

  def show
    @elements = @scene.overlay_scene_elements.includes(:overlay_element).ordered
  end

  def new
    @scene = OverlayScene.new(scene_type: "composition", width: 1920, height: 1080)
  end

  def create
    @scene = OverlayScene.new(scene_params)
    if @scene.save
      set_flash_success("Scene '#{@scene.name}' created.")
      redirect_to admin_overlay_scenes_path
    else
      flash.now[:error] = @scene.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_scene_elements
  end

  def update
    if @scene.update(scene_params)
      set_flash_success("Scene '#{@scene.name}' updated.")
      redirect_to edit_admin_overlay_scene_path(@scene)
    else
      load_scene_elements
      flash.now[:error] = @scene.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @scene.name
    if @scene.overlay_scene_group_scenes.any?
      set_flash_error("Can't delete '#{name}' — still assigned to #{@scene.overlay_scene_group_scenes.count} group(s).")
    else
      @scene.destroy!
      set_flash_success("Scene '#{name}' deleted.")
    end
    redirect_to admin_overlay_scenes_path
  end

  def add_element
    scene_element = @scene.overlay_scene_elements.build(scene_element_params)
    if scene_element.save
      set_flash_success("Element added to scene.")
    else
      set_flash_error(scene_element.errors.full_messages.join(", "))
    end
    redirect_to edit_admin_overlay_scene_path(@scene)
  end

  def remove_element
    scene_element = @scene.overlay_scene_elements.find(params[:scene_element_id])
    scene_element.destroy!
    set_flash_success("Element removed from scene.")
    redirect_to edit_admin_overlay_scene_path(@scene)
  end

  private

  def set_scene
    @scene = OverlayScene.find_by!(slug: params[:id])
  end

  def load_scene_elements
    @scene_elements = @scene.overlay_scene_elements.includes(:overlay_element).ordered
    @available_elements = OverlayElement.order(:element_type, :name)
  end

  def scene_params
    permitted = params.require(:overlay_scene).permit(:name, :slug, :scene_type, :width, :height, :active, :position)
    raw = params[:overlay_scene][:settings_json]
    if raw.present?
      begin
        permitted[:settings] = JSON.parse(raw)
      rescue JSON::ParserError
        permitted[:settings] = {}
        flash.now[:warning] = "Settings JSON was invalid and was reset to {}."
      end
    else
      permitted[:settings] = {}
    end
    permitted
  end

  def scene_element_params
    params.require(:overlay_scene_element).permit(:overlay_element_id, :x, :y, :width, :height, :z_index)
  end
end
