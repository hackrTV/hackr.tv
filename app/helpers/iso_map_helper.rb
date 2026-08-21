# Ruby port of app/javascript/components/tactical/map/isoGeometry.ts for
# server-rendered SVG zone maps (Phase 0 spike B → Phase 6c). Constants and
# math must stay in lockstep with the TS module until the React map dies.
module IsoMapHelper
  ISO_TILE_W = 160
  ISO_TILE_H = 80
  ISO_WALL_H = 32
  ISO_Z_SPACING = 120

  ROOM_TYPE_COLORS = {
    "hub" => "#fbbf24",
    "faction_base" => "#a78bfa",
    "govcorp" => "#f87171",
    "special" => "#34d399",
    "safe_zone" => "#86efac",
    "transit" => "#38bdf8",
    "shop" => "#fb923c",
    "danger_zone" => "#ef4444",
    "hospital" => "#f472b6",
    "containment" => "#dc2626",
    "impound" => "#b91c1c",
    "den" => "#818cf8",
    "sally_port" => "#991b1b",
    "sally_port_anteroom" => "#7f1d1d",
    "repair_service" => "#f472b6",
    "standard" => "#00ffff"
  }.freeze
  DEFAULT_TILE_COLOR = "#00ffff"

  DIRECTION_VECTORS = {
    "north" => [0, -1], "south" => [0, 1], "east" => [1, 0], "west" => [-1, 0],
    "northeast" => [1, -1], "northwest" => [-1, -1], "southeast" => [1, 1], "southwest" => [-1, 1]
  }.freeze

  def iso_project(gx, gy, gz)
    [
      (gx - gy) * (ISO_TILE_W / 2),
      (gx + gy) * (ISO_TILE_H / 2) - gz * ISO_Z_SPACING
    ]
  end

  def iso_tile_points(gx, gy, gz)
    cx, cy = iso_project(gx, gy, gz)
    hw = ISO_TILE_W / 2
    hh = ISO_TILE_H / 2
    {
      top: [cx, cy - hh],
      right: [cx + hw, cy],
      bottom: [cx, cy + hh],
      left: [cx - hw, cy],
      center: [cx, cy]
    }
  end

  def iso_points_attr(*points)
    points.map { |p| p.join(",") }.join(" ")
  end

  def iso_darken(hex, factor)
    r = hex[1, 2].to_i(16)
    g = hex[3, 2].to_i(16)
    b = hex[5, 2].to_i(16)
    "#" + [r, g, b].map { |c| format("%02x", (c * factor).round) }.join
  end

  def iso_tile_color(room)
    ROOM_TYPE_COLORS[room[:room_type] || "standard"] || room[:zone_color] || DEFAULT_TILE_COLOR
  end
end
