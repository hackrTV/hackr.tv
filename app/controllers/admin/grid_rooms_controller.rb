# Read-only controller - Grid rooms are managed via YAML files
# Edit data/world/rooms.yml and run: rails data:rooms
class Admin::GridRoomsController < Admin::ApplicationController
  def index
    @rooms = GridRoom.includes(:grid_zone, :ambient_playlist).order("grid_zones.name, grid_rooms.name").joins(:grid_zone)
  end
end
