# frozen_string_literal: true

class Admin::GridMapEditorController < Admin::ApplicationController
  OPPOSITE_DIRECTIONS = {
    "north" => "south", "south" => "north",
    "east" => "west", "west" => "east",
    "northeast" => "southwest", "southwest" => "northeast",
    "northwest" => "southeast", "southeast" => "northwest",
    "up" => "down", "down" => "up"
  }.freeze

  # GET /root/grid_map_editor/:zone_id
  def show
    @zone = GridZone.find(params[:zone_id])
    @region = @zone.grid_region
    @scope = "zone"
  end

  # GET /root/grid_map_editor/region/:region_id
  def region_show
    @region = GridRegion.find(params[:region_id])
    @scope = "region"
    render :show
  end

  # GET /root/grid_map_editor/region/:region_id/data
  def region_data
    region = GridRegion.find(params[:region_id])
    zones = region.grid_zones.to_a
    all_rooms = region.grid_rooms.includes(:grid_zone).to_a
    all_room_ids = all_rooms.map(&:id)
    region_room_id_set = Set.new(all_room_ids)

    all_exits = GridExit.where(from_room_id: all_room_ids)
      .includes(to_room: {grid_zone: :grid_region}).to_a

    # Compute per-zone room BFS positions and z-levels
    rooms_by_zone = all_rooms.group_by(&:grid_zone_id)
    zone_room_bfs = {}
    zone_room_z = {}
    zone_bboxes = {}

    zones.each do |z|
      z_rooms = rooms_by_zone[z.id] || []
      z_room_ids = Set.new(z_rooms.map(&:id))
      z_exits = all_exits.select { |e| z_room_ids.include?(e.from_room_id) }
      bfs = bfs_positions(z_rooms, z_exits)
      z_levels = compute_z_levels(z_rooms, z_exits)
      zone_room_bfs[z.id] = bfs
      zone_room_z[z.id] = z_levels

      positions = z_rooms.map { |r| bfs[r.id] || [0, 0] }
      if positions.any?
        xs = positions.map(&:first)
        ys = positions.map(&:last)
        zone_bboxes[z.id] = {width: xs.max - xs.min, height: ys.max - ys.min}
      else
        zone_bboxes[z.id] = {width: 0, height: 0}
      end
    end

    # Compute zone positions via BFS
    zone_positions = compute_zone_bfs_positions(zones, all_rooms, all_exits, zone_bboxes)

    # Zone colors
    zone_color_map = build_zone_color_map
    all_zones_sorted = GridZone.includes(:grid_region).order("grid_regions.name, grid_zones.name").to_a

    # Z-levels present across entire region
    z_level_map = zone_room_z.values.reduce({}, :merge)
    z_levels = z_level_map.values.uniq.sort
    z_levels = [0] if z_levels.empty?

    # Build indexes for O(1) lookups
    exits_by_from = all_exits.group_by(&:from_room_id)
    reverse_exit_index = all_exits.index_by { |e| [e.to_room_id, e.from_room_id] }
    room_by_id = all_rooms.index_by(&:id)
    presence = load_presence_data(all_room_ids)

    # Ghost rooms + inbound exits
    ghost_rooms, inbound_exits, inbound_index = load_ghost_data(all_exits, region_room_id_set, all_room_ids)
    inbound_by_to = inbound_exits.group_by(&:to_room_id)
    exits_by_to = all_exits.group_by(&:to_room_id)

    ghost_data = build_ghost_json(ghost_rooms, exits_by_to, inbound_index)

    # Build rooms with world coordinates (zone offset + room local)
    rooms_json = all_rooms.map do |r|
      zp = zone_positions[r.grid_zone_id] || [0, 0]
      local = zone_room_bfs.dig(r.grid_zone_id, r.id) || [0, 0]
      local_x, local_y = local
      room_z = z_level_map[r.id] || 0
      room_exits = exits_by_from[r.id] || []

      build_room_json(r, zp[0] + local_x, zp[1] + local_y, room_z, presence, room_exits,
        reverse_exit_index, room_by_id, ghost_rooms, inbound_by_to[r.id] || []) do |exit_hash, e, to_room|
        to_zone = to_room&.grid_zone
        exit_hash[:cross_zone] = to_zone.present? && to_zone.id != r.grid_zone_id
        exit_hash[:cross_region] = to_zone.present? && to_zone.grid_region_id != region.id
      end.merge(
        local_x: local_x, local_y: local_y,
        zone_color: zone_color_map[r.grid_zone_id] || "#00ffff"
      )
    end

    # Exits (only intra-region for connector rendering)
    exits_json = all_exits.select { |e| region_room_id_set.include?(e.to_room_id) }.map do |e|
      {id: e.id, from_room_id: e.from_room_id, to_room_id: e.to_room_id,
       direction: e.direction, locked: e.locked?,
       reverse_exit_id: reverse_exit_index[[e.from_room_id, e.to_room_id]]&.id}
    end

    # Zones with positions
    room_counts_by_zone = rooms_by_zone.transform_values(&:size)
    zones_json = zones.map do |z|
      zp = zone_positions[z.id] || [0, 0]
      {id: z.id, name: z.name, slug: z.slug, danger_level: z.danger_level,
       map_x: zp[0], map_y: zp[1],
       color: zone_color_map[z.id] || "#00ffff",
       room_count: room_counts_by_zone[z.id] || 0}
    end

    available_zones = all_zones_sorted.map { |z| {id: z.id, name: z.name, region_name: z.grid_region.name} }
    available_regions = GridRegion.order(:name).map { |r| {id: r.id, name: r.name, slug: r.slug} }

    render json: {
      region: {id: region.id, name: region.name, slug: region.slug},
      zones: zones_json,
      z_level: 0,
      z_levels: z_levels,
      rooms: rooms_json,
      exits: exits_json,
      ghost_rooms: ghost_data,
      vertical_rooms: [],
      breach_templates: GridBreachTemplate.published.ordered.map { |t|
        {id: t.id, name: t.name, slug: t.slug, tier: t.tier, min_clearance: t.min_clearance}
      },
      available_zones: available_zones,
      available_regions: available_regions,
      all_rooms_grouped: build_all_rooms_grouped
    }
  end

  # GET /root/grid_map_editor/:zone_id/data?z=0&all_z=true
  def data
    zone = GridZone.find(params[:zone_id])
    all_zone_rooms = zone.grid_rooms.includes(:grid_zone).to_a
    all_zone_room_ids = all_zone_rooms.map(&:id)

    all_exits = GridExit.where(from_room_id: all_zone_room_ids)
      .includes(to_room: {grid_zone: :grid_region}).to_a

    # Always compute positions and z-levels from exit topology
    positions = bfs_positions(all_zone_rooms, all_exits)
    z_levels_map = compute_z_levels(all_zone_rooms, all_exits)

    # Discover z-levels present in this zone
    z_levels = z_levels_map.values.uniq.sort
    z_levels = [0] if z_levels.empty?

    z_level = params[:z].to_i
    all_z = ActiveModel::Type::Boolean.new.cast(params[:all_z])

    # Snap to first available z-level if requested level has no rooms
    z_level = z_levels.first unless z_levels.include?(z_level)

    # In all_z mode, include every room; otherwise filter to requested z-level
    rooms = if all_z
      all_zone_rooms
    else
      all_zone_rooms.select { |r| (z_levels_map[r.id] || 0) == z_level }
    end
    room_ids = rooms.map(&:id)
    room_id_set = Set.new(room_ids)

    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS
    outbound_vertical = all_exits.select { |e| room_id_set.include?(e.from_room_id) && z_directions.key?(e.direction) }

    same_zone_ids = Set.new(all_zone_room_ids)

    if all_z
      cross_zone_vertical_ids = Set.new
      outbound_vertical.each { |e| cross_zone_vertical_ids.add(e.to_room_id) unless same_zone_ids.include?(e.to_room_id) }
      inbound_vertical_exits = GridExit.where(to_room_id: room_ids, direction: %w[up down])
        .where.not(from_room_id: room_ids).to_a
      cross_zone_vertical_ids.merge(inbound_vertical_exits.map(&:from_room_id))
      vertical_rooms = GridRoom.where(id: cross_zone_vertical_ids.to_a)
        .includes(grid_zone: :grid_region).to_a
      inbound_vertical = inbound_vertical_exits
    else
      other_z_room_ids = all_zone_rooms.reject { |r| (z_levels_map[r.id] || 0) == z_level }.map(&:id)
      other_z_set = Set.new(other_z_room_ids)
      inbound_vertical = all_exits.select { |e| other_z_set.include?(e.from_room_id) && room_id_set.include?(e.to_room_id) && z_directions.key?(e.direction) }
      vertical_room_ids = Set.new
      outbound_vertical.each { |e| vertical_room_ids.add(e.to_room_id) }
      inbound_vertical.each { |e| vertical_room_ids.add(e.from_room_id) }
      vertical_rooms = all_zone_rooms.select { |r| vertical_room_ids.include?(r.id) && (z_levels_map[r.id] || 0) != z_level }
    end

    exits = all_exits.select { |e| room_id_set.include?(e.from_room_id) }

    # Build indexes for O(1) lookups
    exits_by_from = exits.group_by(&:from_room_id)
    reverse_exit_index = exits.index_by { |e| [e.to_room_id, e.from_room_id] }
    room_by_id = rooms.index_by(&:id)
    presence = load_presence_data(room_ids)

    # Ghost rooms + inbound exits
    cross_exit_room_ids = exits
      .reject { |e| room_id_set.include?(e.to_room_id) || same_zone_ids.include?(e.to_room_id) }
      .map(&:to_room_id).uniq
    ghost_rooms = GridRoom.where(id: cross_exit_room_ids)
      .includes(grid_zone: :grid_region).index_by(&:id)

    inbound_exits = GridExit.where(from_room_id: cross_exit_room_ids, to_room_id: room_ids)
      .includes(from_room: {grid_zone: :grid_region}).to_a
    inbound_index = inbound_exits.index_by { |e| [e.from_room_id, e.to_room_id] }
    inbound_by_to = inbound_exits.group_by(&:to_room_id)
    exits_by_to = exits.group_by(&:to_room_id)

    ghost_data = build_ghost_json(ghost_rooms, exits_by_to, inbound_index)

    all_zones = GridZone.includes(:grid_region).order("grid_regions.name, grid_zones.name").to_a
    available_zones = all_zones.map { |z| {id: z.id, name: z.name, region_name: z.grid_region.name} }

    zone_index = all_zones.index { |z| z.id == zone.id } || 0
    zone_color = Grid::WorldMapBuilder::ZONE_COLORS[zone_index % Grid::WorldMapBuilder::ZONE_COLORS.length]

    render json: {
      zone: {id: zone.id, name: zone.name, slug: zone.slug,
             danger_level: zone.danger_level,
             region_id: zone.grid_region_id, region_name: zone.grid_region.name},
      z_level: z_level,
      z_levels: z_levels,
      vertical_rooms: vertical_rooms.map { |r|
        connections = []
        outbound_vertical.select { |e| e.to_room_id == r.id }.each do |e|
          connections << {exit_id: e.id, local_room_id: e.from_room_id, direction: e.direction}
        end
        inbound_vertical.select { |e| e.from_room_id == r.id }.each do |e|
          reverse_dir = (e.direction == "up") ? "down" : "up"
          connections << {exit_id: e.id, local_room_id: e.to_room_id, direction: reverse_dir}
        end
        {id: r.id, name: r.name, room_type: r.room_type, map_z: z_levels_map[r.id] || 0,
         zone_name: r.grid_zone&.name, zone_id: r.grid_zone_id,
         region_name: r.grid_zone&.grid_region&.name,
         connected_via: connections}
      },
      rooms: rooms.map { |r|
        pos = positions[r.id] || [0, 0]
        room_exits = exits_by_from[r.id] || []

        build_room_json(r, pos[0], pos[1], z_levels_map[r.id] || 0, presence, room_exits,
          reverse_exit_index, room_by_id, ghost_rooms, inbound_by_to[r.id] || []) do |exit_hash, _e, to_room|
          to_zone = to_room&.grid_zone
          exit_hash[:cross_zone] = to_zone.present? && to_zone.id != zone.id
        end
      },
      exits: exits.select { |e| room_id_set.include?(e.to_room_id) }.map { |e|
        {id: e.id, from_room_id: e.from_room_id, to_room_id: e.to_room_id,
         direction: e.direction, locked: e.locked?,
         reverse_exit_id: reverse_exit_index[[e.from_room_id, e.to_room_id]]&.id}
      },
      ghost_rooms: ghost_data,
      breach_templates: GridBreachTemplate.published.ordered.map { |t|
        {id: t.id, name: t.name, slug: t.slug, tier: t.tier, min_clearance: t.min_clearance}
      },
      zone_color: zone_color,
      available_zones: available_zones,
      all_rooms_grouped: build_all_rooms_grouped
    }
  end

  # POST /root/grid_map_editor/rooms
  def create_room
    zone = GridZone.find(params[:grid_zone_id])
    room = GridRoom.new(
      name: params[:name],
      slug: params[:slug],
      description: params[:description],
      room_type: params[:room_type].presence,
      min_clearance: params[:min_clearance].to_i,
      grid_zone_id: zone.id
    )

    if room.save
      render json: {success: true, room: {id: room.id, name: room.name, slug: room.slug}}
    else
      render json: {success: false, errors: room.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /root/grid_map_editor/rooms/:id
  def update_room
    room = GridRoom.find(params[:id])
    attrs = {}
    attrs[:name] = params[:name] if params.key?(:name)
    attrs[:slug] = params[:slug] if params.key?(:slug)
    attrs[:description] = params[:description] if params.key?(:description)
    attrs[:room_type] = params[:room_type].presence if params.key?(:room_type)
    attrs[:min_clearance] = params[:min_clearance].to_i if params.key?(:min_clearance)
    attrs[:locked] = params[:locked] if params.key?(:locked)
    attrs[:grid_zone_id] = params[:grid_zone_id].presence&.to_i if params.key?(:grid_zone_id)

    if room.update(attrs)
      render json: {success: true}
    else
      render json: {success: false, errors: room.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /root/grid_map_editor/rooms/:id
  def destroy_room
    room = GridRoom.find(params[:id])

    ActiveRecord::Base.transaction do
      blockers = deletion_blockers(room)
      if blockers.any?
        render json: {success: false, blockers: blockers}, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      else
        room.destroy!
        render json: {success: true}
      end
    end
  end

  # POST /root/grid_map_editor/exits
  def create_exit
    from_room = GridRoom.find(params[:from_room_id])
    to_room = GridRoom.find(params[:to_room_id])
    direction = params[:direction].to_s.strip.downcase

    exit_record = GridExit.new(
      from_room: from_room, to_room: to_room,
      direction: direction, locked: params[:locked] || false
    )

    result = nil
    errors = nil
    reverse = nil

    ActiveRecord::Base.transaction do
      unless exit_record.save
        errors = exit_record.errors.full_messages
        raise ActiveRecord::Rollback
      end

      if params[:bidirectional]
        reverse_dir = params[:reverse_direction].presence || OPPOSITE_DIRECTIONS[direction] || direction
        reverse = GridExit.new(
          from_room: to_room, to_room: from_room,
          direction: reverse_dir, locked: params[:locked] || false
        )
        unless reverse.save
          errors = reverse.errors.full_messages
          raise ActiveRecord::Rollback
        end
      end

      result = {
        success: true,
        exit: {id: exit_record.id, from_room_id: from_room.id, to_room_id: to_room.id, direction: direction},
        reverse_exit: reverse ? {id: reverse.id, from_room_id: to_room.id, to_room_id: from_room.id, direction: reverse.direction} : nil
      }
    end

    if result
      render json: result
    else
      render json: {success: false, errors: errors || ["Transaction failed"]}, status: :unprocessable_entity
    end
  end

  # PATCH /root/grid_map_editor/exits/:id
  def update_exit
    exit_record = GridExit.find(params[:id])
    attrs = {}
    attrs[:direction] = params[:direction].to_s.strip.downcase if params.key?(:direction)
    attrs[:locked] = params[:locked] if params.key?(:locked)
    attrs[:to_room_id] = params[:to_room_id].to_i if params.key?(:to_room_id)

    if exit_record.update(attrs)
      render json: {success: true}
    else
      render json: {success: false, errors: exit_record.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /root/grid_map_editor/exits/:id
  def destroy_exit
    exit_record = GridExit.find(params[:id])
    reverse = nil

    if ActiveModel::Type::Boolean.new.cast(params[:delete_reverse])
      reverse_dir = OPPOSITE_DIRECTIONS[exit_record.direction]
      if reverse_dir
        reverse = GridExit.find_by(
          from_room_id: exit_record.to_room_id,
          to_room_id: exit_record.from_room_id,
          direction: reverse_dir
        )
      end
    end

    ActiveRecord::Base.transaction do
      reverse&.destroy!
      exit_record.destroy!
    end

    render json: {success: true}
  end

  # POST /root/grid_map_editor/mobs
  def create_mob
    room = GridRoom.find(params[:grid_room_id])
    mob = GridMob.new(
      name: params[:name],
      mob_type: params[:mob_type].presence,
      description: params[:description],
      grid_room: room,
      dialogue_tree: {},
      grid_faction_id: params[:grid_faction_id].presence&.to_i
    )

    if mob.save
      render json: {success: true, mob: {id: mob.id, name: mob.name, mob_type: mob.mob_type}}
    else
      render json: {success: false, errors: mob.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # PATCH /root/grid_map_editor/mobs/:id
  def update_mob
    mob = GridMob.find(params[:id])
    attrs = {}
    attrs[:name] = params[:name] if params.key?(:name)
    attrs[:mob_type] = params[:mob_type].presence if params.key?(:mob_type)
    attrs[:description] = params[:description] if params.key?(:description)
    attrs[:grid_room_id] = params[:grid_room_id].to_i if params.key?(:grid_room_id)
    attrs[:grid_faction_id] = params[:grid_faction_id].presence&.to_i if params.key?(:grid_faction_id)

    if mob.update(attrs)
      render json: {success: true}
    else
      render json: {success: false, errors: mob.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /root/grid_map_editor/mobs/:id
  def remove_mob
    mob = GridMob.find(params[:id])

    blockers = []
    blockers << "#{mob.grid_shop_listings.count} shop listing(s)" if mob.grid_shop_listings.any?
    blockers << "#{mob.given_missions.count} mission(s) assigned as giver" if mob.given_missions.any?

    if blockers.any?
      render json: {success: false, blockers: blockers}, status: :unprocessable_entity
      return
    end

    mob.destroy!
    render json: {success: true}
  end

  # POST /root/grid_map_editor/encounters
  def create_encounter
    encounter = GridBreachEncounter.new(
      grid_room_id: params[:grid_room_id],
      grid_breach_template_id: params[:grid_breach_template_id],
      state: "available"
    )

    if encounter.save
      template = encounter.grid_breach_template
      render json: {success: true, encounter: {
        id: encounter.id, template_name: template.name,
        template_id: template.id, state: encounter.state, tier: template.tier
      }}
    else
      render json: {success: false, errors: encounter.errors.full_messages}, status: :unprocessable_entity
    end
  end

  # DELETE /root/grid_map_editor/encounters/:id
  def destroy_encounter
    encounter = GridBreachEncounter.find(params[:id])

    if encounter.grid_hackr_breaches.where(state: "active").exists?
      render json: {success: false, errors: ["Active breaches reference this encounter"]}, status: :unprocessable_entity
      return
    end

    encounter.destroy!
    render json: {success: true}
  end

  private

  # ── Shared JSON builders ────────────────────────────────────

  # Load presence counts for a set of room IDs, returns a struct-like hash.
  def load_presence_data(room_ids)
    {
      hackr_counts: GridHackr.where(current_room_id: room_ids).group(:current_room_id).count,
      mob_data: GridMob.where(grid_room_id: room_ids).select(:id, :name, :mob_type, :description, :grid_room_id).to_a
        .group_by(&:grid_room_id),
      item_counts: GridItem.where(room_id: room_ids, container_id: nil, equipped_slot: nil).group(:room_id).count,
      encounter_data: GridBreachEncounter.where(grid_room_id: room_ids).includes(:grid_breach_template).to_a
        .group_by(&:grid_room_id)
    }
  end

  # Load ghost rooms and inbound exits for cross-scope connections.
  # Returns [ghost_rooms_hash, inbound_exits_array, inbound_index].
  def load_ghost_data(exits, scope_room_id_set, scope_room_ids)
    cross_exit_room_ids = exits
      .reject { |e| scope_room_id_set.include?(e.to_room_id) }
      .map(&:to_room_id).uniq
    ghost_rooms = GridRoom.where(id: cross_exit_room_ids)
      .includes(grid_zone: :grid_region).index_by(&:id)

    inbound_exits = GridExit.where(from_room_id: cross_exit_room_ids, to_room_id: scope_room_ids)
      .includes(from_room: {grid_zone: :grid_region}).to_a
    inbound_index = inbound_exits.index_by { |e| [e.from_room_id, e.to_room_id] }

    [ghost_rooms, inbound_exits, inbound_index]
  end

  # Build ghost room JSON from pre-indexed data.
  def build_ghost_json(ghost_rooms, exits_by_to, inbound_index)
    ghost_rooms.values.map do |gr|
      connections = (exits_by_to[gr.id] || []).map do |e|
        reverse = inbound_index[[gr.id, e.from_room_id]]
        {exit_id: e.id, local_room_id: e.from_room_id, direction: e.direction,
         reverse_exit_id: reverse&.id, reverse_direction: reverse&.direction}
      end
      {id: gr.id, name: gr.name, room_type: gr.room_type,
       zone_name: gr.grid_zone.name, zone_id: gr.grid_zone_id,
       region_name: gr.grid_zone.grid_region.name,
       region_id: gr.grid_zone.grid_region_id,
       connected_via: connections}
    end
  end

  # Build room JSON hash with all nested data (exits, mobs, encounters).
  # Accepts a block to add scope-specific exit fields (cross_zone, cross_region).
  def build_room_json(room, map_x, map_y, map_z, presence, room_exits,
    reverse_exit_index, room_by_id, ghost_rooms, inbound_for_room)
    mobs = presence[:mob_data][room.id] || []
    encounters = presence[:encounter_data][room.id] || []

    {id: room.id, name: room.name, slug: room.slug, description: room.description,
     room_type: room.room_type, min_clearance: room.min_clearance,
     locked: room.locked?, grid_zone_id: room.grid_zone_id,
     map_x: map_x, map_y: map_y, map_z: map_z,
     hackr_count: presence[:hackr_counts][room.id].to_i,
     mob_count: mobs.size, item_count: presence[:item_counts][room.id].to_i,
     mobs: mobs.map { |m| {id: m.id, name: m.name, mob_type: m.mob_type, description: m.description} },
     encounters: encounters.map { |e|
       {id: e.id, template_name: e.grid_breach_template.name,
        template_id: e.grid_breach_template_id, state: e.state,
        tier: e.grid_breach_template.tier}
     },
     exits: room_exits.map { |e|
       reverse = reverse_exit_index[[e.from_room_id, e.to_room_id]]
       to_room = room_by_id[e.to_room_id] || ghost_rooms[e.to_room_id]
       to_zone = to_room&.grid_zone
       exit_hash = {
         id: e.id, direction: e.direction, to_room_id: e.to_room_id,
         to_room_name: to_room&.name || "unknown",
         to_zone_name: to_zone&.name,
         locked: e.locked?, reverse_exit_id: reverse&.id
       }
       yield(exit_hash, e, to_room) if block_given?
       exit_hash
     },
     inbound_exits: inbound_for_room.map { |e|
       {id: e.id, direction: e.direction, from_room_id: e.from_room_id,
        from_room_name: e.from_room&.name || "unknown",
        from_zone_name: e.from_room&.grid_zone&.name}
     }}
  end

  # Build zone color map from global zone ordering (consistent with world map).
  def build_zone_color_map
    all_zones = GridZone.includes(:grid_region).order("grid_regions.name, grid_zones.name").to_a
    all_zones.each_with_index.to_h { |z, i| [z.id, Grid::WorldMapBuilder::ZONE_COLORS[i % Grid::WorldMapBuilder::ZONE_COLORS.length]] }
  end

  # ── BFS algorithms ──────────────────────────────────────────

  # Compute z-level for each room by walking up/down exits from z=0 seed.
  def compute_z_levels(rooms, exits)
    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS
    room_ids = Set.new(rooms.map(&:id))
    exits_by_from = exits.group_by(&:from_room_id)

    seed = rooms.find { |r| r.room_type == "hub" } ||
      rooms.find { |r| r.room_type == "special" } ||
      rooms.find { |r| r.room_type == "transit" } ||
      rooms.min_by(&:id)
    return {} unless seed

    levels = {seed.id => 0}
    queue = [seed.id]
    visited = Set.new([seed.id])

    while (rid = queue.shift)
      current_z = levels[rid]
      (exits_by_from[rid] || []).each do |ex|
        next unless room_ids.include?(ex.to_room_id)
        next if visited.include?(ex.to_room_id)

        z_delta = z_directions[ex.direction]
        visited.add(ex.to_room_id)
        levels[ex.to_room_id] = current_z + (z_delta || 0)
        queue << ex.to_room_id
      end
    end

    rooms.each { |r| levels[r.id] ||= 0 }
    levels
  end

  def bfs_positions(rooms, exits)
    return {} if rooms.empty?

    room_index = rooms.index_by(&:id)
    room_ids = Set.new(rooms.map(&:id))
    exits_by_from = exits.group_by(&:from_room_id)

    direction_vectors = Grid::WorldMapBuilder::DIRECTION_VECTORS
    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS

    positions = {}
    occupied = {}
    remaining = Set.new(room_ids)

    seed = rooms.find { |r| r.room_type == "hub" } ||
      rooms.find { |r| r.room_type == "special" } ||
      rooms.find { |r| r.room_type == "transit" } ||
      rooms.min_by(&:id)
    return {} unless seed

    while remaining.any?
      seed_id = remaining.include?(seed.id) ? seed.id : remaining.first
      queue = [[seed_id, 0, positions.empty? ? 0 : (positions.values.map(&:last).max + 3)]]
      visited = Set.new([seed_id])

      while (item = queue.shift)
        rid, lx, ly = item

        if occupied[[lx, ly]] && occupied[[lx, ly]] != rid
          placed = false
          (1..10).each do |radius|
            break if placed
            (-radius..radius).each do |dx|
              break if placed
              (-radius..radius).each do |dy|
                next if dx == 0 && dy == 0
                nx, ny = lx + dx, ly + dy
                unless occupied.key?([nx, ny])
                  lx, ly = nx, ny
                  placed = true
                end
              end
            end
          end
          lx, ly = lx + 11, ly unless placed
        end

        positions[rid] = [lx, ly]
        occupied[[lx, ly]] = rid
        remaining.delete(rid)

        (exits_by_from[rid] || []).each do |ex|
          next if z_directions.key?(ex.direction)
          next unless room_ids.include?(ex.to_room_id)
          next if visited.include?(ex.to_room_id)
          vec = direction_vectors[ex.direction]
          next unless vec
          visited.add(ex.to_room_id)
          queue << [ex.to_room_id, lx + vec[0], ly + vec[1]]
        end
      end

      seed = room_index[remaining.first] if remaining.any?
    end

    # Normalize to start at (0, 0)
    if positions.any?
      min_x = positions.values.map(&:first).min
      min_y = positions.values.map(&:last).min
      positions.transform_values! { |pos| [pos[0] - min_x, pos[1] - min_y] }
    end

    positions
  end

  # ── Misc helpers ────────────────────────────────────────────

  def deletion_blockers(room)
    blockers = []
    hackr_count = room.grid_hackrs.count
    blockers << "#{hackr_count} hackr(s) currently in room" if hackr_count > 0

    mob_count = room.grid_mobs.count
    blockers << "#{mob_count} mob(s) assigned to room" if mob_count > 0

    item_count = GridItem.where(room_id: room.id, container_id: nil, equipped_slot: nil).count
    blockers << "#{item_count} item(s) on floor" if item_count > 0

    encounter_count = room.grid_breach_encounters.count
    blockers << "#{encounter_count} breach encounter(s) placed" if encounter_count > 0

    region_refs = []
    region_refs << "hospital" if GridRegion.where(hospital_room_id: room.id).exists?
    region_refs << "containment" if GridRegion.where(containment_room_id: room.id).exists?
    region_refs << "facility exit" if GridRegion.where(facility_exit_room_id: room.id).exists?
    region_refs << "facility bribe exit" if GridRegion.where(facility_bribe_exit_room_id: room.id).exists?
    blockers << "Region #{region_refs.join(", ")} room reference" if region_refs.any?

    blockers
  end

  def build_all_rooms_grouped
    regions = GridRegion.includes(grid_zones: :grid_rooms).order(:name)
    regions.map do |region|
      {region: region.name, zones: region.grid_zones.sort_by(&:name).map { |z|
        {zone: z.name, zone_id: z.id, rooms: z.grid_rooms.sort_by(&:name).map { |r|
          {id: r.id, name: r.name}
        }}
      }}
    end
  end

  # BFS over zones using cross-zone exits as edges to compute zone positions.
  # Uses zone bounding boxes for tight spacing instead of fixed stride.
  # Handles disconnected clusters: each connected component gets BFS-positioned
  # internally, then clusters stack below each other.
  def compute_zone_bfs_positions(zones, rooms, exits, zone_bboxes = {})
    zone_gap = 3

    zone_of = rooms.index_by(&:id).transform_values(&:grid_zone_id)
    zone_ids = Set.new(zones.map(&:id))

    zone_connections = Hash.new { |h, k| h[k] = [] }
    exits.each do |ex|
      from_zone = zone_of[ex.from_room_id]
      to_zone = zone_of[ex.to_room_id]
      next unless from_zone && to_zone && from_zone != to_zone
      next unless zone_ids.include?(to_zone)
      direction_vec = Grid::WorldMapBuilder::DIRECTION_VECTORS[ex.direction]
      next unless direction_vec
      zone_connections[from_zone] << {to: to_zone, vec: direction_vec}
    end

    positions = {}
    remaining = Set.new(zones.map(&:id))
    zone_room_counts = rooms.group_by(&:grid_zone_id).transform_values(&:count)
    cluster_offset_y = 0

    # Process each connected component
    while remaining.any?
      # Pick seed: largest unplaced zone
      seed_id = remaining.max_by { |zid| zone_room_counts[zid] || 0 }

      # BFS this cluster
      cluster_positions = {}
      cluster_positions[seed_id] = [0, 0]
      cluster_occupied = Set.new([[0, 0]])
      queue = [seed_id]
      remaining.delete(seed_id)

      while (zid = queue.shift)
        zx, zy = cluster_positions[zid]
        src_bb = zone_bboxes[zid] || {width: 4, height: 4}

        zone_connections[zid].each do |conn|
          next unless remaining.include?(conn[:to])
          remaining.delete(conn[:to])

          tgt_bb = zone_bboxes[conn[:to]] || {width: 4, height: 4}
          dx, dy = conn[:vec]

          offset_x = if dx > 0
            src_bb[:width] + zone_gap + 1
          elsif dx < 0
            -(tgt_bb[:width] + zone_gap + 1)
          else
            0
          end
          offset_y = if dy > 0
            src_bb[:height] + zone_gap + 1
          elsif dy < 0
            -(tgt_bb[:height] + zone_gap + 1)
          else
            0
          end

          new_zx = zx + offset_x
          new_zy = zy + offset_y

          nudge_step = [tgt_bb[:height] + zone_gap + 1, zone_gap + 1].max
          safety = 0
          while cluster_occupied.include?([new_zx, new_zy]) && safety < 50
            new_zy += nudge_step
            safety += 1
          end

          cluster_positions[conn[:to]] = [new_zx, new_zy]
          cluster_occupied.add([new_zx, new_zy])
          queue << conn[:to]
        end
      end

      # Normalize cluster to (0, 0) origin, then offset below previous clusters
      if cluster_positions.any?
        min_x = cluster_positions.values.map(&:first).min
        min_y = cluster_positions.values.map(&:last).min
        cluster_positions.transform_values! { |pos| [pos[0] - min_x, pos[1] - min_y + cluster_offset_y] }

        cluster_bottom = cluster_positions.map { |zid, pos|
          pos[1] + (zone_bboxes[zid] || {height: 0})[:height]
        }.max

        positions.merge!(cluster_positions)
        cluster_offset_y = cluster_bottom + zone_gap + 1
      end
    end

    positions
  end
end
