class Api::GridController < ApplicationController
  include GridAuthentication
  include GridSerialization

  before_action :require_login_api, only: %i[current_hackr_info command disconnect request_password_reset request_email_change debit achievements_index missions_index schematics_index loadout_index deck_index]
  before_action -> { require_feature_api(FeatureGrant::PULSE_GRID) }, only: [:command]
  before_action :require_admin_api, only: [:debit]

  # GET /api/grid/achievements - All visible achievements grouped by
  # category, with earned status, awarded_at, and live progress for
  # cumulative triggers. Hidden achievements appear only if earned.
  def achievements_index
    earned_map = current_hackr.grid_hackr_achievements
      .pluck(:grid_achievement_id, :awarded_at)
      .to_h

    checker = Grid::AchievementChecker.new(current_hackr)
    achievements = GridAchievement.order(:category, :name).to_a

    categories = Hash.new { |h, k| h[k] = [] }
    summary = Hash.new { |h, k| h[k] = {total: 0, earned: 0} }

    achievements.each do |a|
      earned = earned_map.key?(a.id)

      # Hidden achievements hide from the list until earned.
      next if a.hidden && !earned

      summary[a.category][:total] += 1
      summary[a.category][:earned] += 1 if earned

      categories[a.category] << {
        slug: a.slug,
        name: a.name,
        description: a.description,
        badge_icon: a.badge_icon,
        category: a.category,
        trigger_type: a.trigger_type,
        xp_reward: a.xp_reward,
        cred_reward: a.cred_reward,
        earned: earned,
        awarded_at: earned_map[a.id]&.iso8601,
        progress: checker.progress(a)
      }
    end

    total_summary = {
      total: summary.values.sum { |s| s[:total] },
      earned: summary.values.sum { |s| s[:earned] }
    }

    render json: {
      categories: categories,
      summary: {by_category: summary, total: total_summary}
    }
  end

  # GET /api/grid/missions - Active + completed + available-in-current-room missions.
  def missions_index
    service = Grid::MissionService.new(current_hackr)

    active = service.active_hackr_missions.to_a
    completed = service.completed_hackr_missions(limit: 20).to_a
    available = service.available_missions(current_hackr.current_room).to_a

    render json: {
      active: active.map { |hm| hackr_mission_json(hm, include_progress: true) },
      completed: completed.map { |hm| hackr_mission_json(hm, include_progress: false) },
      available: available.map { |m| mission_json(m, include_gate_status: true) }
    }
  end

  # GET /api/grid/schematics - Published schematics with ingredients,
  # craftable status, and per-ingredient ownership for the current hackr.
  def schematics_index
    schematics = GridSchematic.published.ordered
      .includes(:output_definition, ingredients: :input_definition)

    # Pre-load hackr state to avoid N+1 on craftable_by? checks
    inventory_qtys = current_hackr.grid_items
      .group(:grid_item_definition_id)
      .sum(:quantity)
    completed_mission_slugs = current_hackr.grid_hackr_missions
      .where(status: "completed")
      .joins(:grid_mission)
      .pluck("grid_missions.slug").to_set
    earned_achievement_slugs = current_hackr.grid_hackr_achievements
      .joins(:grid_achievement)
      .pluck("grid_achievements.slug").to_set

    current_room = current_hackr.current_room

    render json: {
      schematics: schematics.map { |s|
        craftable = s.craftable_by?(current_hackr,
          completed_mission_slugs: completed_mission_slugs,
          earned_achievement_slugs: earned_achievement_slugs,
          current_room: current_room)
        has_ingredients = s.ingredients.all? { |i| (inventory_qtys[i.input_definition_id] || 0) >= i.quantity }

        {
          slug: s.slug,
          name: s.name,
          description: s.description,
          output: {
            slug: s.output_definition.slug,
            name: s.output_definition.name,
            rarity: s.output_definition.rarity,
            rarity_color: s.output_definition.rarity_color
          },
          output_quantity: s.output_quantity,
          xp_reward: s.xp_reward,
          required_clearance: s.required_clearance,
          required_mission_slug: s.required_mission_slug,
          required_achievement_slug: s.required_achievement_slug,
          required_room_type: s.required_room_type,
          required_room_type_label: s.room_type_label,
          ingredients: s.ingredients.ordered.map { |i|
            owned = inventory_qtys[i.input_definition_id] || 0
            {
              item_slug: i.input_definition.slug,
              item_name: i.input_definition.name,
              rarity: i.input_definition.rarity,
              rarity_color: i.input_definition.rarity_color,
              required: i.quantity,
              owned: owned
            }
          },
          craftable: craftable,
          has_ingredients: has_ingredients
        }
      }
    }
  end

  # GET /api/grid/loadout - Loadout data for the SPA page
  def loadout_index
    loadout = current_hackr.loadout_by_slot
    effects = current_hackr.loadout_effects

    inventory_gear = current_hackr.grid_items
      .in_inventory(current_hackr)
      .where(item_type: "gear")
      .includes(:grid_item_definition)

    render json: {
      slots: GridItem::GEAR_SLOTS.map { |slot|
        item = loadout[slot]
        {
          slot: slot,
          label: GridHackr::Loadout::GEAR_SLOT_LABELS[slot],
          item: item ? loadout_item_json(item) : nil
        }
      },
      inventory_gear: inventory_gear.map { |item| loadout_item_json(item) },
      active_effects: effects.reject { |_, v| v == 0 || v == false },
      vitals: {
        health: {current: current_hackr.stat("health"), max: current_hackr.effective_max("health")},
        energy: {current: current_hackr.stat("energy"), max: current_hackr.effective_max("energy")},
        psyche: {current: current_hackr.stat("psyche"), max: current_hackr.effective_max("psyche")}
      }
    }
  end

  # GET /api/grid/deck - DECK status for the /deck SPA page
  def deck_index
    deck = current_hackr.equipped_deck

    unless deck
      return render json: {deck: nil, software: [], inventory_software: []}
    end

    loaded = current_hackr.grid_items.where(deck_id: deck.id, item_type: "software")
      .includes(:grid_item_definition)
    inventory_sw = current_hackr.grid_items.in_inventory(current_hackr)
      .where(item_type: "software").includes(:grid_item_definition)

    render json: {
      deck: {
        id: deck.id,
        name: deck.name,
        rarity: deck.rarity,
        rarity_color: deck.rarity_color,
        rarity_label: deck.rarity_label,
        battery_current: deck.deck_battery,
        battery_max: deck.deck_battery_max,
        slot_count: deck.deck_slot_count,
        slots_used: deck.deck_slots_used,
        module_slot_count: deck.deck_module_slot_count,
        modules_used: deck.deck_modules_used
      },
      software: loaded.map { |s| software_item_json(s) },
      inventory_software: inventory_sw.map { |s| software_item_json(s) }
    }
  end

  # GET /api/grid/current_hackr - Get current logged-in hackr info
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

      hackr.ensure_current_room!
      log_in(hackr)
      hackr.touch_activity!
      Grid::AchievementSweepJob.perform_later(hackr.id)
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
    @hackr.registration_ip = request.remote_ip

    ActiveRecord::Base.transaction do
      if @hackr.save
        @hackr.ensure_current_room!
        token.mark_used!
        @hackr.provision_economy!
        log_in(@hackr)
        @hackr.touch_activity!
        Rails.logger.info("[AUTH] Registration completed: hackr_alias=#{@hackr.hackr_alias} email=#{token.email} ip=#{request.remote_ip}")
        render json: {
          success: true,
          message: "Welcome to THE PULSE GRID, #{@hackr.hackr_alias}. Your journey with the Fracture Network begins now.",
          hackr: auth_hackr_json(@hackr)
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

  def loadout_item_json(item)
    {
      id: item.id,
      name: item.name,
      rarity: item.rarity,
      rarity_color: item.rarity_color,
      rarity_label: item.rarity_label,
      description: item.description,
      gear_slot: item.gear_slot,
      gear_slot_label: GridHackr::Loadout::GEAR_SLOT_LABELS[item.gear_slot] || item.gear_slot&.upcase,
      equipped_slot: item.equipped_slot,
      effects: item.gear_effects,
      required_clearance: item.required_clearance
    }
  end

  def software_item_json(item)
    props = item.properties || {}
    {
      id: item.id,
      name: item.name,
      rarity: item.rarity,
      rarity_color: item.rarity_color,
      rarity_label: item.rarity_label,
      description: item.description,
      software_category: props["software_category"],
      slot_cost: (props["slot_cost"] || 1).to_i,
      battery_cost: (props["battery_cost"] || 0).to_i,
      effect_type: props["effect_type"],
      effect_magnitude: (props["effect_magnitude"] || 0).to_i,
      target_types: props["target_types"],
      level: (props["level"] || 1).to_i,
      loaded: item.deck_id.present?
    }
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

  # --- Mission JSON helpers ---

  def mission_json(mission, include_gate_status: false)
    data = {
      slug: mission.slug,
      name: mission.name,
      description: mission.description,
      repeatable: mission.repeatable,
      arc: mission.grid_mission_arc ? {slug: mission.grid_mission_arc.slug, name: mission.grid_mission_arc.name} : nil,
      giver: mission.giver_mob ? {
        name: mission.giver_mob.name,
        room_id: mission.giver_mob.grid_room_id,
        room_slug: mission.giver_mob.grid_room&.slug
      } : nil,
      prereq_slug: mission.prereq_mission&.slug,
      min_clearance: mission.min_clearance,
      min_rep: mission.min_rep_faction ? {faction_slug: mission.min_rep_faction.slug, value: mission.min_rep_value} : nil,
      objectives: mission.grid_mission_objectives.map { |o|
        {
          id: o.id,
          position: o.position,
          objective_type: o.objective_type,
          label: o.label,
          target_slug: o.target_slug,
          target_count: o.target_count
        }
      },
      rewards: mission.grid_mission_rewards.map { |r|
        {
          id: r.id,
          reward_type: r.reward_type,
          amount: r.amount,
          target_slug: r.target_slug,
          quantity: r.quantity
        }
      }
    }

    if include_gate_status
      status = mission_service.gate_status(mission)
      data[:gates] = {
        clearance_met: status.clearance_met,
        prereq_met: status.prereq_met,
        rep_met: status.rep_met
      }
    end

    data
  end

  # Memoized per-request. Reuses one MissionService instance across all
  # mission_json calls in a serializer loop so ReputationService preload
  # + completed_mission_ids don't re-query per row.
  def mission_service
    @mission_service ||= Grid::MissionService.new(current_hackr)
  end

  def hackr_mission_json(hackr_mission, include_progress: true)
    mission = hackr_mission.grid_mission
    base = {
      id: hackr_mission.id,
      status: hackr_mission.status,
      accepted_at: hackr_mission.accepted_at&.iso8601,
      completed_at: hackr_mission.completed_at&.iso8601,
      turn_in_count: hackr_mission.turn_in_count,
      mission: mission_json(mission)
    }

    if include_progress
      progress_by_obj = hackr_mission.grid_hackr_mission_objectives.index_by(&:grid_mission_objective_id)
      base[:objective_progress] = mission.grid_mission_objectives.map do |obj|
        hobj = progress_by_obj[obj.id]
        {
          objective_id: obj.id,
          progress: hobj&.progress.to_i,
          target_count: obj.target_count,
          completed: hobj&.completed_at.present?
        }
      end
      base[:ready_to_turn_in] = hackr_mission.all_objectives_completed?
    end

    base
  end
end
