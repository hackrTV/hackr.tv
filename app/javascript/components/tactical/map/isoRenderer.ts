// Pure rendering functions for isometric SVG tiles
// Ported from admin map editor — read-only player version

import { iso, ISO_TILE_W, ISO_TILE_H, ISO_WALL_H, isoDarken, ROOM_TYPE_COLORS } from './isoGeometry'
import { ZoneMapRoom } from '~/types/zoneMap'

export interface TilePoints {
  top: [number, number]
  right: [number, number]
  bottom: [number, number]
  left: [number, number]
  center: [number, number]
}

export interface RenderRoom {
  room: ZoneMapRoom
  depth: number
  points: TilePoints
}

export function tilePoints (gx: number, gy: number, gz: number): TilePoints {
  const center = iso(gx, gy, gz)
  const cx = center[0], cy = center[1]
  const hw = ISO_TILE_W / 2, hh = ISO_TILE_H / 2
  return {
    top: [cx, cy - hh],
    right: [cx + hw, cy],
    bottom: [cx, cy + hh],
    left: [cx - hw, cy],
    center: [cx, cy]
  }
}

export function buildRenderList (rooms: ZoneMapRoom[]): RenderRoom[] {
  return rooms
    .map(room => ({
      room,
      depth: room.map_x + room.map_y,
      points: tilePoints(room.map_x, room.map_y, room.map_z)
    }))
    .sort((a, b) => a.depth - b.depth)
}

export function tileColor (room: ZoneMapRoom): string {
  return ROOM_TYPE_COLORS[room.room_type || 'standard'] || room.zone_color || '#00ffff'
}

export type TileReach = 'current' | 'adjacent' | 'distant' | 'unexplored'

export function tileStyles (room: ZoneMapRoom, reach: TileReach) {
  const color = tileColor(room)
  if (reach === 'current') {
    return {
      topFill: '#1a2a2a',
      topStroke: '#fff',
      topStrokeW: 2.5,
      leftFill: isoDarken(color, 0.25),
      rightFill: isoDarken(color, 0.18),
      sideStroke: isoDarken(color, 0.45),
      nameColor: color,
      opacity: 1.0
    }
  }
  if (reach === 'adjacent') {
    return {
      topFill: '#111',
      topStroke: color,
      topStrokeW: 1.5,
      leftFill: isoDarken(color, 0.20),
      rightFill: isoDarken(color, 0.14),
      sideStroke: isoDarken(color, 0.35),
      nameColor: color,
      opacity: 0.7
    }
  }
  if (reach === 'unexplored') {
    return {
      topFill: '#0c0c0c',
      topStroke: '#444',
      topStrokeW: 1,
      leftFill: '#0a0a0a',
      rightFill: '#080808',
      sideStroke: '#1a1a1a',
      nameColor: '#555',
      opacity: 0.55
    }
  }
  // distant
  return {
    topFill: '#0e0e0e',
    topStroke: isoDarken(color, 0.4),
    topStrokeW: 1,
    leftFill: isoDarken(color, 0.10),
    rightFill: isoDarken(color, 0.07),
    sideStroke: isoDarken(color, 0.15),
    nameColor: isoDarken(color, 0.45),
    opacity: 0.35
  }
}

export function connectorEndpoints (
  from: ZoneMapRoom,
  to: ZoneMapRoom
): { x1: number; y1: number; x2: number; y2: number } | null {
  const p1 = iso(from.map_x, from.map_y, from.map_z)
  const p2 = iso(to.map_x, to.map_y, to.map_z)
  const dx = p2[0] - p1[0], dy = p2[1] - p1[1]
  const dist = Math.sqrt(dx * dx + dy * dy)
  if (dist === 0) return null

  const ux = dx / dist, uy = dy / dist
  const shorten = Math.min(ISO_TILE_W, ISO_TILE_H) * 0.45

  return {
    x1: Math.round(p1[0] + ux * shorten),
    y1: Math.round(p1[1] + uy * shorten),
    x2: Math.round(p2[0] - ux * shorten),
    y2: Math.round(p2[1] - uy * shorten)
  }
}

export function computeViewBox (
  renderList: RenderRoom[],
  padding: number = 120
): { x: number; y: number; w: number; h: number } {
  if (renderList.length === 0) {
    return { x: -400, y: -300, w: 800, h: 600 }
  }

  let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
  for (const { points } of renderList) {
    const pts = [points.top, points.right, points.bottom, points.left]
    for (const [px, py] of pts) {
      if (px < minX) minX = px
      if (py < minY) minY = py
      if (px > maxX) maxX = px
      if (py + ISO_WALL_H > maxY) maxY = py + ISO_WALL_H
    }
  }

  return {
    x: minX - padding,
    y: minY - padding,
    w: maxX - minX + padding * 2,
    h: maxY - minY + padding * 2
  }
}
