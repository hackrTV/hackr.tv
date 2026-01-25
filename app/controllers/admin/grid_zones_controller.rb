# Read-only controller - Grid zones are managed via YAML files
# Edit data/world/zones.yml and run: rails data:zones
class Admin::GridZonesController < Admin::ApplicationController
  def index
    @zones = GridZone.includes(:ambient_playlist, :grid_faction).order(:name)
  end
end
