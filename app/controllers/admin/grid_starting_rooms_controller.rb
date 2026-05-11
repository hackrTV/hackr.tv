# frozen_string_literal: true

class Admin::GridStartingRoomsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridStartingRoom

  before_action :set_starting_room, only: %i[edit update destroy]
  before_action :load_rooms, only: %i[new edit create update]

  def index
    @starting_rooms = GridStartingRoom.includes(grid_room: {grid_zone: :grid_region}).order(:position, :name)
  end

  def new
    @starting_room = GridStartingRoom.new(active: true, position: (GridStartingRoom.maximum(:position) || 0) + 1)
  end

  def create
    @starting_room = GridStartingRoom.new(starting_room_params)
    if @starting_room.save
      set_flash_success("Starting room '#{@starting_room.name}' created.")
      redirect_to admin_grid_starting_rooms_path
    else
      flash.now[:error] = @starting_room.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @starting_room.update(starting_room_params)
      set_flash_success("Starting room '#{@starting_room.name}' updated.")
      redirect_to admin_grid_starting_rooms_path
    else
      flash.now[:error] = @starting_room.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @starting_room.name
    @starting_room.destroy!
    set_flash_success("Starting room '#{name}' deleted.")
    redirect_to admin_grid_starting_rooms_path
  end

  private

  def set_starting_room
    @starting_room = GridStartingRoom.find(params[:id])
  end

  def load_rooms
    @rooms = GridRoom.includes(grid_zone: :grid_region)
      .order(:name)
  end

  def starting_room_params
    params.require(:grid_starting_room).permit(:grid_room_id, :name, :blurb, :position, :active)
  end
end
