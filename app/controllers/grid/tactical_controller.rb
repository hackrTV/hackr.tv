# Server-rendered tactical shell (Hotwire migration Phase 6b) — ports
# GridTacticalPage.tsx / TacticalContext.tsx. The command form posts to
# the shared Grid::CommandsController with surface=tactical, whose
# response streams the changed tactical fragments (bar vitals, room
# flags, map, breach region, tab-refresh bus) — replacing the SPA's
# three refresh tokens. Status tabs and side panels are lazy frames.
class Grid::TacticalController < Grid::TacticalBaseController
  # GET /grid/1337
  def show
    result = Grid::CommandRunner.run(current_hackr, "look")
    @initial_output = result.output
    @room = current_hackr.current_room
    @map = @room && Grid::ZoneMapBuilder.new(zone: @room.grid_zone, hackr: current_hackr).build
  end
end
