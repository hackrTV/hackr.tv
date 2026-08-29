# Shared base for the Hotwire tactical surface (Phase 6b): login +
# tactical_grid feature gate. Mirrors the SPA's FeatureGate wrapping of
# /grid/1337 (has_feature? admits admins implicitly).
class Grid::TacticalBaseController < ApplicationController
  before_action :require_login
  before_action :require_tactical_grid

  private

  def require_tactical_grid
    return if current_hackr.has_feature?(FeatureGrant::TACTICAL_GRID)

    respond_to do |format|
      format.html { render "grid/game/coming_soon" }
      format.turbo_stream { head :forbidden }
    end
  end
end
