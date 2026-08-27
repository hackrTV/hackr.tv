# Slide-in panel frames for the tactical page (Phase 6b): vendor,
# transit, npc, rest_pod. Each renders ERB over the same services the
# JSON API used; every action inside is a form posting the exact command
# string the React panel composed, through the shared command bus.
class Grid::TacticalPanelsController < Grid::TacticalBaseController
  PANELS = %w[vendor transit npc rest_pod].freeze

  # Literal partial paths (Brakeman: never render params-derived paths).
  PANEL_PARTIALS = {
    "vendor" => "grid/tactical_panels/vendor",
    "transit" => "grid/tactical_panels/transit",
    "npc" => "grid/tactical_panels/npc",
    "rest_pod" => "grid/tactical_panels/rest_pod"
  }.freeze

  # GET /grid/1337/panels/:panel
  def show
    @panel = params[:panel]
    return head :not_found unless PANELS.include?(@panel)

    send(:"load_#{@panel}")
    render :show, layout: false
  end

  private

  def load_vendor
    room = current_hackr.current_room
    @vendor = room&.grid_mobs&.find_by(mob_type: "vendor")
    return unless @vendor

    @listings = Grid::ShopService.listing_display(mob: @vendor, hackr: current_hackr)
    @balance = current_hackr.default_cache&.balance || 0
    load_sellable_inventory
  end

  def load_sellable_inventory
    items = current_hackr.grid_items.in_inventory(current_hackr)
      .includes(:grid_item_definition).to_a
    listings_by_def = @vendor.grid_shop_listings.includes(:grid_item_definition)
      .index_by(&:grid_item_definition_id)
    @sellable = items.filter_map { |item|
      next if item.unicorn? || item.value.to_i <= 0
      price = Grid::ShopService.sell_price_for(item: item, listing: listings_by_def[item.grid_item_definition_id])
      next unless price.to_i > 0
      {item: item, price: price}
    }
  end

  def load_transit
    room = current_hackr.current_room
    region = room&.grid_zone&.grid_region
    @journey = current_hackr.active_journey
    @heat = current_hackr.slipstream_heat
    @heat_tier = current_hackr.slipstream_heat_tier
    @region = region
    @local_routes = region ? Grid::LocalTransitService.routes_at_room(room: room, hackr: current_hackr) : []
    @slip_routes = region ? Grid::SlipstreamService.routes_from(region: region, hackr: current_hackr).to_a : []
    @private_types = Grid::LocalTransitService.private_types_at_room(room: room, hackr: current_hackr)
    @private_destinations = @private_types.any? ? Grid::LocalTransitService.private_destinations(room: room) : []
  end

  def load_npc
    room = current_hackr.current_room
    @mob = room&.grid_mobs&.find_by(id: params[:mob_id])
    return unless @mob

    @navigator = Grid::DialogueNavigator.new(hackr: current_hackr, mob: @mob)
    service = Grid::MissionService.new(current_hackr)
    @available_missions = GridMission.published.where(giver_mob_id: @mob.id)
      .select { |m| !service.already_active?(m) && !service.completed_nonrepeatable?(m) }
    @active_missions = current_hackr.grid_hackr_missions.active
      .joins(:grid_mission).where(grid_missions: {giver_mob_id: @mob.id})
      .includes(grid_mission: :grid_mission_objectives)
    @mission_service = service
    @inventory_by_name = current_hackr.grid_items.in_inventory(current_hackr)
      .group(:name).sum(:quantity)
  end

  def load_rest_pod
    room = current_hackr.current_room
    @available = room&.room_type == "rest_pod"
    return unless @available

    @rate = Grid::RestPodService.rate_for(current_hackr)
    @balance = current_hackr.default_cache&.balance || 0
  end
end
