# Game command endpoint for the Hotwire /grid terminal (Phase 6a).
# Mirrors Api::GridController#command through the shared CommandRunner;
# the response streams exactly what changed — output line, and on
# movement the per-room subscription swap. The client echoes the command
# itself (grid-command Stimulus), so no echo here.
class Grid::CommandsController < ApplicationController
  layout "hotwire"

  before_action :require_login
  before_action :require_pulse_grid

  # POST /grid/commands
  def create
    in_breach_before = current_hackr.active_breach.present?
    @result = Grid::CommandRunner.run(current_hackr, params[:input])
    @room = current_hackr.current_room
    @breach_changed = current_hackr.active_breach.present? != in_breach_before

    if params[:surface] == "tactical" && @room && (@result.room_changed || @breach_changed)
      @map = Grid::ZoneMapBuilder.new(zone: @room.grid_zone, hackr: current_hackr).build
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to grid_path }
    end
  end

  private

  def require_pulse_grid
    head :forbidden unless current_hackr.has_feature?(FeatureGrant::PULSE_GRID)
  end
end
