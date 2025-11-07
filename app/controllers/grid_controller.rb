class GridController < ApplicationController
  include GridAuthentication

  before_action :require_login, only: [:index, :command]
  before_action :require_logout, only: [:login, :register]

  # GET /grid - Main game interface
  def index
    @current_room = current_hackr.current_room
    @messages = GridMessage.recent.limit(20) if @current_room
  end

  # GET /grid/login - Login form
  def login
  end

  # POST /grid/login - Process login
  def create_session
    hackr = GridHackr.find_by(hackr_alias: params[:hackr_alias])

    if hackr&.authenticate(params[:password])
      log_in(hackr)
      flash[:success] = "Welcome back to THE PULSE GRID, #{hackr.hackr_alias}."
      redirect_to grid_path
    else
      flash.now[:error] = "Invalid hackr alias or password. Access denied."
      render :login, status: :unprocessable_entity
    end
  end

  # GET /grid/register - Registration form
  def register
  end

  # POST /grid/register - Create new hackr account
  def create_hackr
    @hackr = GridHackr.new(hackr_params)

    # Set starting room (hackr.tv Broadcast Station)
    starting_room = GridRoom.joins(:grid_zone)
      .where(grid_zones: {slug: "hackr_tv_central"})
      .where(room_type: "hub")
      .first

    @hackr.current_room = starting_room

    if @hackr.save
      log_in(@hackr)
      flash[:success] = "Welcome to THE PULSE GRID, #{@hackr.hackr_alias}. Your resistance begins now."
      redirect_to grid_path
    else
      flash.now[:error] = "Registration failed: #{@hackr.errors.full_messages.join(", ")}"
      render :register, status: :unprocessable_entity
    end
  end

  # DELETE /grid/logout - Log out
  def logout
    hackr_alias = current_hackr&.hackr_alias
    log_out
    flash[:notice] = "#{hackr_alias} disconnected from THE PULSE GRID."
    redirect_to grid_login_path
  end

  # POST /grid/command - Execute game command
  def command
    Rails.logger.info "=== COMMAND RECEIVED: #{params[:input]} from #{current_hackr.hackr_alias} ==="

    result = Grid::CommandParser.new(current_hackr, params[:input]).execute
    output = result[:output]
    event = result[:event]

    Rails.logger.info "=== EVENT: #{event.inspect} ==="

    # Broadcast event to affected rooms
    if event
      case event[:type]
      when "movement"
        # Broadcast to both old and new rooms
        broadcast_event(GridRoom.find(event[:from_room_id]), event) if event[:from_room_id]
        broadcast_event(GridRoom.find(event[:to_room_id]), event) if event[:to_room_id]
      when "say", "take", "drop"
        # Broadcast to current room
        Rails.logger.info "=== Broadcasting #{event[:type]} to room #{current_hackr.current_room&.id} ==="
        broadcast_event(current_hackr.current_room, event)
      end
    end

    respond_to do |format|
      format.json { render json: {output: output, success: true, room_id: current_hackr.current_room&.id} }
      format.html do
        flash.now[:command_output] = output
        render :index
      end
    end
  end

  private

  def hackr_params
    params.require(:grid_hackr).permit(:hackr_alias, :password, :password_confirmation)
  end

  def broadcast_event(room, event)
    return unless room

    Rails.logger.info "=== BROADCASTING to room #{room.id} (#{room.name}): #{event.inspect} ==="
    GridChannel.broadcast_to(room, event)
    Rails.logger.info "=== BROADCAST COMPLETE ==="
  end
end
