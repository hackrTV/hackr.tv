class Admin::GridZonesController < Admin::ApplicationController
  before_action :set_zone, only: [:edit, :update]

  def index
    @zones = GridZone.includes(:ambient_playlist, :grid_faction).order(:name)
  end

  def edit
    @zone_playlists = ZonePlaylist.order(:name)
  end

  def update
    if @zone.update(zone_params)
      set_flash_success("Zone '#{@zone.name}' updated successfully!")
      redirect_to admin_grid_zones_path
    else
      @zone_playlists = ZonePlaylist.order(:name)
      flash.now[:error] = "Failed to update zone: #{@zone.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_zone
    @zone = GridZone.find(params[:id])
  end

  def zone_params
    params.require(:grid_zone).permit(:ambient_playlist_id)
  end
end
