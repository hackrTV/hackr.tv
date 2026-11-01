# /root/grid_zones — the zones ledger and the zone record as console
# screens (2026-10-31; root_console.css). The record screen is the edit
# screen: show redirects there, saves stay on it; ?grid_region_id=
# prefills a new zone (the region record's [+] NEW ZONE).
class Admin::GridZonesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridZone

  before_action :set_zone, only: %i[show edit update destroy]

  def index
    @zones = GridZone.includes(:grid_region, :ambient_playlist, :grid_faction, :grid_rooms).order(:name)
  end

  def show
    redirect_to edit_admin_grid_zone_path(@zone)
  end

  def new
    @zone = GridZone.new(grid_region_id: params[:grid_region_id])
    load_selects
  end

  def create
    @zone = GridZone.new(zone_params)
    if @zone.save
      set_flash_success("Zone '#{@zone.name}' created.")
      redirect_to edit_admin_grid_zone_path(@zone)
    else
      load_selects
      flash.now[:error] = @zone.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @zone.update(zone_params)
      set_flash_success("Zone '#{@zone.name}' updated.")
      redirect_to edit_admin_grid_zone_path(@zone)
    else
      load_selects
      flash.now[:error] = @zone.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @zone.name
    if @zone.grid_rooms.any?
      set_flash_error("Can't delete '#{name}' — rooms still reference it.")
    else
      @zone.destroy!
      set_flash_success("Zone '#{name}' deleted.")
    end
    redirect_to admin_grid_zones_path
  end

  private

  def set_zone
    @zone = GridZone.find(params[:id])
  end

  def load_selects
    @regions = GridRegion.order(:name)
    @factions = GridFaction.ordered
    @playlists = ZonePlaylist.order(:name)
  end

  def zone_params
    params.require(:grid_zone).permit(
      :name, :slug, :description, :danger_level, :grid_region_id, :grid_faction_id, :ambient_playlist_id
    )
  end
end
