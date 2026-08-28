# Grid meta pages (Hotwire migration Phase 6e) — ports the last six SPA
# pages: achievements, missions, schematics, loadout, deck, transit. All
# read-only browsers over the same data the JSON API serves; mutations
# stay terminal commands (the pages only hint them, like the SPA).
class Grid::MetaController < ApplicationController
  before_action :require_login
  before_action :require_pulse_grid

  # GET /achievements
  def achievements
    earned_map = current_hackr.grid_hackr_achievements
      .pluck(:grid_achievement_id, :awarded_at).to_h
    checker = Grid::AchievementChecker.new(current_hackr)

    @summary = Hash.new { |h, k| h[k] = {total: 0, earned: 0} }
    @categories = Hash.new { |h, k| h[k] = [] }
    Grid::AchievementChecker.all_achievements_cached.each do |a|
      earned = earned_map.key?(a.id)
      next if a.hidden && !earned

      @summary[a.category][:total] += 1
      @summary[a.category][:earned] += 1 if earned
      @categories[a.category] << {
        achievement: a, earned: earned,
        awarded_at: earned_map[a.id],
        progress: earned ? nil : checker.progress(a)
      }
    end
    @total = {
      total: @summary.values.sum { |s| s[:total] },
      earned: @summary.values.sum { |s| s[:earned] }
    }
  end

  # GET /missions
  def missions
    service = Grid::MissionService.new(current_hackr)
    @active = service.active_hackr_missions.to_a
    @completed = service.completed_hackr_missions(limit: 20).to_a
    @available = service.available_missions(current_hackr.current_room).to_a
    @gate_statuses = @available.index_with { |m| service.gate_status(m) }
  end

  # GET /schematics
  def schematics
    @schematics = GridSchematic.published.non_tutorial.ordered
      .includes(:output_definition, ingredients: :input_definition)
    @inventory_qtys = current_hackr.grid_items
      .group(:grid_item_definition_id).sum(:quantity)
    @completed_mission_slugs = current_hackr.grid_hackr_missions
      .where(status: "completed").joins(:grid_mission)
      .pluck("grid_missions.slug").to_set
    @earned_achievement_slugs = current_hackr.grid_hackr_achievements
      .joins(:grid_achievement).pluck("grid_achievements.slug").to_set
  end

  # GET /loadout
  def loadout
    @loadout = current_hackr.loadout_by_slot
    @effects = current_hackr.loadout_effects.reject { |_, v| v == 0 || v == false }
    @inventory_gear = current_hackr.grid_items.in_inventory(current_hackr)
      .where(item_type: "gear").includes(:grid_item_definition)
  end

  # GET /deck
  def deck
    @deck = current_hackr.equipped_deck
    return unless @deck

    @software = current_hackr.grid_items.where(deck_id: @deck.id, item_type: "software")
      .includes(:grid_item_definition)
    @modules = @deck.installed_modules.includes(:grid_item_definition)
    @inventory_software = current_hackr.grid_items.in_inventory(current_hackr)
      .where(item_type: "software").includes(:grid_item_definition)
  end

  # GET /transit
  def transit
    room = current_hackr.current_room
    @region = room&.grid_zone&.grid_region
    @heat = current_hackr.slipstream_heat
    @heat_tier = current_hackr.slipstream_heat_tier
    @local_routes = @region ? Grid::LocalTransitService.routes_at_room(room: room, hackr: current_hackr) : []
    @slip_routes = @region ? Grid::SlipstreamService.routes_from(region: @region, hackr: current_hackr).to_a : []

    # Grid-wide transit-type availability by region (region network tab).
    region_type_pairs = GridTransitRoute.active
      .joins(:grid_transit_type, :grid_region)
      .select("grid_regions.slug AS region_slug, grid_regions.name AS region_name, grid_transit_types.slug AS type_slug, grid_transit_types.name AS type_name, grid_transit_types.category AS type_category, grid_transit_types.position AS type_position")
      .distinct
    @region_transit = region_type_pairs
      .group_by { |r| [r.region_slug, r.region_name] }
      .transform_values { |rows| rows.sort_by(&:type_position) }
  end

  private

  def require_pulse_grid
    return if current_hackr.has_feature?(FeatureGrant::PULSE_GRID)

    render "grid/game/coming_soon"
  end
end
