class Api::GridController < ApplicationController
  include GridAuthentication

  # Skip CSRF verification for API endpoints (handled by session cookies)
  skip_before_action :verify_authenticity_token

  before_action :require_login_api, only: [:current_hackr_info, :command, :disconnect]

  # GET /api/grid/current_hackr - Get current logged-in hackr info
  def current_hackr_info
    render json: {
      logged_in: true,
      hackr: {
        id: current_hackr.id,
        hackr_alias: current_hackr.hackr_alias,
        role: current_hackr.role,
        current_room: current_hackr.current_room ? room_json(current_hackr.current_room) : nil
      }
    }
  end

  # POST /api/grid/login - Authenticate hackr
  def login
    hackr = GridHackr.find_by(hackr_alias: params[:hackr_alias])

    if hackr&.authenticate(params[:password])
      log_in(hackr)
      hackr.touch_activity!
      render json: {
        success: true,
        message: "Welcome back to THE PULSE GRID, #{hackr.hackr_alias}.",
        hackr: {
          id: hackr.id,
          hackr_alias: hackr.hackr_alias,
          role: hackr.role,
          current_room: hackr.current_room ? room_json(hackr.current_room) : nil
        }
      }
    else
      render json: {
        success: false,
        error: "Invalid hackr alias or password. Access denied."
      }, status: :unauthorized
    end
  end

  # POST /api/grid/register - Create new hackr account
  def register
    # Block registration during prerelease mode
    if APP_SETTINGS[:prerelease_mode].present?
      return render json: {
        success: false,
        error: "Registration is temporarily disabled during #{APP_SETTINGS[:prerelease_mode]} phase. Existing users can still log in."
      }, status: :forbidden
    end

    @hackr = GridHackr.new(hackr_params)
    @hackr.enforce_alias_length = true

    # Set starting room (hackr.tv Broadcast Station)
    starting_room = GridRoom.joins(:grid_zone)
      .where(grid_zones: {slug: "hackr_tv_central"})
      .where(room_type: "hub")
      .first

    @hackr.current_room = starting_room

    if @hackr.save
      log_in(@hackr)
      @hackr.touch_activity!
      render json: {
        success: true,
        message: "Welcome to THE PULSE GRID, #{@hackr.hackr_alias}. Your journey with the Fracture Network begins now.",
        hackr: {
          id: @hackr.id,
          hackr_alias: @hackr.hackr_alias,
          role: @hackr.role,
          current_room: @hackr.current_room ? room_json(@hackr.current_room) : nil
        }
      }, status: :created
    else
      render json: {
        success: false,
        error: "Registration failed: #{@hackr.errors.full_messages.join(", ")}"
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/grid/disconnect - Disconnect from THE PULSE GRID
  def disconnect
    hackr_alias = current_hackr&.hackr_alias
    log_out
    render json: {
      success: true,
      message: "#{hackr_alias} disconnected from THE PULSE GRID."
    }
  end

  # POST /api/grid/command - Execute game command
  def command
    Rails.logger.info "=== API COMMAND RECEIVED: #{params[:input]} from #{current_hackr.hackr_alias} ==="

    # Update last activity timestamp
    current_hackr.touch_activity!

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

    # Reload hackr to get updated current_room
    current_hackr.reload

    render json: {
      success: true,
      output: output,
      room_id: current_hackr.current_room&.id,
      current_room: current_hackr.current_room ? room_json(current_hackr.current_room) : nil
    }
  end

  private

  def hackr_params
    params.permit(:hackr_alias, :password, :password_confirmation)
  end

  def require_login_api
    return if logged_in?

    render json: {
      success: false,
      error: "Access denied. Please log in to THE PULSE GRID.",
      logged_in: false
    }, status: :unauthorized
  end

  def broadcast_event(room, event)
    return unless room

    Rails.logger.info "=== BROADCASTING to room #{room.id} (#{room.name}): #{event.inspect} ==="
    GridChannel.broadcast_to(room, event)
    Rails.logger.info "=== BROADCAST COMPLETE ==="
  end

  def room_json(room)
    # Get ambient playlist - room's playlist overrides zone's playlist
    ambient_playlist = room.ambient_playlist || room.grid_zone.ambient_playlist

    {
      id: room.id,
      name: room.name,
      description: room.description,
      ambient_playlist: ambient_playlist ? playlist_json(ambient_playlist) : nil
    }
  end

  def playlist_json(playlist)
    {
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      crossfade_duration_ms: playlist.crossfade_duration_ms,
      default_volume: playlist.default_volume.to_f,
      tracks: playlist.ordered_tracks.includes(:artist, album: :cover_image_attachment).map do |track|
        {
          id: track.id.to_s,
          title: track.title,
          artist: track.artist.name,
          url: track.audio_file.attached? ? url_for(track.audio_file) : nil,
          coverUrl: track.album&.cover_image&.attached? ? url_for(track.album.cover_image) : ""
        }
      end
    }
  end
end
