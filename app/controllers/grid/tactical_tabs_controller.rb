# Status-panel tab frames for the tactical page (Phase 6b). Each tab is
# a lazy turbo-frame rendering ERB over the same models/services the
# JSON API uses; the frame-refresher bus reloads the visible tab after
# every command (the SPA's dataRefreshToken refetch).
class Grid::TacticalTabsController < Grid::TacticalBaseController
  TABS = %w[deck stats loadout inventory rep cred missions schematics].freeze

  # Inventory display maps, used by the inventory tab partial (moved here
  # from the retired API tab loaders in Phase 7).
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

  # Literal partial paths (Brakeman: never render params-derived paths).
  TAB_PARTIALS = {
    "deck" => "grid/tactical_tabs/deck",
    "stats" => "grid/tactical_tabs/stats",
    "loadout" => "grid/tactical_tabs/loadout",
    "inventory" => "grid/tactical_tabs/inventory",
    "rep" => "grid/tactical_tabs/rep",
    "cred" => "grid/tactical_tabs/cred",
    "missions" => "grid/tactical_tabs/missions",
    "schematics" => "grid/tactical_tabs/schematics"
  }.freeze

  # GET /grid/1337/tabs/:tab
  def show
    @tab = params[:tab]
    return head :not_found unless TABS.include?(@tab)

    send(:"load_#{@tab}")
    render :show, layout: false
  end

  private

  def load_deck
    @deck = current_hackr.equipped_deck
    return unless @deck

    @software = current_hackr.grid_items.where(deck_id: @deck.id, item_type: "software")
      .includes(:grid_item_definition)
    @modules = @deck.installed_modules.includes(:grid_item_definition)
  end

  def load_stats
    @clearance = current_hackr.stat("clearance")
    @xp = current_hackr.stat("xp")
    @max_clearance = @clearance >= GridHackr::Stats::MAX_CLEARANCE
    @xp_to_next = @max_clearance ? nil : GridHackr::Stats.xp_for_clearance(@clearance + 1) - @xp
    @xp_current_floor = GridHackr::Stats.xp_for_clearance(@clearance)
    @xp_next_ceil = @max_clearance ? @xp_current_floor : GridHackr::Stats.xp_for_clearance(@clearance + 1)

    caches = current_hackr.grid_caches.player.to_a
    @default_cache = caches.find(&:is_default?)
    @total_balance = caches.sum(&:balance)
    @debt = current_hackr.stat("govcorp_debt").to_i
    @deck = current_hackr.equipped_deck
    @equipped_count = current_hackr.grid_items.equipped_by(current_hackr).count

    earned_ids = current_hackr.grid_hackr_achievements.pluck(:grid_achievement_id).to_set
    visible = Grid::AchievementChecker.all_achievements_cached.reject { |a| a.hidden && !earned_ids.include?(a.id) }
    @achievements_earned = visible.count { |a| earned_ids.include?(a.id) }
    @achievements_total = visible.size
    checker = Grid::AchievementChecker.new(current_hackr)
    @achievements_in_progress = visible.filter_map { |a|
      next if earned_ids.include?(a.id)
      prog = checker.progress(a)
      next unless prog && prog[:target] && prog[:target] > 0 && prog[:current] > 0
      {name: a.name, badge_icon: a.badge_icon, current: prog[:current], target: prog[:target]}
    }

    @standings_summary = Grid::ReputationService.new(current_hackr).faction_standings
  end

  def load_loadout
    @loadout = current_hackr.loadout_by_slot
    @effects = current_hackr.loadout_effects.reject { |_, v| v == 0 || v == false }
  end

  def load_inventory
    @items = current_hackr.grid_items.in_inventory(current_hackr)
      .includes(:grid_item_definition).to_a
    @grouped = @items.group_by(&:item_type)
    vendor_mob = current_hackr.current_room&.grid_mobs&.find_by(mob_type: "vendor")
    @vendor_listings_by_def = if vendor_mob
      vendor_mob.grid_shop_listings.includes(:grid_item_definition)
        .index_by(&:grid_item_definition_id)
    end
  end

  def load_rep
    service = Grid::ReputationService.new(current_hackr)
    standings = service.faction_standings(include_zero: true)

    # Parent→child tree walk — same ordering as the JSON reputation_index.
    children_by_parent = standings.group_by { |s| s[:faction].parent_id }
    standing_ids = standings.map { |s| s[:faction].id }.to_set
    roots = standings.select { |s| s[:faction].parent_id.nil? || !standing_ids.include?(s[:faction].parent_id) }

    @standings = []
    visited = Set.new
    walk = lambda do |standing, depth|
      fid = standing[:faction].id
      next if visited.include?(fid)
      visited << fid
      @standings << {standing: standing, depth: depth}
      (children_by_parent[fid] || []).each { |child| walk.call(child, depth + 1) }
    end
    roots.each { |s| walk.call(s, 0) }
  end

  def load_cred
    @caches = current_hackr.grid_caches.player.order(:created_at)
    @debt = current_hackr.stat("govcorp_debt").to_i
  end

  def load_missions
    service = Grid::MissionService.new(current_hackr)
    @active = service.active_hackr_missions.to_a
    @completed = service.completed_hackr_missions(limit: 20).to_a
  end

  def load_schematics
    @schematics = GridSchematic.published.non_tutorial.ordered
      .includes(:output_definition, ingredients: :input_definition)
    @inventory_qtys = current_hackr.grid_items
      .group(:grid_item_definition_id)
      .sum(:quantity)
    @completed_mission_slugs = current_hackr.grid_hackr_missions
      .where(status: "completed")
      .joins(:grid_mission)
      .pluck("grid_missions.slug").to_set
    @earned_achievement_slugs = current_hackr.grid_hackr_achievements
      .joins(:grid_achievement)
      .pluck("grid_achievements.slug").to_set
  end
end
