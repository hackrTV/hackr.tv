class Admin::GridRoomsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridRoom

  before_action :set_room, only: %i[edit update destroy]

  def index
    @rooms = GridRoom.includes(:grid_zone, :ambient_playlist)
      .joins(:grid_zone)
      .order("grid_zones.name, grid_rooms.name")
  end

  def new
    @room = GridRoom.new(min_clearance: 0)
    load_selects
  end

  def create
    @room = GridRoom.new(room_params)
    if @room.save
      set_flash_success("Room '#{@room.name}' created.")
      redirect_to admin_grid_rooms_path
    else
      load_selects
      flash.now[:error] = @room.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @room.update(room_params)
      set_flash_success("Room '#{@room.name}' updated.")
      redirect_to admin_grid_rooms_path
    else
      load_selects
      flash.now[:error] = @room.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @room.name
    if @room.grid_mobs.any? || @room.grid_items.any?
      set_flash_error("Can't delete '#{name}' — mobs or items still reference it.")
    else
      @room.destroy!
      set_flash_success("Room '#{name}' deleted.")
    end
    redirect_to admin_grid_rooms_path
  end

  private

  def set_room
    @room = GridRoom.find(params[:id])
  end

  def load_selects
    @zones = GridZone.includes(:grid_region).order(:name)
    @playlists = ZonePlaylist.order(:name)
  end

  def room_params
    params.require(:grid_room).permit(
      :name, :slug, :description, :room_type, :min_clearance, :grid_zone_id, :ambient_playlist_id
    )
  end
end
