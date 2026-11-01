# /root/grid_exits — the exits ledger and the exit record as console
# screens (2026-10-31; root_console.css). The record screen is the edit
# screen: show redirects there, saves stay on it; ?from_room_id=
# prefills a new exit (the room record's [+] NEW EXIT). Replies write
# "from > direction > to" — no arrows in the Terminus subset.
class Admin::GridExitsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridExit

  before_action :set_exit, only: %i[show edit update destroy]

  def index
    @exits = GridExit.includes(from_room: :grid_zone, to_room: :grid_zone).order(:from_room_id, :direction)
  end

  def show
    redirect_to edit_admin_grid_exit_path(@exit)
  end

  def new
    @exit = GridExit.new(locked: false, from_room_id: params[:from_room_id])
    load_selects
  end

  def create
    @exit = GridExit.new(exit_params)
    if @exit.save
      set_flash_success("Exit created: #{@exit.from_room.name} > #{@exit.direction} > #{@exit.to_room.name}")
      redirect_to edit_admin_grid_exit_path(@exit)
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
      redirect_to edit_admin_grid_exit_path(@exit)
    else
      load_selects
      flash.now[:error] = @exit.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    desc = "#{@exit.from_room.name} > #{@exit.direction} > #{@exit.to_room.name}"
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
