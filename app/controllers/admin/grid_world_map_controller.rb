# frozen_string_literal: true

class Admin::GridWorldMapController < Admin::ApplicationController
  # GET /root/grid_world_map — world overview (all regions + connections)
  def index
    @regions = GridRegion.includes(grid_zones: :grid_rooms).order(:name)

    # Find inter-region connections
    all_exits = GridExit.includes(from_room: {grid_zone: :grid_region}, to_room: {grid_zone: :grid_region}).to_a
    @connections = all_exits
      .select { |e| e.from_room&.grid_zone&.grid_region_id && e.to_room&.grid_zone&.grid_region_id }
      .select { |e| e.from_room.grid_zone.grid_region_id != e.to_room.grid_zone.grid_region_id }
      .map { |e| {from_region: e.from_room.grid_zone.grid_region, to_region: e.to_room.grid_zone.grid_region, from_room: e.from_room, to_room: e.to_room, direction: e.direction} }
      .uniq { |c| [c[:from_region].id, c[:to_region].id].sort }
  end

  # GET /root/grid_world_map/:id — region map (all rooms, zone-colored)
  def show
    @region = GridRegion.find(params[:id])
    @zones = @region.grid_zones.includes(:grid_rooms, :grid_faction).order(:name)
    @z_level = params[:z].to_i

    rooms = @region.grid_rooms.includes(:grid_zone).to_a
    room_ids = rooms.map(&:id)
    exits = GridExit.where(from_room_id: room_ids).includes(to_room: {grid_zone: :grid_region}).to_a

    # Presence
    hackr_counts = GridHackr.where(current_room_id: room_ids).group(:current_room_id).count
    mob_counts = GridMob.where(grid_room_id: room_ids).group(:grid_room_id).count
    presence = rooms.each_with_object({}) do |r, h|
      h[r.id] = {hackrs: hackr_counts[r.id].to_i, mobs: mob_counts[r.id].to_i}
    end

    # Zone color assignment
    @zone_colors = {}
    @zones.each_with_index do |zone, i|
      @zone_colors[zone.id] = Grid::WorldMapBuilder::ZONE_COLORS[i % Grid::WorldMapBuilder::ZONE_COLORS.length]
    end

    # Cross-region room index for edge labels
    cross_room_ids = exits.filter_map { |e| e.to_room_id unless room_ids.include?(e.to_room_id) }.uniq
    cross_rooms = GridRoom.where(id: cross_room_ids).includes(grid_zone: :grid_region).index_by(&:id)

    @map = Grid::WorldMapBuilder.new(
      rooms: rooms, exits: exits, presence: presence,
      zone_colors: @zone_colors, cross_room_index: cross_rooms
    ).build(z_level: @z_level)
  end

  # GET /root/grid_world_map/:id/zone_map?zone_id=N&z=0 — single zone map
  def zone_map
    @region = GridRegion.find(params[:id])
    @zone = @region.grid_zones.find(params[:zone_id])
    @z_level = params[:z].to_i

    rooms = @zone.grid_rooms.includes(:grid_zone).to_a
    room_ids = rooms.map(&:id)
    exits = GridExit.where(from_room_id: room_ids).includes(to_room: {grid_zone: :grid_region}).to_a

    hackr_counts = GridHackr.where(current_room_id: room_ids).group(:current_room_id).count
    mob_counts = GridMob.where(grid_room_id: room_ids).group(:grid_room_id).count
    presence = rooms.each_with_object({}) do |r, h|
      h[r.id] = {hackrs: hackr_counts[r.id].to_i, mobs: mob_counts[r.id].to_i}
    end

    zone_colors = {@zone.id => Grid::WorldMapBuilder::ZONE_COLORS[0]}
    cross_room_ids = exits.filter_map { |e| e.to_room_id unless room_ids.include?(e.to_room_id) }.uniq
    cross_rooms = GridRoom.where(id: cross_room_ids).includes(grid_zone: :grid_region).index_by(&:id)

    @map = Grid::WorldMapBuilder.new(
      rooms: rooms, exits: exits, presence: presence,
      zone_colors: zone_colors, cross_room_index: cross_rooms
    ).build(z_level: @z_level)
  end
end
