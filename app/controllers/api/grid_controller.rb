class Api::GridController < ApplicationController
  include GridAuthentication
  include GridSerialization

  # Phase 7 decommission: the SPA's per-tab JSON loaders, registration /
  # password / identity endpoints, and zone_map are retired — those flows
  # are server-rendered now (Grid:: controllers). What remains is the
  # programmatic client surface (login + command, envelope spec-locked),
  # the session utilities Stimulus and admin pages use (current_hackr,
  # disconnect), and the Bearer-token external debit endpoint.
  before_action :require_login_api, only: %i[current_hackr_info command disconnect debit]
  before_action -> { require_feature_api(FeatureGrant::PULSE_GRID) }, only: [:command]
  before_action :require_admin_api, only: [:debit]

  # GET /api/grid/current_hackr - Session identity for API clients and
  # the admin moderation pages (alias -> id lookup).
  def current_hackr_info
    render json: {
      logged_in: true,
      hackr: auth_hackr_json(current_hackr)
    }
  end

  # POST /api/grid/login - Authenticate hackr
  def login
    hackr = GridHackr.find_by(hackr_alias: params[:hackr_alias])

    if hackr&.authenticate(params[:password])
      if hackr.login_disabled?
        Rails.logger.warn("[AUTH] Login blocked (disabled): hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
        return render json: {success: false, error: "This account has been disabled."}, status: :forbidden
      end

      # 2FA gate: if TOTP enabled, defer login until code is verified
      if hackr.otp_required_for_login?
        session[:pending_2fa_hackr_id] = hackr.id
        session[:pending_2fa_at] = Time.current.to_i
        Rails.logger.info("[AUTH] 2FA required: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
        return render json: {success: true, requires_totp: true}
      end

      establish_grid_session(hackr)
      Rails.logger.info("[AUTH] Login success: hackr_alias=#{hackr.hackr_alias} ip=#{request.remote_ip}")
      render json: {
        success: true,
        message: "Welcome back to THE PULSE GRID, #{hackr.hackr_alias}.",
        hackr: auth_hackr_json(hackr)
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

  # DELETE /api/grid/disconnect - Log out
  def disconnect
    hackr_alias = current_hackr&.hackr_alias
    log_out
    render json: {
      success: true,
      message: "#{hackr_alias} disconnected from THE PULSE GRID."
    }
  end

  # POST /api/grid/debit - External CRED debit (admin Bearer token only)
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

  # POST /api/grid/command - Execute a terminal command
  def command
    Rails.logger.info "=== API COMMAND RECEIVED: #{params[:input]} from #{current_hackr.hackr_alias} ==="

    # Bootstrap + parse + event broadcasts (JSON and Turbo HTML
    # dual-publish) live in the runner, shared with the Hotwire /grid
    # page (Phase 6a).
    result = Grid::CommandRunner.run(current_hackr, params[:input])

    breach_meta = breach_meta_for(current_hackr)

    render json: {
      success: true,
      output: result.output,
      room_id: current_hackr.current_room&.id,
      current_room: current_hackr.current_room ? room_json(current_hackr.current_room) : nil,
      in_breach: breach_meta.present?,
      breach_meta: breach_meta
    }
  end

  private

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

  def breach_meta_for(hackr)
    breach = hackr.active_breach
    return nil unless breach

    protocols = breach.grid_breach_protocols.sort_by(&:position).map do |p|
      {
        position: p.position,
        alive: p.alive?,
        type_label: (p.analyze_level >= 1) ? p.type_label : "???",
        state: p.state
      }
    end

    {
      template_name: breach.grid_breach_template.name,
      tier_label: breach.grid_breach_template.tier_label,
      protocols: protocols,
      detection_level: breach.detection_level,
      pnr_threshold: breach.pnr_threshold,
      actions_remaining: breach.actions_remaining,
      actions_this_round: breach.actions_this_round,
      round_number: breach.round_number
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
