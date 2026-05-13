// Isometric geometry constants and transforms
// Ported from admin map editor (show.html.erb)

export const ISO_TILE_W = 160
export const ISO_TILE_H = 80
export const ISO_WALL_H = 32
export const ISO_Z_SPACING = 120

export function iso (gx: number, gy: number, gz: number): [number, number] {
  return [
    (gx - gy) * (ISO_TILE_W / 2),
    (gx + gy) * (ISO_TILE_H / 2) - gz * ISO_Z_SPACING
  ]
}

export function isoInverse (sx: number, sy: number, gz: number): [number, number] {
  const hw = ISO_TILE_W / 2
  const hh = ISO_TILE_H / 2
  const syAdj = sy + gz * ISO_Z_SPACING
  return [
    Math.round((sx / hw + syAdj / hh) / 2),
    Math.round((syAdj / hh - sx / hw) / 2)
  ]
}

export function isoPts (arr: [number, number][]): string {
  return arr.map(p => `${p[0]},${p[1]}`).join(' ')
}

export function isoDarken (hex: string, factor: number): string {
  const r = parseInt(hex.slice(1, 3), 16)
  const g = parseInt(hex.slice(3, 5), 16)
  const b = parseInt(hex.slice(5, 7), 16)
  return '#' + [r, g, b].map(c =>
    ('0' + Math.round(c * factor).toString(16)).slice(-2)
  ).join('')
}

export const DIRECTION_VECTORS: Record<string, [number, number]> = {
  north: [0, -1],
  south: [0, 1],
  east: [1, 0],
  west: [-1, 0],
  northeast: [1, -1],
  northwest: [-1, -1],
  southeast: [1, 1],
  southwest: [-1, 1]
}

export const ROOM_TYPE_COLORS: Record<string, string> = {
  hub: '#fbbf24',
  faction_base: '#a78bfa',
  govcorp: '#f87171',
  special: '#34d399',
  safe_zone: '#86efac',
  transit: '#38bdf8',
  shop: '#fb923c',
  danger_zone: '#ef4444',
  hospital: '#f472b6',
  containment: '#dc2626',
  impound: '#b91c1c',
  den: '#818cf8',
  sally_port: '#991b1b',
  sally_port_anteroom: '#7f1d1d',
  repair_service: '#f472b6',
  standard: '#00ffff'
}
