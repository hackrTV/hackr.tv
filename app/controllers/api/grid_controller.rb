class Api::GridController < ApplicationController
  include GridAuthentication

  before_action :require_login_api, only: %i[current_hackr_info command disconnect request_password_reset reset_password]

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
      # Ensure hackr has a current room (spawn point if missing)
      if hackr.current_room.nil?
        starting_room = GridRoom.joins(:grid_zone)
          .where(grid_zones: {slug: "hackr_tv_central"})
          .where(room_type: "hub")
          .first
        hackr.update!(current_room: starting_room) if starting_room
      end

      log_in(hackr)
      hackr.touch_activity!
      Rails.logger.info("[AUTH] Login success: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
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
      attempted_alias = params[:hackr_alias].to_s.truncate(50)
      reason = hackr ? "invalid_password" : "unknown_alias"
      Rails.logger.warn("[AUTH] Login failed: attempted_alias=#{attempted_alias} reason=#{reason} ip=#{request.remote_ip}")
      render json: {
        success: false,
        error: "Invalid hackr alias or password. Access denied."
      }, status: :unauthorized
    end
  end

  # POST /api/grid/register - Request registration verification email
  def register
    email = params[:email].to_s.downcase.strip

    if email.blank?
      return render json: {
        success: false,
        error: "Email address is required."
      }, status: :unprocessable_entity
    end

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: {
        success: false,
        error: "Please enter a valid email address."
      }, status: :unprocessable_entity
    end

    # Check if email is already registered
    if GridHackr.exists?(email: email)
      return render json: {
        success: false,
        error: "This email address is already registered. Try logging in instead."
      }, status: :unprocessable_entity
    end

    # Create registration token
    token = GridRegistrationToken.create!(
      email: email,
      ip_address: request.remote_ip
    )

    # Send verification email
    GridMailer.registration_verification(token).deliver_later

    Rails.logger.info("[AUTH] Registration email sent: email=#{email} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Verification email sent. Check your inbox to complete registration."
    }
  end

  # GET /api/grid/verify/:token - Check if registration token is valid
  def verify_token
    token = GridRegistrationToken.find_by(token: params[:token])

    if token.nil?
      return render json: {
        valid: false,
        error: "Invalid verification link."
      }
    end

    if token.used?
      return render json: {
        valid: false,
        error: "This verification link has already been used."
      }
    end

    if token.expired?
      return render json: {
        valid: false,
        error: "This verification link has expired. Please register again."
      }
    end

    render json: {
      valid: true,
      email: token.email
    }
  end

  # POST /api/grid/complete_registration - Complete registration with alias and password
  def complete_registration
    token = GridRegistrationToken.find_by(token: params[:token])

    if token.nil?
      return render json: {
        success: false,
        error: "Invalid verification token."
      }, status: :unprocessable_entity
    end

    unless token.valid_for_use?
      error_message = token.used? ? "This verification link has already been used." : "This verification link has expired."
      return render json: {
        success: false,
        error: error_message
      }, status: :unprocessable_entity
    end

    @hackr = GridHackr.new(
      email: token.email,
      hackr_alias: params[:hackr_alias],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
    @hackr.enforce_alias_length = true

    # Set starting room (hackr.tv Broadcast Station)
    starting_room = GridRoom.joins(:grid_zone)
      .where(grid_zones: {slug: "hackr_tv_central"})
      .where(room_type: "hub")
      .first

    @hackr.current_room = starting_room

    ActiveRecord::Base.transaction do
      if @hackr.save
        token.mark_used!
        log_in(@hackr)
        @hackr.touch_activity!
        Rails.logger.info("[AUTH] Registration completed: hackr_alias=#{@hackr.hackr_alias} email=#{token.email} ip=#{request.remote_ip}")
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
        Rails.logger.warn("[AUTH] Registration completion failed: email=#{token.email} errors=#{@hackr.errors.full_messages.join("; ")} ip=#{request.remote_ip}")
        render json: {
          success: false,
          error: "Registration failed: #{@hackr.errors.full_messages.join(", ")}"
        }, status: :unprocessable_entity
      end
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

  # POST /api/grid/request_password_reset - Send password reset email
  def request_password_reset
    token = GridVerificationToken.create!(
      grid_hackr: current_hackr,
      purpose: "password_reset",
      ip_address: request.remote_ip
    )

    GridMailer.password_reset(token).deliver_later

    Rails.logger.info("[AUTH] Password reset email sent: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Password reset email sent. Check your inbox."
    }
  end

  # POST /api/grid/reset_password - Reset password with token
  def reset_password
    token = GridVerificationToken.find_by(token: params[:token])

    if token.nil?
      return render json: {
        success: false,
        error: "Invalid reset token."
      }, status: :unprocessable_entity
    end

    unless token.purpose == "password_reset"
      return render json: {
        success: false,
        error: "Invalid reset token."
      }, status: :unprocessable_entity
    end

    unless token.grid_hackr_id == current_hackr.id
      return render json: {
        success: false,
        error: "This reset token does not belong to your account."
      }, status: :unprocessable_entity
    end

    unless token.valid_for_use?
      error_message = token.used? ? "This reset link has already been used." : "This reset link has expired."
      return render json: {
        success: false,
        error: error_message
      }, status: :unprocessable_entity
    end

    current_hackr.password = params[:password]
    current_hackr.password_confirmation = params[:password_confirmation]

    ActiveRecord::Base.transaction do
      if current_hackr.save
        token.mark_used!
        Rails.logger.info("[AUTH] Password reset completed: hackr_alias=#{current_hackr.hackr_alias} ip=#{request.remote_ip}")
        render json: {
          success: true,
          message: "Password updated successfully."
        }
      else
        render json: {
          success: false,
          error: "Password update failed: #{current_hackr.errors.full_messages.join(", ")}"
        }, status: :unprocessable_entity
      end
    end
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
