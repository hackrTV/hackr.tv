class Api::GridController < ApplicationController
  include GridAuthentication

  before_action :require_login_api, only: %i[current_hackr_info command disconnect request_password_reset request_email_change debit]
  before_action -> { require_feature_api(FeatureGrant::PULSE_GRID) }, only: [:command]
  before_action :require_admin_api, only: [:debit]

  # GET /api/grid/current_hackr - Get current logged-in hackr info
  def current_hackr_info
    render json: {
      logged_in: true,
      hackr: {
        id: current_hackr.id,
        hackr_alias: current_hackr.hackr_alias,
        email: current_hackr.email,
        role: current_hackr.role,
        current_room: current_hackr.current_room ? room_json(current_hackr.current_room) : nil,
        features: current_hackr.admin? ? [FeatureGrant::PULSE_GRID] : current_hackr.feature_grants.pluck(:feature)
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
          .where(grid_zones: {slug: "hackr-tv-central"})
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
          email: hackr.email,
          role: hackr.role,
          current_room: hackr.current_room ? room_json(hackr.current_room) : nil,
          features: hackr.admin? ? [FeatureGrant::PULSE_GRID] : hackr.feature_grants.pluck(:feature)
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
      .where(grid_zones: {slug: "hackr-tv-central"})
      .where(room_type: "hub")
      .first

    @hackr.current_room = starting_room

    @hackr.registration_ip = request.remote_ip

    ActiveRecord::Base.transaction do
      if @hackr.save
        token.mark_used!
        @hackr.provision_economy!
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
            current_room: @hackr.current_room ? room_json(@hackr.current_room) : nil,
            features: @hackr.admin? ? [FeatureGrant::PULSE_GRID] : @hackr.feature_grants.pluck(:feature)
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

  # POST /api/grid/forgot_password - Send password reset email (unauthenticated)
  def forgot_password
    email = params[:email].to_s.downcase.strip

    # Always return success to prevent email enumeration
    hackr = GridHackr.find_by(email: email)

    if hackr
      token = GridVerificationToken.create!(
        grid_hackr: hackr,
        purpose: "password_reset",
        ip_address: request.remote_ip
      )

      GridMailer.password_reset(token).deliver_later
      Rails.logger.info("[AUTH] Forgot password email sent: email=#{email} ip=#{request.remote_ip}")
    else
      Rails.logger.info("[AUTH] Forgot password attempt for unknown email: ip=#{request.remote_ip}")
    end

    render json: {
      success: true,
      message: "If an account exists with that email, a reset link has been sent."
    }
  end

  # POST /api/grid/request_password_reset - Send password reset email
  def request_password_reset
    if current_hackr.email.blank?
      return render json: {
        success: false,
        error: "No email address on file. Set an email first to enable password reset."
      }, status: :unprocessable_entity
    end

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

  # POST /api/grid/reset_password - Reset password with token (no login required)
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

    unless token.valid_for_use?
      error_message = token.used? ? "This reset link has already been used." : "This reset link has expired."
      return render json: {
        success: false,
        error: error_message
      }, status: :unprocessable_entity
    end

    hackr = token.grid_hackr
    hackr.password = params[:password]
    hackr.password_confirmation = params[:password_confirmation]

    ActiveRecord::Base.transaction do
      if hackr.save
        token.mark_used!
        Rails.logger.info("[AUTH] Password reset completed: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
        render json: {
          success: true,
          message: "Password updated successfully."
        }
      else
        render json: {
          success: false,
          error: "Password update failed: #{hackr.errors.full_messages.join(", ")}"
        }, status: :unprocessable_entity
      end
    end
  end

  # POST /api/grid/request_email_change - Send email change verification
  def request_email_change
    new_email = params[:new_email].to_s.downcase.strip

    if new_email.blank?
      return render json: {
        success: false,
        error: "New email address is required."
      }, status: :unprocessable_entity
    end

    unless new_email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: {
        success: false,
        error: "Please enter a valid email address."
      }, status: :unprocessable_entity
    end

    if new_email == current_hackr.email
      return render json: {
        success: false,
        error: "New email must be different from your current email."
      }, status: :unprocessable_entity
    end

    if GridHackr.exists?(email: new_email)
      return render json: {
        success: false,
        error: "This email address is already in use."
      }, status: :unprocessable_entity
    end

    token = GridVerificationToken.create!(
      grid_hackr: current_hackr,
      purpose: "email_change",
      metadata: {new_email: new_email},
      ip_address: request.remote_ip
    )

    GridMailer.email_change_verification(token).deliver_later

    Rails.logger.info("[AUTH] Email change verification sent: hackr_alias=#{current_hackr.hackr_alias} new_email=#{new_email} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Verification email sent to #{new_email}. Check your inbox to confirm the change."
    }
  end

  # POST /api/grid/confirm_email_change - Confirm email change with token (no login required)
  def confirm_email_change
    token = GridVerificationToken.find_by(token: params[:token])

    if token.nil?
      return render json: {
        success: false,
        error: "Invalid verification token."
      }, status: :unprocessable_entity
    end

    unless token.purpose == "email_change"
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

    if GridHackr.exists?(email: token.new_email)
      return render json: {
        success: false,
        error: "This email address is already in use."
      }, status: :unprocessable_entity
    end

    hackr = token.grid_hackr
    old_email = hackr.email

    begin
      ActiveRecord::Base.transaction do
        hackr.update!(email: token.new_email)
        token.mark_used!
      end
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      return render json: {
        success: false,
        error: "This email address is already in use."
      }, status: :unprocessable_entity
    end

    GridMailer.email_change_notification(hackr, old_email).deliver_later

    Rails.logger.info("[AUTH] Email changed: hackr_alias=#{hackr.hackr_alias} old_email=#{old_email} new_email=#{token.new_email} ip=#{request.remote_ip}")
    render json: {
      success: true,
      message: "Email address updated successfully."
    }
  end

  # POST /api/grid/debit - External service debit (e.g., Synthia redemptions)
  # Authenticated via Bearer token (service account)
  def debit
    hackr_alias = params[:hackr_alias]
    amount = params[:amount].to_i
    memo = params[:memo].to_s.presence || "External debit"

    hackr = GridHackr.find_by(hackr_alias: hackr_alias)
    unless hackr
      return render json: {success: false, error: "Hackr not found"}, status: :not_found
    end

    cache = hackr.default_cache
    unless cache&.active?
      return render json: {success: false, error: "No active cache"}, status: :unprocessable_entity
    end

    unless amount.positive?
      return render json: {success: false, error: "Amount must be positive"}, status: :unprocessable_entity
    end

    tx = Grid::TransactionService.redeem!(from_cache: cache, amount: amount, memo: memo)
    Rails.logger.info("[ECONOMY] Debit: hackr=#{hackr_alias} amount=#{amount} memo=#{memo} tx=#{tx.short_hash}")

    render json: {
      success: true,
      tx_hash: tx.tx_hash,
      remaining_balance: cache.balance
    }
  rescue Grid::TransactionService::InsufficientBalance
    render json: {
      success: false,
      error: "Insufficient balance",
      balance: cache&.balance || 0
    }, status: :unprocessable_entity
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
      tracks: playlist.ordered_tracks.includes(:artist, release: :cover_image_attachment).map do |track|
        {
          id: track.id.to_s,
          title: track.title,
          artist: track.artist.name,
          url: track.audio_file.attached? ? url_for(track.audio_file) : nil,
          coverUrl: track.release&.cover_image&.attached? ? url_for(track.release.cover_image) : "",
          coverUrls: track.release ? cover_urls_for(track.release) : nil
        }
      end
    }
  end
end
