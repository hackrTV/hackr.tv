class Admin::OverlayScenesController < Admin::ApplicationController
  before_action :set_scene, only: [:show, :edit, :update, :destroy]

  def index
    @scenes = OverlayScene.ordered
  end

  def show
    @elements = @scene.overlay_scene_elements.includes(:overlay_element).ordered
  end

  def new
    @scene = OverlayScene.new
    @available_elements = OverlayElement.active.order(:element_type, :name)
  end

  def create
    @scene = OverlayScene.new(scene_params)
    if @scene.save
      set_flash_success("Scene '#{@scene.name}' created!")
      redirect_to admin_overlay_scenes_path
    else
      @available_elements = OverlayElement.active.order(:element_type, :name)
      flash.now[:error] = @scene.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_elements = OverlayElement.active.order(:element_type, :name)
    @scene_elements = @scene.overlay_scene_elements.includes(:overlay_element)
  end

  def update
    if @scene.update(scene_params)
      set_flash_success("Scene '#{@scene.name}' updated!")
      redirect_to admin_overlay_scenes_path
    else
      @available_elements = OverlayElement.active.order(:element_type, :name)
      @scene_elements = @scene.overlay_scene_elements.includes(:overlay_element)
      flash.now[:error] = @scene.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @scene.name
    @scene.destroy
    set_flash_success("Scene '#{name}' deleted!")
    redirect_to admin_overlay_scenes_path
  end

  private

  def set_scene
    @scene = OverlayScene.find_by!(slug: params[:id])
  end

  def scene_params
    params.require(:overlay_scene).permit(:name, :slug, :scene_type, :width, :height, :active, :position, settings: {})
  end
end
