# frozen_string_literal: true

module Grid
  # Builds an SVG map from a set of rooms and exits.
  # Rooms have no stored coordinates — positions are derived via BFS
  # using direction vectors. Rooms are color-coded by zone.
  # Output is an SVG string embedded directly in the page.
  class WorldMapBuilder
    MapResult = Struct.new(
      :svg,                  # String — complete <svg> element
      :placed_rooms,         # Array<GridRoom> — rooms placed on this z-level
      :unplaced_rooms,       # Array<GridRoom> — rooms with no exits (never visited)
      :cross_exits,          # Array<Hash> — exits pointing outside the room set
      :conflicts,            # Array<String> — nudge descriptions
      :z_levels_present,     # Array<Integer> — all reachable z-levels
      :components,           # Integer — connected component count
      keyword_init: true
    )

    DIRECTION_VECTORS = {
      "north" => [0, -1],
      "south" => [0, 1],
      "east" => [1, 0],
      "west" => [-1, 0],
      "northeast" => [1, -1],
      "northwest" => [-1, -1],
      "southeast" => [1, 1],
      "southwest" => [-1, 1]
    }.freeze

    Z_DIRECTIONS = {"up" => 1, "down" => -1}.freeze

    # SVG dimensions
    BOX_W = 140       # room box width
    BOX_H = 52        # room box height
    STRIDE_X = 200    # horizontal center-to-center distance
    STRIDE_Y = 100    # vertical center-to-center distance
    PADDING = 40      # canvas edge padding
    MIN_SVG_W = 1000  # minimum viewBox width to prevent oversized rooms

    ZONE_COLORS = %w[
      #00ffff #34d399 #f472b6 #fbbf24 #a78bfa
      #60a5fa #f87171 #86efac #fb923c #818cf8
      #e879f9 #38bdf8 #facc15 #4ade80 #fb7185
    ].freeze

    def initialize(rooms:, exits:, presence:, zone_colors: {}, cross_room_index: {})
      @rooms = rooms
      @exits = exits
      @presence = presence
      @zone_colors = zone_colors
      @cross_room_index = cross_room_index
    end

    def build(z_level: 0)
      room_index = @rooms.index_by(&:id)
      all_exits = @exits.group_by(&:from_room_id)

      intra_exits_by_from = {}
      cross_exits = []

      all_exits.each do |from_id, exits_list|
        exits_list.each do |ex|
          if room_index.key?(ex.to_room_id)
            (intra_exits_by_from[from_id] ||= []) << ex
          else
            target = @cross_room_index[ex.to_room_id]
            cross_exits << {
              from_room: room_index[from_id],
              direction: ex.direction,
              to_room: target,
              to_zone: target&.grid_zone,
              to_region: target&.grid_zone&.grid_region
            }
          end
        end
      end

      z_seeds = find_z_seeds(room_index, intra_exits_by_from)
      z_levels = z_seeds.keys.sort
      z_levels = [0] if z_levels.empty?

      level_room_ids = rooms_on_level(room_index, intra_exits_by_from, z_seeds, z_level)

      if z_level == 0
        assigned = Set.new
        z_seeds.each_key do |zl|
          assigned.merge(rooms_on_level(room_index, intra_exits_by_from, z_seeds, zl))
        end
        level_room_ids.merge(Set.new(room_index.keys) - assigned)
      end

      level_rooms = level_room_ids.filter_map { |id| room_index[id] }

      if level_rooms.empty?
        return MapResult.new(
          svg: "", placed_rooms: [], unplaced_rooms: [], cross_exits: cross_exits,
          conflicts: [], z_levels_present: z_levels, components: 0
        )
      end

      positions = {}
      occupied = {}
      conflicts = []
      component_count = 0
      remaining = Set.new(level_room_ids)
      seed_id = z_seeds[z_level] || pick_seed(level_rooms)

      while remaining.any?
        seed = room_index[seed_id] || room_index[remaining.first]
        break unless seed && remaining.include?(seed.id)

        component_count += 1
        y_offset = positions.empty? ? 0 : (positions.values.map(&:last).max + 3)

        comp_positions, comp_conflicts = bfs_component(
          seed, intra_exits_by_from, room_index, occupied, level_room_ids, y_offset
        )

        positions.merge!(comp_positions)
        conflicts.concat(comp_conflicts)
        remaining -= comp_positions.keys
        seed_id = remaining.first
      end

      unplaced = level_rooms.reject { |r| positions.key?(r.id) }

      # Normalize positions to start at (0, 0)
      if positions.any?
        min_x = positions.values.map(&:first).min
        min_y = positions.values.map(&:last).min
        positions.transform_values! { |pos| [pos[0] - min_x, pos[1] - min_y] }
      end

      svg = render_svg(positions, room_index, intra_exits_by_from, level_room_ids)

      MapResult.new(
        svg: svg,
        placed_rooms: positions.keys.filter_map { |id| room_index[id] },
        unplaced_rooms: unplaced,
        cross_exits: cross_exits,
        conflicts: conflicts,
        z_levels_present: z_levels,
        components: component_count
      )
    end

    private

    # ── BFS / z-level logic (unchanged) ─────────────────────────

    def find_z_seeds(room_index, exits_by_from)
      seeds = {}
      all_room_ids = Set.new(room_index.keys)
      base_seed = pick_seed(room_index.values)
      return seeds unless base_seed

      seeds[0] = base_seed
      visited_levels = Set.new([0])
      queue = [0]

      while (current_z = queue.shift)
        level_rooms = flat_reachable(seeds[current_z], exits_by_from, all_room_ids)
        level_rooms.each do |rid|
          (exits_by_from[rid] || []).each do |ex|
            z_delta = Z_DIRECTIONS[ex.direction]
            next unless z_delta
            next unless all_room_ids.include?(ex.to_room_id)
            new_z = current_z + z_delta
            next if visited_levels.include?(new_z)
            seeds[new_z] = ex.to_room_id
            visited_levels.add(new_z)
            queue << new_z
          end
        end
      end

      seeds
    end

    def flat_reachable(seed_id, exits_by_from, all_room_ids)
      return Set.new unless seed_id
      visited = Set.new([seed_id])
      queue = [seed_id]
      while (rid = queue.shift)
        (exits_by_from[rid] || []).each do |ex|
          next if Z_DIRECTIONS.key?(ex.direction)
          next unless all_room_ids.include?(ex.to_room_id)
          next if visited.include?(ex.to_room_id)
          visited.add(ex.to_room_id)
          queue << ex.to_room_id
        end
      end
      visited
    end

    def rooms_on_level(room_index, exits_by_from, z_seeds, z_level)
      seed_id = z_seeds[z_level]
      return Set.new unless seed_id
      flat_reachable(seed_id, exits_by_from, Set.new(room_index.keys))
    end

    def pick_seed(rooms)
      hub = rooms.find { |r| r.room_type == "hub" }
      return hub.id if hub
      special = rooms.find { |r| r.room_type == "special" }
      return special.id if special
      transit = rooms.find { |r| r.room_type == "transit" }
      return transit.id if transit
      rooms.min_by(&:id)&.id
    end

    def bfs_component(seed, exits_by_from, room_index, occupied, level_room_ids, y_offset)
      positions = {}
      conflicts = []
      queue = [[seed.id, 0, y_offset]]
      visited = Set.new([seed.id])

      while (item = queue.shift)
        rid, lx, ly = item

        if occupied[[lx, ly]] && occupied[[lx, ly]] != rid
          lx, ly = find_free_cell(lx, ly, occupied)
          conflicts << "#{room_index[rid]&.name}: position nudged"
        end

        positions[rid] = [lx, ly]
        occupied[[lx, ly]] = rid

        (exits_by_from[rid] || []).each do |ex|
          next if Z_DIRECTIONS.key?(ex.direction)
          next unless level_room_ids.include?(ex.to_room_id)
          next if visited.include?(ex.to_room_id)
          vec = DIRECTION_VECTORS[ex.direction]
          next unless vec
          visited.add(ex.to_room_id)
          queue << [ex.to_room_id, lx + vec[0], ly + vec[1]]
        end
      end

      [positions, conflicts]
    end

    def find_free_cell(cx, cy, occupied)
      (1..10).each do |radius|
        (-radius..radius).each do |dx|
          (-radius..radius).each do |dy|
            next if dx == 0 && dy == 0
            nx, ny = cx + dx, cy + dy
            return [nx, ny] unless occupied.key?([nx, ny])
          end
        end
      end
      [cx + 11, cy]
    end

    # ── SVG rendering ───────────────────────────────────────────

    def render_svg(positions, room_index, exits_by_from, level_room_ids)
      return "" if positions.empty?

      max_lx = positions.values.map(&:first).max
      max_ly = positions.values.map(&:last).max
      svg_w = [(max_lx + 1) * STRIDE_X + PADDING * 2, MIN_SVG_W].max
      svg_h = (max_ly + 1) * STRIDE_Y + PADDING * 2

      lines = []
      lines << %(<svg xmlns="http://www.w3.org/2000/svg" width="100%" viewBox="0 0 #{svg_w} #{svg_h}" style="background: #0d0d0d; border-radius: 4px;">)
      lines << %(<style>)
      lines << %(  .room-box { cursor: pointer; })
      lines << %(  .room-box:hover rect { stroke-width: 2; filter: brightness(1.3); })
      lines << %(  .room-box:hover .room-name { fill: #fff !important; })
      lines << %(  .room-name { font-family: 'Courier New', monospace; font-size: 11px; })
      lines << %(  .room-info { font-family: 'Courier New', monospace; font-size: 9px; fill: #666; })
      lines << %(  .connector { stroke-width: 1; fill: none; })
      lines << %(  .arrow { fill: #444; })
      lines << %(</style>)

      # Draw connectors first (behind rooms)
      drawn_edges = Set.new
      positions.each do |rid, (lx, ly)|
        (exits_by_from[rid] || []).each do |ex|
          next if Z_DIRECTIONS.key?(ex.direction)
          next unless level_room_ids.include?(ex.to_room_id)
          next unless positions.key?(ex.to_room_id)

          edge_key = [rid, ex.to_room_id].sort
          next if drawn_edges.include?(edge_key)
          drawn_edges.add(edge_key)

          to_lx, to_ly = positions[ex.to_room_id]
          lines << render_connector(lx, ly, to_lx, to_ly)
        end
      end

      # Draw rooms on top
      positions.each do |rid, (lx, ly)|
        room = room_index[rid]
        lines << render_room(lx, ly, room)
      end

      lines << %(</svg>)
      lines.join("\n")
    end

    def render_room(lx, ly, room)
      cx = lx * STRIDE_X + PADDING
      cy = ly * STRIDE_Y + PADDING
      rx = cx - BOX_W / 2
      ry = cy - BOX_H / 2
      color = @zone_colors[room.grid_zone_id] || "#888"
      pres = @presence[room.id] || {hackrs: 0, mobs: 0}
      locked = room.locked?

      name = h(room.name[0, 18])
      tooltip = h("#{room.name} [#{room.grid_zone&.name}] #{room.room_type}")
      room_url = "/root/grid_rooms/#{room.id}/edit"

      # Build info line
      info_parts = []
      info_parts << h(room.room_type) if room.room_type
      info_parts << "#{pres[:hackrs]}H" if pres[:hackrs] > 0
      info_parts << "#{pres[:mobs]}M" if pres[:mobs] > 0
      info_line = info_parts.join(" · ")

      stroke = locked ? "#f87171" : color
      stroke_w = locked ? "2" : "1"
      fill = "#111"

      svg = +""
      svg << %(<a href="#{room_url}" class="room-box">)
      svg << %(<title>#{tooltip}</title>)
      svg << %(<rect x="#{rx}" y="#{ry}" width="#{BOX_W}" height="#{BOX_H}" )
      svg << %(fill="#{fill}" stroke="#{stroke}" stroke-width="#{stroke_w}" rx="3"/>)
      svg << %(<text x="#{cx}" y="#{cy - 6}" text-anchor="middle" class="room-name" fill="#{color}">#{name}</text>)
      svg << %(<text x="#{cx}" y="#{cy + 10}" text-anchor="middle" class="room-info">#{info_line}</text>)
      if locked
        svg << %(<text x="#{rx + 4}" y="#{ry + 11}" font-size="8" fill="#f87171">🔒</text>)
      end
      svg << %(</a>)
      svg
    end

    def render_connector(from_lx, from_ly, to_lx, to_ly)
      x1 = from_lx * STRIDE_X + PADDING
      y1 = from_ly * STRIDE_Y + PADDING
      x2 = to_lx * STRIDE_X + PADDING
      y2 = to_ly * STRIDE_Y + PADDING

      dx = x2 - x1
      dy = y2 - y1
      dist = Math.sqrt(dx * dx + dy * dy)
      return "" if dist == 0

      ux = dx / dist
      uy = dy / dist

      # Proper box-edge intersection: find where the direction ray exits the box
      inset1 = box_edge_inset(ux, uy)
      inset2 = box_edge_inset(-ux, -uy)

      sx = x1 + ux * inset1
      sy = y1 + uy * inset1
      ex = x2 - ux * inset2
      ey = y2 - uy * inset2

      %(<line x1="#{sx.round}" y1="#{sy.round}" x2="#{ex.round}" y2="#{ey.round}" stroke="#333" class="connector"/>)
    end

    # Distance from box center to its edge along direction (ux, uy).
    # Handles all angles correctly, including diagonals.
    def box_edge_inset(ux, uy)
      hw = BOX_W / 2.0
      hh = BOX_H / 2.0
      return hh if ux.abs < 0.001
      return hw if uy.abs < 0.001
      [hw / ux.abs, hh / uy.abs].min
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
