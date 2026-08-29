# Standalone zone-map fragment (Phase 6c) — the shell renders the map
# inline and the command bus replaces it on movement; this endpoint
# serves ad-hoc refetches (recovery, specs).
class Grid::TacticalMapController < Grid::TacticalBaseController
  # GET /grid/1337/map
  def show
    @room = current_hackr.current_room
    return head :unprocessable_entity unless @room

    @map = Grid::ZoneMapBuilder.new(zone: @room.grid_zone, hackr: current_hackr).build
    render partial: "grid/tactical/zone_map", locals: {map: @map, current_room: @room}
  end
end
