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
  end

  # GET /root/grid_map_editor/:zone_id/data?z=0&all_z=true
  def data
    zone = GridZone.find(params[:zone_id])
    z_level = params[:z].to_i
    all_z = ActiveModel::Type::Boolean.new.cast(params[:all_z])
    all_zone_rooms = zone.grid_rooms.includes(:grid_zone).to_a
    all_zone_room_ids = all_zone_rooms.map(&:id)

    all_exits = GridExit.where(from_room_id: all_zone_room_ids)
      .includes(to_room: {grid_zone: :grid_region}).to_a

    # Compute BFS positions for rooms without stored coords (on z=0 plane)
    bfs_positions = compute_bfs_positions(all_zone_rooms, all_exits)

    # Discover z-levels present in this zone
    z_levels = all_zone_rooms.map(&:map_z).uniq.sort
    z_levels = [0] if z_levels.empty?

    # Snap to first available z-level if requested level has no rooms
    z_level = z_levels.first unless z_levels.include?(z_level)

    # In all_z mode, include every room; otherwise filter to requested z-level
    rooms = all_z ? all_zone_rooms : all_zone_rooms.select { |r| r.map_z == z_level }
    room_ids = rooms.map(&:id)

    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS
    outbound_vertical = all_exits.select { |e| room_ids.include?(e.from_room_id) && z_directions.key?(e.direction) }

    same_zone_ids = Set.new(all_zone_room_ids)

    if all_z
      # In all_z mode, vertical rooms are CROSS-ZONE rooms connected via up/down
      cross_zone_vertical_ids = Set.new
      outbound_vertical.each { |e| cross_zone_vertical_ids.add(e.to_room_id) unless same_zone_ids.include?(e.to_room_id) }
      # Also check inbound: other-zone rooms with up/down exits pointing into this zone
      inbound_vertical_exits = GridExit.where(to_room_id: room_ids, direction: %w[up down])
        .where.not(from_room_id: room_ids).to_a
      cross_zone_vertical_ids.merge(inbound_vertical_exits.map(&:from_room_id))
      vertical_rooms = GridRoom.where(id: cross_zone_vertical_ids.to_a)
        .includes(grid_zone: :grid_region).to_a
      inbound_vertical = inbound_vertical_exits
    else
      other_z_room_ids = all_zone_rooms.reject { |r| r.map_z == z_level }.map(&:id)
      inbound_vertical = all_exits.select { |e| other_z_room_ids.include?(e.from_room_id) && room_ids.include?(e.to_room_id) && z_directions.key?(e.direction) }
      vertical_room_ids = Set.new
      outbound_vertical.each { |e| vertical_room_ids.add(e.to_room_id) }
      inbound_vertical.each { |e| vertical_room_ids.add(e.from_room_id) }
      vertical_rooms = all_zone_rooms.select { |r| vertical_room_ids.include?(r.id) && r.map_z != z_level }
    end

    exits = all_exits.select { |e| room_ids.include?(e.from_room_id) }

    # Presence counts
    hackr_counts = GridHackr.where(current_room_id: room_ids).group(:current_room_id).count
    mob_data = GridMob.where(grid_room_id: room_ids).select(:id, :name, :mob_type, :description, :grid_room_id).to_a
    item_counts = GridItem.where(room_id: room_ids, container_id: nil, equipped_slot: nil)
      .group(:room_id).count
    encounter_data = GridBreachEncounter.where(grid_room_id: room_ids)
      .includes(:grid_breach_template).to_a

    # Ghost rooms: rooms in OTHER ZONES connected to this zone's rooms.
    cross_exit_room_ids = exits
      .reject { |e| room_ids.include?(e.to_room_id) || same_zone_ids.include?(e.to_room_id) }
      .map(&:to_room_id).uniq
    ghost_rooms = GridRoom.where(id: cross_exit_room_ids)
      .includes(grid_zone: :grid_region).index_by(&:id)

    # Reverse exits pointing into this zone (from ghost rooms) — load before ghost_data to avoid N+1
    inbound_exits = GridExit.where(from_room_id: cross_exit_room_ids, to_room_id: room_ids)
      .includes(from_room: {grid_zone: :grid_region}).to_a
    inbound_index = inbound_exits.index_by { |e| [e.from_room_id, e.to_room_id] }

    # Build ghost room data with connection info
    ghost_data = ghost_rooms.values.map do |gr|
      connections = exits.select { |e| e.to_room_id == gr.id }.map do |e|
        reverse = inbound_index[[gr.id, e.from_room_id]]
        {exit_id: e.id, local_room_id: e.from_room_id, direction: e.direction,
         reverse_exit_id: reverse&.id, reverse_direction: reverse&.direction}
      end
      {id: gr.id, name: gr.name, room_type: gr.room_type,
       zone_name: gr.grid_zone.name, zone_id: gr.grid_zone_id,
       region_name: gr.grid_zone.grid_region.name,
       connected_via: connections}
    end

    # All rooms grouped for combobox (cross-zone/region exit creation)
    all_rooms_grouped = build_all_rooms_grouped

    # Breach templates for placement
    breach_templates = GridBreachTemplate.published.ordered.map do |t|
      {id: t.id, name: t.name, slug: t.slug, tier: t.tier, min_clearance: t.min_clearance}
    end

    # Available zones for navigation (also used for zone color derivation)
    all_zones = GridZone.includes(:grid_region).order("grid_regions.name, grid_zones.name").to_a
    available_zones = all_zones.map { |z| {id: z.id, name: z.name, region_name: z.grid_region.name} }

    # Zone color — match world map's per-zone color assignment
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
        # Outbound: local room --up/down--> this vertical room
        outbound_vertical.select { |e| e.to_room_id == r.id }.each do |e|
          connections << {exit_id: e.id, local_room_id: e.from_room_id, direction: e.direction}
        end
        # Inbound: this vertical room --up/down--> local room (reverse perspective)
        inbound_vertical.select { |e| e.from_room_id == r.id }.each do |e|
          reverse_dir = (e.direction == "up") ? "down" : "up"
          connections << {exit_id: e.id, local_room_id: e.to_room_id, direction: reverse_dir}
        end
        {id: r.id, name: r.name, room_type: r.room_type, map_z: r.map_z,
         zone_name: r.grid_zone&.name, zone_id: r.grid_zone_id,
         region_name: r.grid_zone&.grid_region&.name,
         connected_via: connections}
      },
      rooms: rooms.map { |r|
        mobs = mob_data.select { |m| m.grid_room_id == r.id }
        encounters = encounter_data.select { |e| e.grid_room_id == r.id }
        room_exits = exits.select { |e| e.from_room_id == r.id }
        # Include inbound exits from ghost rooms
        inbound = inbound_exits.select { |e| e.to_room_id == r.id }
        pos_source = r.map_x.nil? ? "computed" : "stored"
        mx = r.map_x || bfs_positions.dig(r.id, 0) || 0
        my = r.map_y || bfs_positions.dig(r.id, 1) || 0

        {id: r.id, name: r.name, slug: r.slug, description: r.description,
         room_type: r.room_type, min_clearance: r.min_clearance,
         locked: r.locked?, grid_zone_id: r.grid_zone_id,
         map_x: mx, map_y: my, map_z: r.map_z, position_source: pos_source,
         hackr_count: hackr_counts[r.id].to_i,
         mob_count: mobs.size, item_count: item_counts[r.id].to_i,
         mobs: mobs.map { |m| {id: m.id, name: m.name, mob_type: m.mob_type, description: m.description} },
         encounters: encounters.map { |e|
           {id: e.id, template_name: e.grid_breach_template.name,
            template_id: e.grid_breach_template_id, state: e.state,
            tier: e.grid_breach_template.tier}
         },
         exits: room_exits.map { |e|
           reverse = exits.find { |r_ex| r_ex.from_room_id == e.to_room_id && r_ex.to_room_id == e.from_room_id }
           to_room = rooms.find { |rm| rm.id == e.to_room_id } || ghost_rooms[e.to_room_id]
           to_zone = to_room&.grid_zone
           {id: e.id, direction: e.direction, to_room_id: e.to_room_id,
            to_room_name: to_room&.name || "unknown",
            to_zone_name: to_zone&.name,
            locked: e.locked?, reverse_exit_id: reverse&.id,
            cross_zone: to_zone.present? && to_zone.id != zone.id}
         },
         inbound_exits: inbound.map { |e|
           {id: e.id, direction: e.direction, from_room_id: e.from_room_id,
            from_room_name: e.from_room&.name || "unknown",
            from_zone_name: e.from_room&.grid_zone&.name}
         }}
      },
      exits: exits.select { |e| room_ids.include?(e.to_room_id) }.map { |e|
        reverse = exits.find { |r_ex| r_ex.from_room_id == e.to_room_id && r_ex.to_room_id == e.from_room_id }
        {id: e.id, from_room_id: e.from_room_id, to_room_id: e.to_room_id,
         direction: e.direction, locked: e.locked?,
         reverse_exit_id: reverse&.id}
      },
      ghost_rooms: ghost_data,
      breach_templates: breach_templates,
      zone_color: zone_color,
      available_zones: available_zones,
      all_rooms_grouped: all_rooms_grouped
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
      grid_zone_id: zone.id,
      map_x: params[:map_x].to_i,
      map_y: params[:map_y].to_i,
      map_z: params[:map_z].to_i
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
    attrs[:map_x] = params[:map_x].to_i if params.key?(:map_x)
    attrs[:map_y] = params[:map_y].to_i if params.key?(:map_y)
    attrs[:map_z] = params[:map_z].to_i if params.key?(:map_z)

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

  # POST /root/grid_map_editor/:zone_id/auto_layout
  def auto_layout
    zone = GridZone.find(params[:zone_id])
    rooms = zone.grid_rooms.includes(:grid_zone).to_a
    room_ids = rooms.map(&:id)
    exits = GridExit.where(from_room_id: room_ids)
      .includes(to_room: {grid_zone: :grid_region}).to_a

    positions = compute_bfs_positions(rooms, exits)
    z_levels = compute_z_levels(rooms, exits)

    room_index = rooms.index_by(&:id)
    count = 0
    ActiveRecord::Base.transaction do
      positions.each do |room_id, (x, y)|
        room = room_index[room_id]
        next unless room
        z = z_levels[room_id] || 0
        room.update!(map_x: x, map_y: y, map_z: z)
        count += 1
      end
    end

    render json: {success: true, updated: count}
  end

  private

  def compute_bfs_positions(rooms, exits)
    return {} if rooms.empty?
    bfs_positions(rooms, exits)
  end

  # Compute z-level for each room by walking up/down exits from z=0 seed.
  def compute_z_levels(rooms, exits)
    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS
    room_ids = Set.new(rooms.map(&:id))
    exits_by_from = exits.group_by(&:from_room_id)

    # Seed: same priority as BFS
    seed = rooms.find { |r| r.room_type == "hub" } ||
      rooms.find { |r| r.room_type == "special" } ||
      rooms.find { |r| r.room_type == "transit" } ||
      rooms.min_by(&:id)
    return {} unless seed

    # BFS: walk horizontal exits to find all rooms reachable on z=0,
    # then follow up/down exits to discover other z-levels
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

    # Any unvisited rooms default to z=0
    rooms.each { |r| levels[r.id] ||= 0 }
    levels
  end

  def bfs_positions(rooms, exits)
    room_index = rooms.index_by(&:id)
    room_ids = Set.new(rooms.map(&:id))
    exits_by_from = exits.group_by(&:from_room_id)

    direction_vectors = Grid::WorldMapBuilder::DIRECTION_VECTORS
    z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS

    positions = {}
    occupied = {}
    remaining = Set.new(room_ids)

    # Pick seed: hub > special > transit > min id
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
          # Find free cell
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

    # Region special room references
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
end
