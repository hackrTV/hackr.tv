class Admin::GridZonesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridZone

  before_action :set_zone, only: %i[edit update destroy]

  def index
    @zones = GridZone.includes(:grid_region, :ambient_playlist, :grid_faction, :grid_rooms).order(:name)
  end

  def new
    @zone = GridZone.new
    load_selects
  end

  def create
    @zone = GridZone.new(zone_params)
    if @zone.save
      set_flash_success("Zone '#{@zone.name}' created.")
      redirect_to admin_grid_zones_path
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
      redirect_to admin_grid_zones_path
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
      :name, :slug, :description, :zone_type, :color_scheme, :grid_region_id, :grid_faction_id, :ambient_playlist_id
    )
  end
end
