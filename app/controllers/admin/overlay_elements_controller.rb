# Read-only controller - Overlay elements are managed via YAML files
# Edit data/overlays/elements.yml and run: rails data:overlay_elements
class Admin::OverlayElementsController < Admin::ApplicationController
  def index
    @elements = OverlayElement.order(:element_type, :name)
  end

  def show
    @element = OverlayElement.find_by!(slug: params[:id])
    @used_in_scenes = @element.overlay_scenes.ordered
  end
end
