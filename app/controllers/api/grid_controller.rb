class Api::GridController < ApplicationController
  include GridAuthentication
  include GridSerialization

  before_action :require_login_api, only: %i[current_hackr_info command disconnect request_password_reset request_email_change debit achievements_index missions_index schematics_index loadout_index deck_index transit_index zone_map inventory_index reputation_index cred_index shop_index]
  before_action -> { require_feature_api(FeatureGrant::PULSE_GRID) }, only: [:command]
  before_action -> { require_feature_api(FeatureGrant::TACTICAL_GRID) }, only: %i[zone_map shop_index]
  before_action :require_admin_api, only: [:debit]

  INVENTORY_TYPE_ORDER = %w[gear consumable tool software module firmware material data rig_component fixture collectible faction].freeze
  INVENTORY_TYPE_LABELS = {
    "gear" => "GEAR", "consumable" => "CONSUMABLES", "tool" => "TOOLS",
    "software" => "SOFTWARE", "module" => "MODULES", "firmware" => "FIRMWARE",
    "material" => "MATERIALS", "data" => "DATA", "rig_component" => "RIG COMPONENTS",
    "fixture" => "FIXTURES", "collectible" => "COLLECTIBLES", "faction" => "FACTION"
  }.freeze
  INVENTORY_ITEM_ACTIONS = {
    "gear" => %w[equip use drop salvage], "consumable" => %w[use drop salvage],
    "tool" => %w[use drop salvage], "fixture" => %w[place salvage],
    "software" => %w[use drop salvage], "firmware" => %w[use drop salvage],
    "module" => %w[use drop salvage], "material" => %w[use drop salvage],
    "data" => %w[use drop salvage], "rig_component" => %w[use drop salvage],
    "collectible" => %w[use drop salvage], "faction" => %w[use drop]
  }.freeze

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
    schematics = GridSchematic.published.non_tutorial.ordered
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
            description: s.output_definition.description,
            item_type: s.output_definition.item_type,
            rarity: s.output_definition.rarity,
            rarity_color: s.output_definition.rarity_color,
            rarity_label: s.output_definition.rarity_label,
            max_stack: s.output_definition.max_stack,
            properties: s.output_definition.properties
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
      clearance: current_hackr.stat("clearance"),
      vitals: {
        health: {current: current_hackr.stat("health"), max: current_hackr.effective_max("health")},
        energy: {current: current_hackr.stat("energy"), max: current_hackr.effective_max("energy")},
        psyche: {current: current_hackr.stat("psyche"), max: current_hackr.effective_max("psyche")}
      }
    }
  end

  # GET /api/grid/inventory - Inventory items grouped by type with available actions
  def inventory_index
    items = current_hackr.grid_items.in_inventory(current_hackr)
      .includes(:grid_item_definition).to_a

    grouped = items.group_by(&:item_type)
    vendor_mob = current_hackr.current_room&.grid_mobs&.find_by(mob_type: "vendor")
    vendor_listings_by_def = if vendor_mob
      vendor_mob.grid_shop_listings.includes(:grid_item_definition)
        .index_by(&:grid_item_definition_id)
    end

    render json: {
      capacity: {used: items.size, max: current_hackr.inventory_capacity},
      groups: INVENTORY_TYPE_ORDER.filter_map { |type|
        type_items = grouped[type]
        next unless type_items&.any?
        {
          item_type: type,
          label: INVENTORY_TYPE_LABELS[type] || type.upcase,
          items: type_items
            .sort_by { |i| [-(GridItem::RARITIES.index(i.rarity) || 0), i.name.to_s] }
            .map { |i| inventory_item_json(i, vendor_listings_by_def: vendor_listings_by_def) }
        }
      }
    }
  end

  # GET /api/grid/shop - Vendor shop listings for current room
  def shop_index
    room = current_hackr.current_room
    vendor = room&.grid_mobs&.find_by(mob_type: "vendor")
    return render(json: {error: "No vendor here"}, status: :not_found) unless vendor

    listings = Grid::ShopService.listing_display(mob: vendor, hackr: current_hackr)

    balance = current_hackr.default_cache&.balance || 0

    render json: {
      vendor_name: vendor.name,
      shop_type: vendor.shop_type,
      balance: balance,
      listings: listings.map { |entry|
        listing = entry[:listing]
        {
          id: listing.id,
          name: listing.name,
          description: listing.description,
          item_type: listing.item_type,
          rarity: listing.rarity,
          rarity_color: listing.rarity_color,
          rarity_label: listing.rarity_label,
          price: entry[:effective_price],
          affordable: entry[:affordable],
          out_of_stock: entry[:out_of_stock],
          stock: listing.unlimited_stock? ? nil : listing.stock
        }
      }
    }
  end

  # GET /api/grid/reputation - Faction standings with parent→child hierarchy
  def reputation_index
    service = Grid::ReputationService.new(current_hackr)
    standings = service.faction_standings(include_zero: true)

    # Walk parent→child hierarchy — same tree logic as rep_command
    children_by_parent = standings.group_by { |s| s[:faction].parent_id }
    standing_ids = standings.map { |s| s[:faction].id }.to_set
    roots = standings.select { |s| s[:faction].parent_id.nil? || !standing_ids.include?(s[:faction].parent_id) }

    ordered = []
    visited = Set.new
    walk = lambda do |standing, depth|
      fid = standing[:faction].id
      return if visited.include?(fid)
      visited << fid
      ordered << {standing: standing, depth: depth}
      (children_by_parent[fid] || []).each { |child| walk.call(child, depth + 1) }
    end
    roots.each { |s| walk.call(s, 0) }

    render json: {
      standings: ordered.map { |entry|
        s = entry[:standing]
        {
          faction_name: s[:faction].display_name,
          faction_slug: s[:faction].slug,
          effective: s[:effective],
          tier_key: s[:tier][:key],
          tier_label: s[:tier][:label],
          tier_color: s[:tier][:color],
          next_tier_label: s[:next_tier]&.dig(:label),
          next_tier_diff: s[:next_tier] ? (s[:next_tier][:min] - s[:effective]) : nil,
          aggregate: s[:aggregate],
          depth: entry[:depth]
        }
      }
    }
  end

  # GET /api/grid/cred - CRED/cache data for the tactical CRED tab
  def cred_index
    caches = current_hackr.grid_caches.player.order(:created_at)
    debt = current_hackr.stat("govcorp_debt").to_i

    render json: {
      caches: caches.map { |c|
        {
          address: c.address,
          nickname: c.nickname,
          balance: c.balance,
          is_default: c.is_default?,
          abandoned: c.abandoned?
        }
      },
      total_balance: caches.sum(&:balance),
      debt: debt
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

    modules = deck.installed_modules.includes(:grid_item_definition)

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
      modules: modules.map { |m|
        {
          id: m.id,
          name: m.name,
          rarity_color: m.rarity_color,
          description: m.description,
          firmware: m.properties&.dig("firmware_name")
        }
      },
      inventory_software: inventory_sw.map { |s| software_item_json(s) }
    }
  end

  # GET /api/grid/transit - Transit map and route browser data
  def transit_index
    room = current_hackr.current_room
    region = room&.grid_zone&.grid_region

    active_journey = current_hackr.active_journey

    local_routes = if region
      Grid::LocalTransitService.routes_at_room(room: room, hackr: current_hackr)
    else
      []
    end

    slip_routes = if region
      Grid::SlipstreamService.routes_from(region: region, hackr: current_hackr)
    else
      GridSlipstreamRoute.none
    end

    # Derive region transit types from actual routes — lightweight query,
    # only fetches distinct (region, type) pairs instead of full route objects.
    region_type_pairs = GridTransitRoute.active
      .joins(:grid_transit_type, :grid_region)
      .select("grid_regions.slug AS region_slug, grid_transit_types.slug AS type_slug, grid_transit_types.name AS type_name, grid_transit_types.category AS type_category, grid_transit_types.position AS type_position")
      .distinct
    region_transit = region_type_pairs
      .group_by(&:region_slug)
      .transform_values { |rows|
        rows.sort_by(&:type_position)
          .map { |r| {slug: r.type_slug, name: r.type_name, category: r.type_category} }
      }

    render json: {
      slipstream_heat: current_hackr.slipstream_heat,
      slipstream_heat_tier: current_hackr.slipstream_heat_tier,
      current_region: region ? {slug: region.slug, name: region.name} : nil,
      current_journey: active_journey ? transit_journey_json(active_journey) : nil,
      local_routes: local_routes.map { |r| transit_route_json(r) },
      slipstream_routes: slip_routes.map { |r| slipstream_route_json(r) },
      region_transit: region_transit
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

      # Start tutorial for hackrs who haven't seen it (e.g., seeded accounts)
      if hackr.stat("tutorial_active").nil? && hackr.stat("tutorial_completed").nil?
        tutorial = Grid::TutorialService.new(hackr)
        tutorial.start!
        # Move to Bootloader hub (start! doesn't move — only sets state)
        hub = tutorial.tutorial_hub_room
        hackr.update!(current_room: hub) if hub
        # Remove den chip if provisioned before tutorial was set up.
        # Skip if hackr already has a den (chip was already used).
        unless hackr.den.present?
          hackr.grid_items.joins(:grid_item_definition)
            .where(grid_item_definitions: {slug: "den-access-chip"}).destroy_all
        end
      end

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
        Grid::TutorialService.new(@hackr).start!
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

  # GET /api/grid/zone_map - Zone map data for the tactical UI
  def zone_map
    room = current_hackr.current_room
    unless room
      return render json: {error: "No current room."}, status: :unprocessable_entity
    end

    result = Grid::ZoneMapBuilder.new(zone: room.grid_zone, hackr: current_hackr).build

    # Breach encounters available in current room (clearance-filtered)
    encounters = Grid::BreachService.available_encounters(room: room, hackr: current_hackr)
    breach_encounters = encounters.map do |enc|
      {id: enc.id, name: enc.name, tier_label: enc.tier_label, min_clearance: enc.min_clearance}
    end

    # DECK status for pre-checking breach eligibility
    deck = current_hackr.equipped_deck
    deck_status = {
      equipped: deck.present?,
      fried: deck.present? && deck.deck_fried?
    }

    render json: {
      zone: result.zone,
      current_room_id: result.current_room_id,
      rooms: result.rooms,
      exits: result.exits,
      ghost_rooms: result.ghost_rooms,
      z_levels: result.z_levels,
      z_level: result.z_level,
      in_breach: current_hackr.in_breach?,
      breach_encounters: breach_encounters,
      deck_status: deck_status,
      has_vendor: room.grid_mobs.loaded? ? room.grid_mobs.any?(&:vendor?) : room.grid_mobs.exists?(mob_type: "vendor")
    }
  end

  # POST /api/grid/command - Execute game command
  def command
    Rails.logger.info "=== API COMMAND RECEIVED: #{params[:input]} from #{current_hackr.hackr_alias} ==="

    # Ensure hackr has a room (handles stale sessions after DB reset)
    current_hackr.ensure_current_room!

    # Start tutorial for hackrs who haven't seen it (handles stale sessions)
    if current_hackr.stat("tutorial_active").nil? && current_hackr.stat("tutorial_completed").nil?
      tutorial = Grid::TutorialService.new(current_hackr)
      tutorial.start!
      hub = tutorial.tutorial_hub_room
      current_hackr.update!(current_room: hub) if hub
      unless current_hackr.den.present?
        current_hackr.grid_items.joins(:grid_item_definition)
          .where(grid_item_definitions: {slug: "den-access-chip"}).destroy_all
      end
    end

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
        # Zone-level presence broadcast for tactical map
        broadcast_zone_presence(event)
      when "say", "take", "drop"
        # Broadcast to current room
        Rails.logger.info "=== Broadcasting #{event[:type]} to room #{current_hackr.current_room&.id} ==="
        broadcast_event(current_hackr.current_room, event)
      end
    end

    # Reload hackr to get updated current_room
    current_hackr.reload

    breach_meta = breach_meta_for(current_hackr)

    render json: {
      success: true,
      output: output,
      room_id: current_hackr.current_room&.id,
      current_room: current_hackr.current_room ? room_json(current_hackr.current_room) : nil,
      in_breach: breach_meta.present?,
      breach_meta: breach_meta
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

  def broadcast_zone_presence(event)
    from_room = GridRoom.find_by(id: event[:from_room_id])
    to_room = GridRoom.find_by(id: event[:to_room_id])

    zone_ids = [from_room&.grid_zone_id, to_room&.grid_zone_id].compact.uniq
    presence_event = event.merge(type: "presence_update")

    zone_ids.each do |zone_id|
      ActionCable.server.broadcast(ZoneChannel.stream_name_for(zone_id), presence_event)
    end
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

  def inventory_item_json(item, vendor_listings_by_def: nil)
    actions = (INVENTORY_ITEM_ACTIONS[item.item_type] || %w[drop]).dup
    actions.delete("salvage") if item.unicorn?

    result = {
      id: item.id,
      name: item.name,
      description: item.description,
      item_type: item.item_type,
      rarity: item.rarity,
      rarity_color: item.rarity_color,
      rarity_label: item.rarity_label,
      quantity: item.quantity,
      max_stack: item.grid_item_definition&.max_stack,
      definition_slug: item.grid_item_definition&.slug,
      properties: item.properties || {},
      actions: actions
    }

    if vendor_listings_by_def && !item.unicorn? && item.value.to_i > 0
      result[:sell_price] = sell_price_for(item, vendor_listings_by_def)
    end

    result
  end

  def sell_price_for(item, vendor_listings_by_def)
    listing = vendor_listings_by_def[item.grid_item_definition_id]
    price = if listing
      listing.sell_price
    else
      (item.value * Grid::EconomyConfig::SELL_PRICE_RATIO).ceil
    end
    [price, 1].max
  end

  def transit_journey_json(journey)
    {
      id: journey.id,
      journey_type: journey.journey_type,
      state: journey.state,
      legs_completed: journey.legs_completed,
      total_legs: journey.total_legs,
      pending_fork: journey.pending_fork,
      breach_mid_journey: journey.breach_mid_journey,
      started_at: journey.started_at&.iso8601,
      route_name: journey.slipstream? ? journey.grid_slipstream_route&.name : journey.grid_transit_route&.name,
      current_stop: journey.current_stop ? {position: journey.current_stop.position, name: journey.current_stop.display_name} : nil,
      current_leg: journey.current_leg ? {position: journey.current_leg.position, name: journey.current_leg.name} : nil
    }
  end

  def transit_route_json(route)
    {
      slug: route.slug,
      name: route.name,
      transit_type: {slug: route.grid_transit_type.slug, name: route.grid_transit_type.name, category: route.grid_transit_type.category, base_fare: route.grid_transit_type.base_fare, icon_key: route.grid_transit_type.icon_key},
      region: {slug: route.grid_region.slug, name: route.grid_region.name},
      loop_route: route.loop_route,
      stop_count: route.grid_transit_stops.size,
      stops: route.grid_transit_stops.map { |s| {position: s.position, name: s.display_name, room_slug: s.grid_room.slug, is_terminus: s.is_terminus} }
    }
  end

  def slipstream_route_json(route)
    {
      slug: route.slug,
      name: route.name,
      origin_region: {slug: route.origin_region.slug, name: route.origin_region.name},
      destination_region: {slug: route.destination_region.slug, name: route.destination_region.name},
      min_clearance: route.min_clearance,
      leg_count: route.grid_slipstream_legs.size,
      legs: route.grid_slipstream_legs.map { |l| {position: l.position, name: l.name, has_forks: l.has_forks?} }
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
        room_name: mission.giver_mob.grid_room&.name,
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
