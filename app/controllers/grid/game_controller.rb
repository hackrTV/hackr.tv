# Server-rendered legacy PULSE GRID terminal (Hotwire migration Phase
# 6a) — ports GridGamePage.tsx. The initial `look` runs inline at render
# time (the SPA POSTed it on mount); live room events arrive over the
# per-room grid_room_html Turbo stream; commands POST to
# Grid::CommandsController.
class Grid::GameController < ApplicationController
  before_action :require_login
  before_action :require_pulse_grid

  # GET /grid
  def show
    result = Grid::CommandRunner.run(current_hackr, "look")
    @initial_output = result.output
    @room = current_hackr.current_room
  end

  private

  # FeatureGate.tsx parity: without the grant, the coming-soon page
  # renders in place (has_feature? admits admins implicitly).
  def require_pulse_grid
    return if current_hackr.has_feature?(FeatureGrant::PULSE_GRID)

    render "grid/game/coming_soon"
  end
end
