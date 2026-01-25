# Read-only controller - Overlay scenes are managed via YAML files
# Edit data/overlays/scenes.yml and run: rails data:overlay_scenes
class Admin::OverlayScenesController < Admin::ApplicationController
  def index
    @scenes = OverlayScene.ordered
  end

  def show
    @scene = OverlayScene.find_by!(slug: params[:id])
    @elements = @scene.overlay_scene_elements.includes(:overlay_element).ordered
  end
end
