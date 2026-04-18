class Admin::GridExitsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridExit

  before_action :set_exit, only: %i[edit update destroy]

  def index
    @exits = GridExit.includes(:from_room, :to_room).order(:from_room_id, :direction)
  end

  def new
    @exit = GridExit.new(locked: false)
    load_selects
  end

  def create
    @exit = GridExit.new(exit_params)
    if @exit.save
      set_flash_success("Exit created: #{@exit.from_room.name} → #{@exit.direction} → #{@exit.to_room.name}")
      redirect_to admin_grid_exits_path
    else
      load_selects
      flash.now[:error] = @exit.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @exit.update(exit_params)
      set_flash_success("Exit updated.")
      redirect_to admin_grid_exits_path
    else
      load_selects
      flash.now[:error] = @exit.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    desc = "#{@exit.from_room.name} → #{@exit.direction} → #{@exit.to_room.name}"
    @exit.destroy!
    set_flash_success("Exit '#{desc}' deleted.")
    redirect_to admin_grid_exits_path
  end

  private

  def set_exit
    @exit = GridExit.find(params[:id])
  end

  def load_selects
    @rooms = GridRoom.includes(:grid_zone).joins(:grid_zone).order("grid_zones.name, grid_rooms.name")
  end

  def exit_params
    params.require(:grid_exit).permit(:from_room_id, :to_room_id, :direction, :locked, :requires_item_id)
  end
end
