class Admin::OverlaySceneElementsController < Admin::ApplicationController
  before_action :set_scene
  before_action :set_scene_element, only: [:edit, :update, :destroy]

  def new
    @scene_element = @scene.overlay_scene_elements.build
    @available_elements = available_elements_for_scene
    load_content_options
  end

  def create
    @scene_element = @scene.overlay_scene_elements.build(scene_element_params)
    apply_content_overrides

    if @scene_element.save
      set_flash_success("Element added to scene!")
      redirect_to admin_overlay_scene_path(@scene)
    else
      @available_elements = available_elements_for_scene
      load_content_options
      flash.now[:error] = @scene_element.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_elements = OverlayElement.active.order(:element_type, :name)
    load_content_options
  end

  def update
    apply_content_overrides

    if @scene_element.update(scene_element_params)
      set_flash_success("Element updated!")
      redirect_to admin_overlay_scene_path(@scene)
    else
      @available_elements = OverlayElement.active.order(:element_type, :name)
      load_content_options
      flash.now[:error] = @scene_element.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scene_element.destroy
    set_flash_success("Element removed from scene!")
    redirect_to admin_overlay_scene_path(@scene)
  end

  private

  def set_scene
    @scene = OverlayScene.find_by!(slug: params[:overlay_scene_id])
  end

  def set_scene_element
    @scene_element = @scene.overlay_scene_elements.find(params[:id])
  end

  def scene_element_params
    params.require(:overlay_scene_element).permit(:overlay_element_id, :x, :y, :width, :height, :z_index)
  end

  def available_elements_for_scene
    # Show all active elements - same element can be added multiple times with different overrides
    OverlayElement.active.order(:element_type, :name)
  end

  def load_content_options
    @lower_thirds = OverlayLowerThird.where(active: true).order(:name)
    @tickers = OverlayTicker.where(active: true).order(:name)
    @codex_entries = CodexEntry.where(published: true).order(:name)
  end

  def apply_content_overrides
    overrides = @scene_element.overrides || {}

    # Content slug settings
    %w[lower_third_slug ticker_slug codex_entry_slug].each do |key|
      if params[key].present?
        overrides[key] = params[key]
      elsif params.key?(key) && params[key].blank?
        overrides.delete(key)
      end
    end

    # Numeric settings
    if params[:max_items].present?
      overrides["max_items"] = params[:max_items].to_i
    elsif params.key?(:max_items) && params[:max_items].blank?
      overrides.delete("max_items")
    end

    @scene_element.overrides = overrides
  end
end
