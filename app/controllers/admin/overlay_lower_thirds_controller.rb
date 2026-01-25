# Read-only controller - Overlay lower thirds are managed via YAML files
# Edit data/overlays/lower_thirds.yml and run: rails data:overlay_lower_thirds
class Admin::OverlayLowerThirdsController < Admin::ApplicationController
  def index
    @lower_thirds = OverlayLowerThird.order(:name)
  end

  def show
    @lower_third = OverlayLowerThird.find_by!(slug: params[:id])
  end
end
