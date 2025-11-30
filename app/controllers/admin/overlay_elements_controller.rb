class Admin::OverlayElementsController < Admin::ApplicationController
  before_action :set_element, only: [:show, :edit, :update, :destroy]

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
      set_flash_success("Element '#{@element.name}' created!")
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
      set_flash_success("Element '#{@element.name}' updated!")
      redirect_to admin_overlay_elements_path
    else
      flash.now[:error] = @element.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @element.overlay_scenes.any?
      set_flash_error("Cannot delete element '#{@element.name}' - it's used in #{@element.overlay_scenes.count} scene(s)")
    else
      name = @element.name
      @element.destroy
      set_flash_success("Element '#{name}' deleted!")
    end
    redirect_to admin_overlay_elements_path
  end

  private

  def set_element
    @element = OverlayElement.find_by!(slug: params[:id])
  end

  def element_params
    params.require(:overlay_element).permit(:name, :slug, :element_type, :active, settings: {})
  end
end
