# Read-only controller - Overlay scene groups are managed via YAML files
# Edit data/overlays/scene_groups.yml and run: rails data:overlay_scene_groups
class Admin::OverlaySceneGroupsController < Admin::ApplicationController
  def index
    @scene_groups = OverlaySceneGroup.ordered.includes(:overlay_scenes)
  end

  def show
    @scene_group = OverlaySceneGroup.find_by!(slug: params[:id])
    @available_scenes = OverlayScene.where.not(id: @scene_group.overlay_scenes.pluck(:id)).ordered
  end
end
