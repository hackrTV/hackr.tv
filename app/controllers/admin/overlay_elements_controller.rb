class Admin::OverlayElementsController < Admin::ApplicationController
  include Admin::Versionable

  versionable OverlayElement, find_by: :slug

  before_action :set_element, only: %i[show edit update destroy]

  def index
    @elements = OverlayElement.order(:element_type, :name)
  end

  def show
    @used_in_scenes = @element.overlay_scenes.ordered
  end

  def new
    @element = OverlayElement.new
  end

  def create
    @element = OverlayElement.new(element_params)
    if @element.save
      set_flash_success("Element '#{@element.name}' created.")
      redirect_to admin_overlay_elements_path
    else
      flash.now[:error] = @element.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @element.update(element_params)
      set_flash_success("Element '#{@element.name}' updated.")
      redirect_to admin_overlay_elements_path
    else
      flash.now[:error] = @element.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @element.name
    if @element.overlay_scene_elements.any?
      set_flash_error("Can't delete '#{name}' — still used in #{@element.overlay_scene_elements.count} scene(s).")
    else
      @element.destroy!
      set_flash_success("Element '#{name}' deleted.")
    end
    redirect_to admin_overlay_elements_path
  end

  private

  def set_element
    @element = OverlayElement.find_by!(slug: params[:id])
  end

  def element_params
    permitted = params.require(:overlay_element).permit(:name, :slug, :element_type, :active)
    raw = params[:overlay_element][:settings_json]
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
end
