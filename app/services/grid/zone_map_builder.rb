# frozen_string_literal: true

module Grid
  class ZoneMapBuilder
    TOPOLOGY_TTL = 5.minutes
    TOPOLOGY_RACE_TTL = 30.seconds
    CACHE_NS = "grid/zone_map/v1"

    ZoneMapResult = Struct.new(
      :zone, :rooms, :exits, :ghost_rooms,
      :current_room_id, :z_levels, :z_level
    )

    def initialize(zone:, hackr:)
      @zone = zone
      @hackr = hackr
    end

    def build
      topology = cached_topology
      apply_hackr_overlay(topology)
    end

    def self.bust_cache!(zone_id)
      Rails.cache.delete(topology_cache_key(zone_id))
    end

    def self.topology_cache_key(zone_id)
      "#{CACHE_NS}/topology/zone:#{zone_id}"
    end

    private

    def cached_topology
      Rails.cache.fetch(
        self.class.topology_cache_key(@zone.id),
        expires_in: TOPOLOGY_TTL,
        race_condition_ttl: TOPOLOGY_RACE_TTL
      ) { build_topology }
    end

    # Zone-structural data — same for all hackrs in a zone. Cached.
    # Returns plain hashes only (no AR objects) for safe serialization.
    def build_topology
      rooms = @zone.grid_rooms.to_a
      room_ids = rooms.map(&:id)
      all_exits = GridExit.where(from_room_id: room_ids).to_a

      positions = bfs_positions(rooms, all_exits)
      z_levels_map = compute_z_levels(rooms, all_exits)

      zone_color = build_zone_color(@zone)
      room_id_set = Set.new(room_ids)

      # All exits as plain hashes for overlay adjacency lookups
      exit_hashes = all_exits.map do |e|
        {from_room_id: e.from_room_id, to_room_id: e.to_room_id,
         direction: e.direction, locked: e.locked?,
         in_zone: room_id_set.include?(e.to_room_id)}
      end

      # Ghost rooms — cross-zone exits point outside this zone
      cross_exit_room_ids = all_exits
        .reject { |e| room_id_set.include?(e.to_room_id) }
        .map(&:to_room_id).uniq
      ghost_rooms_raw = GridRoom.where(id: cross_exit_room_ids)
        .includes(grid_zone: :grid_region).to_a

      # Store ALL connecting exits per ghost room so the per-hackr overlay
      # can pick the first one from a visible room. Storing only one would
      # drop the ghost if that single exit starts from a fog-hidden room.
      exits_by_dest = all_exits.select { |e| cross_exit_room_ids.include?(e.to_room_id) }
        .group_by(&:to_room_id)

      ghost_rooms = ghost_rooms_raw.map do |gr|
        connections = (exits_by_dest[gr.id] || []).map { |e| {from_room_id: e.from_room_id, direction: e.direction} }
        {
          id: gr.id, name: gr.name, zone_id: gr.grid_zone_id,
          zone_name: gr.grid_zone.name, region_name: gr.grid_zone.grid_region.name,
          connections: connections
        }
      end

      region = @zone.grid_region

      {
        zone_meta: {
          id: @zone.id, name: @zone.name, slug: @zone.slug,
          danger_level: @zone.danger_level,
          region_id: region&.id, region_name: region&.name
        },
        rooms: rooms.map { |r|
          pos = positions[r.id] || [0, 0]
          {
            id: r.id, name: r.name, slug: r.slug, room_type: r.room_type,
            map_x: pos[0], map_y: pos[1], map_z: z_levels_map[r.id] || 0,
            zone_id: r.grid_zone_id, zone_color: zone_color
          }
        },
        exits: exit_hashes,
        ghost_rooms: ghost_rooms,
        z_levels: z_levels_map.values.uniq.sort,
        room_ids: room_ids
      }
    end

    # Per-hackr overlay — fog-of-war, presence, visibility. Computed live.
    def apply_hackr_overlay(topology)
      room_ids = topology[:room_ids]

      # Fog of war
      visited_ids = GridRoomVisit.where(grid_hackr: @hackr, grid_room_id: room_ids)
        .pluck(:grid_room_id).to_set
      visited_ids.add(@hackr.current_room_id) if room_ids.include?(@hackr.current_room_id)

      # Adjacent = one step from current room
      exits_by_from = topology[:exits].group_by { |e| e[:from_room_id] }
      adjacent_ids = Set.new
      (exits_by_from[@hackr.current_room_id] || []).each { |e| adjacent_ids.add(e[:to_room_id]) }
      visible_ids = visited_ids | adjacent_ids

      # Presence
      presence_data = GridHackr.where(current_room_id: room_ids)
        .pluck(:current_room_id, :hackr_alias)
      presence_by_room = presence_data.group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }

      # Apply fog to rooms
      room_data = topology[:rooms].select { |r| visible_ids.include?(r[:id]) }.map do |r|
        visited = visited_ids.include?(r[:id])
        {
          id: r[:id],
          name: visited ? r[:name] : "???",
          slug: visited ? r[:slug] : nil,
          room_type: visited ? r[:room_type] : nil,
          map_x: r[:map_x], map_y: r[:map_y], map_z: r[:map_z],
          zone_id: r[:zone_id], zone_color: r[:zone_color],
          visited: visited,
          is_current: r[:id] == @hackr.current_room_id,
          hackr_count: visited ? (presence_by_room[r[:id]]&.size || 0) : 0,
          hackr_aliases: visited ? (presence_by_room[r[:id]] || []) : []
        }
      end

      # Filter exits to visible in-zone pairs
      exit_data = topology[:exits]
        .select { |e| e[:in_zone] && visible_ids.include?(e[:from_room_id]) && visible_ids.include?(e[:to_room_id]) }
        .map { |e| {from_room_id: e[:from_room_id], to_room_id: e[:to_room_id], direction: e[:direction], locked: e[:locked]} }

      # Filter ghost rooms — pick the first connection from a visible room
      ghost_rooms = topology[:ghost_rooms].filter_map do |gr|
        visible_conn = gr[:connections].find { |c| visible_ids.include?(c[:from_room_id]) }
        next unless visible_conn
        gr.except(:connections).merge(
          local_room_id: visible_conn[:from_room_id],
          direction: visible_conn[:direction]
        )
      end

      current_room = topology[:rooms].find { |r| r[:id] == @hackr.current_room_id }
      current_z = current_room ? current_room[:map_z] : 0

      ZoneMapResult.new(
        zone: topology[:zone_meta],
        rooms: room_data,
        exits: exit_data,
        ghost_rooms: ghost_rooms,
        current_room_id: @hackr.current_room_id,
        z_levels: topology[:z_levels],
        z_level: current_z
      )
    end

    def build_zone_color(zone)
      Grid::WorldMapBuilder::ZONE_COLORS[zone.id % Grid::WorldMapBuilder::ZONE_COLORS.length]
    end

    def compute_z_levels(rooms, exits)
      z_directions = Grid::WorldMapBuilder::Z_DIRECTIONS
      room_ids = Set.new(rooms.map(&:id))
      exits_by_from = exits.group_by(&:from_room_id)

      # Seed from hub or special room (surface-level anchors).
      # Transit rooms are excluded — they're often underground and
      # would shift the whole zone's z-levels if used as z=0 anchor.
      seed = rooms.find { |r| r.room_type == "hub" } ||
        rooms.find { |r| r.room_type == "special" } ||
        rooms.reject { |r| r.room_type == "transit" }.min_by(&:id) ||
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
        # Queue items: [room_id, x, y, vertical?]
        queue = [[seed_id, 0, positions.empty? ? 0 : (positions.values.map(&:last).max + 3), false]]
        visited = Set.new([seed_id])

        while (item = queue.shift)
          rid, lx, ly, vertical = item

          # Skip collision detection for vertical exits (they share x,y by design)
          if !vertical && occupied[[lx, ly]] && occupied[[lx, ly]] != rid
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
          occupied[[lx, ly]] = rid unless vertical
          remaining.delete(rid)

          (exits_by_from[rid] || []).each do |ex|
            next unless room_ids.include?(ex.to_room_id)
            next if visited.include?(ex.to_room_id)
            if z_directions.key?(ex.direction)
              visited.add(ex.to_room_id)
              queue << [ex.to_room_id, lx, ly, true]
            else
              vec = direction_vectors[ex.direction]
              next unless vec
              visited.add(ex.to_room_id)
              queue << [ex.to_room_id, lx + vec[0], ly + vec[1], false]
            end
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
  end
end
