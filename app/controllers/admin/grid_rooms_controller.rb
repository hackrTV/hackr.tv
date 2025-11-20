class Admin::GridRoomsController < Admin::ApplicationController
  before_action :set_room, only: [:edit, :update]

  def index
    @rooms = GridRoom.includes(:grid_zone, :ambient_playlist).order("grid_zones.name, grid_rooms.name").joins(:grid_zone)
  end

  def edit
    @zone_playlists = ZonePlaylist.order(:name)
  end

  def update
    if @room.update(room_params)
      set_flash_success("Room '#{@room.name}' updated successfully!")
      redirect_to admin_grid_rooms_path
    else
      @zone_playlists = ZonePlaylist.order(:name)
      flash.now[:error] = "Failed to update room: #{@room.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_room
    @room = GridRoom.find(params[:id])
  end

  def room_params
    params.require(:grid_room).permit(:ambient_playlist_id)
  end
end
