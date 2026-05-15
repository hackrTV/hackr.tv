import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react'
import { apiJson } from '~/utils/apiClient'
import { ZoneMapData, ZoneMapRoom, ZoneMapGhostRoom, BreachEncounter, DeckStatus } from '~/types/zoneMap'
import { iso, isoPts, ISO_WALL_H, ISO_TILE_W, ISO_TILE_H, DIRECTION_VECTORS } from './isoGeometry'
import { useZonePresence } from './useZonePresence'
import {
  buildRenderList, tileStyles, tileColor, connectorEndpoints,
  computeViewBox, RenderRoom
} from './isoRenderer'

interface ZoneMapProps {
  refreshToken: number
  currentRoomId: number | null
  onNavigate?: (direction: string) => void
  onBreachEncountersChange?: (encounters: BreachEncounter[], deckStatus: DeckStatus) => void
  onVendorPresenceChange?: (hasVendor: boolean) => void
  onTransitPresenceChange?: (hasTransit: boolean) => void
}

interface Tooltip {
  room: ZoneMapRoom
  x: number
  y: number
}

const Z_DIRS = new Set(['up', 'down'])

export const ZoneMap: React.FC<ZoneMapProps> = ({ refreshToken, currentRoomId, onNavigate, onBreachEncountersChange, onVendorPresenceChange, onTransitPresenceChange }) => {
  const [mapData, setMapData] = useState<ZoneMapData | null>(null)
  const [tooltip, setTooltip] = useState<Tooltip | null>(null)
  const [zoom, setZoom] = useState(1.25)
  const [panOffset, setPanOffset] = useState<[number, number]>([0, 0])
  const svgRef = useRef<SVGSVGElement>(null)
  const containerRef = useRef<HTMLDivElement>(null)
  const [isPanningState, setIsPanningState] = useState(false)
  const isPanning = useRef(false)
  const panStart = useRef<{ clientX: number; clientY: number; panX: number; panY: number } | null>(null)

  // Fetch zone map data
  useEffect(() => {
    apiJson<ZoneMapData>('/api/grid/zone_map')
      .then(data => {
        setMapData(data)
        setPanOffset([0, 0])
        onBreachEncountersChange?.(data.breach_encounters || [], data.deck_status || { equipped: false, fried: false })
        onVendorPresenceChange?.(data.has_vendor ?? false)
        onTransitPresenceChange?.(data.has_transit ?? false)
      })
      .catch(err => console.error('Zone map fetch failed:', err))
  // eslint-disable-next-line react-hooks/exhaustive-deps -- callback ref change should not re-trigger fetch; refreshToken controls cadence
  }, [refreshToken])

  // Zone-level presence updates via ZoneChannel
  const handlePresenceUpdate = useCallback((event: { hackr_alias: string; from_room_id: number; to_room_id: number }) => {
    setMapData(prev => {
      if (!prev) return prev
      const roomIds = new Set(prev.rooms.map(r => r.id))
      // Only update if the event involves rooms in this zone
      if (!roomIds.has(event.from_room_id) && !roomIds.has(event.to_room_id)) return prev

      return {
        ...prev,
        rooms: prev.rooms.map(r => {
          if (r.id === event.from_room_id && r.hackr_aliases.includes(event.hackr_alias)) {
            const aliases = r.hackr_aliases.filter(a => a !== event.hackr_alias)
            return { ...r, hackr_aliases: aliases, hackr_count: aliases.length }
          }
          if (r.id === event.to_room_id && r.visited && !r.hackr_aliases.includes(event.hackr_alias)) {
            const aliases = [...r.hackr_aliases, event.hackr_alias]
            return { ...r, hackr_aliases: aliases, hackr_count: aliases.length }
          }
          return r
        })
      }
    })
  }, [])

  useZonePresence({
    enabled: !!currentRoomId,
    refreshToken,
    onPresenceUpdate: handlePresenceUpdate
  })

  // Build render list: visited rooms + unvisited rooms adjacent to current room
  const renderList = useMemo(() => {
    if (!mapData || !currentRoomId) return []
    // Find IDs of rooms reachable from current room (one hop)
    const adjacentIds = new Set<number>()
    for (const exit of mapData.exits) {
      if (exit.from_room_id === currentRoomId) adjacentIds.add(exit.to_room_id)
    }
    const visible = mapData.rooms.filter(r => r.visited || adjacentIds.has(r.id))
    return buildRenderList(visible)
  }, [mapData, currentRoomId])

  // Room index for connector lookups
  const roomById = useMemo(() => {
    if (!mapData) return new Map<number, ZoneMapRoom>()
    return new Map(mapData.rooms.map(r => [r.id, r]))
  }, [mapData])

  // Exits from current room: roomId → direction (for click-to-move)
  // Includes both intra-zone exits and cross-zone ghost room exits
  const navigableExits = useMemo(() => {
    if (!mapData || !currentRoomId) return new Map<number, string>()
    const map = new Map<number, string>()
    for (const exit of mapData.exits) {
      if (exit.from_room_id === currentRoomId) {
        map.set(exit.to_room_id, exit.direction)
      }
    }
    for (const ghost of mapData.ghost_rooms) {
      if (ghost.local_room_id === currentRoomId) {
        map.set(ghost.id, ghost.direction)
      }
    }
    return map
  }, [mapData, currentRoomId])

  // Available directions from current room (for nav buttons)
  const availableDirections = useMemo(() => new Set(navigableExits.values()), [navigableExits])

  // Ghost room positions: compute from local room position + direction vector
  const ghostRenderList = useMemo(() => {
    if (!mapData) return []
    const result: { ghost: ZoneMapGhostRoom; cx: number; cy: number; hw: number; hh: number; navigable: boolean }[] = []
    for (const ghost of mapData.ghost_rooms) {
      const localRoom = roomById.get(ghost.local_room_id)
      if (!localRoom || !localRoom.visited) continue
      if (Z_DIRS.has(ghost.direction)) continue // vertical ghosts handled separately
      const vec = DIRECTION_VECTORS[ghost.direction]
      if (!vec) continue
      const gx = localRoom.map_x + vec[0]
      const gy = localRoom.map_y + vec[1]
      const center = iso(gx, gy, localRoom.map_z)
      result.push({
        ghost,
        cx: center[0],
        cy: center[1],
        hw: ISO_TILE_W / 2,
        hh: ISO_TILE_H / 2,
        navigable: navigableExits.has(ghost.id)
      })
    }
    return result
  }, [mapData, roomById, navigableExits])

  // Horizontal connectors between rendered rooms (visited + adjacent-to-current)
  const connectors = useMemo(() => {
    if (!mapData || !currentRoomId) return []
    const visitedIds = new Set(mapData.rooms.filter(r => r.visited).map(r => r.id))
    const adjacentIds = new Set<number>()
    for (const exit of mapData.exits) {
      if (exit.from_room_id === currentRoomId) adjacentIds.add(exit.to_room_id)
    }
    const renderedIds = new Set([...visitedIds, ...adjacentIds])
    const seen = new Set<string>()
    const result: { key: string; x1: number; y1: number; x2: number; y2: number }[] = []

    for (const exit of mapData.exits) {
      if (Z_DIRS.has(exit.direction)) continue
      if (!renderedIds.has(exit.from_room_id) || !renderedIds.has(exit.to_room_id)) continue
      const pairKey = [Math.min(exit.from_room_id, exit.to_room_id), Math.max(exit.from_room_id, exit.to_room_id)].join('-')
      if (seen.has(pairKey)) continue
      seen.add(pairKey)

      const from = roomById.get(exit.from_room_id)
      const to = roomById.get(exit.to_room_id)
      if (!from || !to) continue

      const pts = connectorEndpoints(from, to)
      if (pts) result.push({ key: pairKey, ...pts })
    }
    return result
  }, [mapData, roomById, currentRoomId])

  // Vertical connectors (up/down between z-levels)
  const verticalConnectors = useMemo(() => {
    if (!mapData) return []
    const visitedIds = new Set(mapData.rooms.filter(r => r.visited).map(r => r.id))
    const seen = new Set<string>()
    const result: { key: string; x1: number; y1: number; x2: number; y2: number; mx: number; my: number; isUp: boolean }[] = []

    for (const exit of mapData.exits) {
      if (!Z_DIRS.has(exit.direction)) continue
      if (!visitedIds.has(exit.from_room_id) || !visitedIds.has(exit.to_room_id)) continue
      const pairKey = [Math.min(exit.from_room_id, exit.to_room_id), Math.max(exit.from_room_id, exit.to_room_id)].join('-')
      if (seen.has(pairKey)) continue
      seen.add(pairKey)

      const from = roomById.get(exit.from_room_id)
      const to = roomById.get(exit.to_room_id)
      if (!from || !to) continue

      const p1 = iso(from.map_x, from.map_y, from.map_z)
      const p2 = iso(to.map_x, to.map_y, to.map_z)
      // Direction relative to hackr's current z-level
      const otherZ = from.is_current ? to.map_z : to.is_current ? from.map_z : Math.max(from.map_z, to.map_z)
      const currentZ = mapData!.z_level
      const isUp = otherZ > currentZ

      result.push({
        key: pairKey,
        x1: p1[0], y1: p1[1],
        x2: p2[0], y2: p2[1],
        mx: (p1[0] + p2[0]) / 2,
        my: (p1[1] + p2[1]) / 2,
        isUp
      })
    }
    return result
  }, [mapData, roomById])

  // Compute viewBox
  const baseViewBox = useMemo(() => {
    // Include ghost rooms in viewBox calculation
    const allPoints = [...renderList]
    for (const g of ghostRenderList) {
      allPoints.push({
        room: {} as ZoneMapRoom,
        depth: 0,
        points: {
          top: [g.cx, g.cy - g.hh],
          right: [g.cx + g.hw, g.cy],
          bottom: [g.cx, g.cy + g.hh],
          left: [g.cx - g.hw, g.cy],
          center: [g.cx, g.cy]
        }
      })
    }
    return computeViewBox(allPoints)
  }, [renderList, ghostRenderList])

  const viewBox = useMemo(() => {
    const w = baseViewBox.w / zoom
    const h = baseViewBox.h / zoom
    const cx = baseViewBox.x + baseViewBox.w / 2
    const cy = baseViewBox.y + baseViewBox.h / 2
    return {
      x: cx - w / 2 + panOffset[0],
      y: cy - h / 2 + panOffset[1],
      w, h
    }
  }, [baseViewBox, zoom, panOffset])

  // Pan handlers
  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    if (e.button !== 0) return
    if ((e.target as Element).closest('[data-room-id]')) return
    isPanning.current = true
    setIsPanningState(true)
    panStart.current = { clientX: e.clientX, clientY: e.clientY, panX: panOffset[0], panY: panOffset[1] }
  }, [panOffset])

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (!isPanning.current || !panStart.current || !svgRef.current || !containerRef.current) return
    const rect = containerRef.current.getBoundingClientRect()
    const scaleX = viewBox.w / rect.width
    const scaleY = viewBox.h / rect.height
    const dx = (e.clientX - panStart.current.clientX) * scaleX
    const dy = (e.clientY - panStart.current.clientY) * scaleY
    // Direct viewBox mutation during drag for performance
    const vb = `${panStart.current.panX - dx + viewBox.x - panOffset[0]} ${panStart.current.panY - dy + viewBox.y - panOffset[1]} ${viewBox.w} ${viewBox.h}`
    svgRef.current.setAttribute('viewBox', vb)
  }, [viewBox, panOffset])

  const handleMouseUp = useCallback((e: React.MouseEvent) => {
    if (!isPanning.current || !panStart.current || !containerRef.current) return
    isPanning.current = false
    setIsPanningState(false)
    const rect = containerRef.current.getBoundingClientRect()
    const scaleX = viewBox.w / rect.width
    const scaleY = viewBox.h / rect.height
    const dx = (e.clientX - panStart.current.clientX) * scaleX
    const dy = (e.clientY - panStart.current.clientY) * scaleY
    setPanOffset([panStart.current.panX - dx, panStart.current.panY - dy])
    panStart.current = null
  }, [viewBox])

  // Zoom handler
  const handleWheel = useCallback((e: React.WheelEvent) => {
    e.preventDefault()
    const delta = e.deltaY > 0 ? 0.9 : 1.1
    setZoom(prev => Math.max(0.5, Math.min(4.0, prev * delta)))
  }, [])

  // Room click
  const handleRoomClick = useCallback((room: ZoneMapRoom, e: React.MouseEvent) => {
    e.stopPropagation()
    const direction = navigableExits.get(room.id)
    if (direction && onNavigate) {
      setTooltip(null)
      onNavigate(direction)
    } else {
      setTooltip(prev =>
        prev?.room.id === room.id ? null : { room, x: e.clientX, y: e.clientY }
      )
    }
  }, [navigableExits, onNavigate])

  const dismissTooltip = useCallback(() => setTooltip(null), [])

  if (!mapData) {
    return (
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        height: '100%', color: '#555', fontSize: '0.85em'
      }}>
        Loading zone map...
      </div>
    )
  }

  return (
    <div
      ref={containerRef}
      style={{ width: '100%', height: '100%', position: 'relative', overflow: 'hidden', background: '#080808' }}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={() => { isPanning.current = false; setIsPanningState(false); panStart.current = null }}
      onWheel={handleWheel}
      onClick={dismissTooltip}
    >
      <style>{`
        @keyframes pulse-marker {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.4; }
        }
      `}</style>

      {/* Zone label */}
      <div style={{
        position: 'absolute', top: 8, left: 12, zIndex: 10,
        fontSize: '0.8em', pointerEvents: 'none'
      }}>
        <span style={{ color: '#888' }}>{mapData.zone.region_name}</span>
        <span style={{ color: '#444', margin: '0 6px' }}>&gt;</span>
        <span style={{ color: '#f0abfc', fontWeight: 'bold' }}>{mapData.zone.name}</span>
        {mapData.z_levels.length > 1 && (
          <span style={{ marginLeft: 8, color: '#a78bfa' }}>Z:{mapData.z_level}</span>
        )}
      </div>

      <svg
        ref={svgRef}
        viewBox={`${viewBox.x} ${viewBox.y} ${viewBox.w} ${viewBox.h}`}
        style={{ width: '100%', height: '100%', cursor: isPanningState ? 'grabbing' : 'grab' }}
      >
        {/* Connectors (render before tiles for correct depth) */}
        {connectors.map(c => (
          <line
            key={c.key}
            x1={c.x1} y1={c.y1} x2={c.x2} y2={c.y2}
            stroke="#444" strokeWidth={2}
          />
        ))}

        {/* Tiles — depth-sorted back-to-front */}
        {renderList.map(({ room, points }: RenderRoom) => {
          const isCurrent = room.id === currentRoomId
          const isNavigable = navigableExits.has(room.id)
          const isUnexplored = !room.visited && isNavigable
          const reach = isCurrent ? 'current' as const
            : isUnexplored ? 'unexplored' as const
              : isNavigable ? 'adjacent' as const
                : 'distant' as const
          const styles = tileStyles(room, reach)
          const name = isUnexplored ? '?' : (room.name.length > 14 ? room.name.substring(0, 13) + '\u2026' : room.name)

          return (
            <g key={room.id} data-room-id={room.id}
              onClick={(e) => handleRoomClick(room, e)}
              style={{ cursor: isNavigable ? 'pointer' : 'default', opacity: styles.opacity }}>
              {/* Left wall */}
              <polygon
                points={isoPts([points.left, points.bottom,
                  [points.bottom[0], points.bottom[1] + ISO_WALL_H],
                  [points.left[0], points.left[1] + ISO_WALL_H]])}
                fill={styles.leftFill} stroke={styles.sideStroke} strokeWidth={0.5}
              />
              {/* Right wall */}
              <polygon
                points={isoPts([points.bottom, points.right,
                  [points.right[0], points.right[1] + ISO_WALL_H],
                  [points.bottom[0], points.bottom[1] + ISO_WALL_H]])}
                fill={styles.rightFill} stroke={styles.sideStroke} strokeWidth={0.5}
              />
              {/* Top face (diamond) */}
              <polygon
                points={isoPts([points.top, points.right, points.bottom, points.left])}
                fill={styles.topFill} stroke={styles.topStroke} strokeWidth={styles.topStrokeW}
              />
              {/* Room name */}
              <text
                x={points.center[0]} y={points.center[1] - 4}
                textAnchor="middle" fill={styles.nameColor}
                fontFamily="'Courier New', monospace" fontSize="11px"
                pointerEvents="none"
              >
                {name}
              </text>
              {/* Room type */}
              {room.room_type && room.room_type !== 'standard' && (
                <text
                  x={points.center[0]} y={points.center[1] + 12}
                  textAnchor="middle" fill="#555"
                  fontFamily="'Courier New', monospace" fontSize="8px"
                  pointerEvents="none"
                >
                  {room.room_type}
                </text>
              )}

              {/* "You are here" pulsing marker */}
              {isCurrent && (
                <polygon
                  points={isoPts([points.top, points.right, points.bottom, points.left])}
                  fill="none" stroke="#22d3ee" strokeWidth={3}
                  style={{
                    animation: 'pulse-marker 2s ease-in-out infinite',
                    filter: 'drop-shadow(0 0 6px #22d3ee)'
                  }}
                />
              )}

              {/* Hackr presence dots */}
              {room.hackr_count > 0 && !isCurrent && (
                <circle
                  cx={points.center[0]}
                  cy={points.top[1] - 8}
                  r={4}
                  fill="#fbbf24"
                  stroke="#0a0a0a" strokeWidth={1}
                />
              )}
              {room.hackr_count > 1 && !isCurrent && (
                <text
                  x={points.center[0]} y={points.top[1] - 16}
                  textAnchor="middle" fill="#fbbf24"
                  fontFamily="'Courier New', monospace" fontSize="8px"
                  pointerEvents="none"
                >
                  {room.hackr_count}
                </text>
              )}
            </g>
          )
        })}

        {/* Ghost rooms (cross-zone boundary) */}
        {ghostRenderList.map(({ ghost, cx, cy, hw, hh, navigable }) => {
          const top: [number, number] = [cx, cy - hh]
          const right: [number, number] = [cx + hw, cy]
          const bottom: [number, number] = [cx, cy + hh]
          const left: [number, number] = [cx - hw, cy]
          const ghostName = ghost.name.length > 12 ? ghost.name.substring(0, 11) + '\u2026' : ghost.name

          // Connector from local room to ghost
          const localRoom = roomById.get(ghost.local_room_id)
          const conn = localRoom ? connectorEndpoints(localRoom, {
            map_x: localRoom.map_x + (DIRECTION_VECTORS[ghost.direction]?.[0] || 0),
            map_y: localRoom.map_y + (DIRECTION_VECTORS[ghost.direction]?.[1] || 0),
            map_z: localRoom.map_z
          } as ZoneMapRoom) : null

          return (
            <g key={`ghost-${ghost.id}`}
              opacity={navigable ? 0.5 : 0.25}
              style={{ cursor: navigable ? 'pointer' : 'default' }}
              onClick={(e) => {
                if (navigable && onNavigate) {
                  e.stopPropagation()
                  setTooltip(null)
                  onNavigate(ghost.direction)
                }
              }}
            >
              {/* Connector line */}
              {conn && (
                <line x1={conn.x1} y1={conn.y1} x2={conn.x2} y2={conn.y2}
                  stroke="#555" strokeWidth={1.5} strokeDasharray="6,4" />
              )}
              {/* Top face (dashed diamond) */}
              <polygon
                points={isoPts([top, right, bottom, left])}
                fill="#0e0e0e" stroke="#555" strokeWidth={1} strokeDasharray="4,3"
              />
              {/* Name */}
              <text x={cx} y={cy - 2} textAnchor="middle" fill="#666"
                fontFamily="'Courier New', monospace" fontSize="9px" pointerEvents="none">
                {ghostName}
              </text>
              {/* Zone name */}
              <text x={cx} y={cy + 12} textAnchor="middle" fill="#444"
                fontFamily="'Courier New', monospace" fontSize="7px" pointerEvents="none">
                {ghost.zone_name}
              </text>
            </g>
          )
        })}

        {/* Vertical connectors (between z-levels, rendered on top) */}
        {verticalConnectors.map(vc => {
          const color = vc.isUp ? '#a78bfa' : '#fb923c'
          return (
            <g key={`vert-${vc.key}`}>
              {/* Glow line */}
              <line
                x1={vc.x1} y1={vc.y1} x2={vc.x2} y2={vc.y2}
                stroke={color} strokeWidth={4} opacity={0.08}
              />
              {/* Dashed line */}
              <line
                x1={vc.x1} y1={vc.y1} x2={vc.x2} y2={vc.y2}
                stroke={color} strokeWidth={2} strokeDasharray="8,5" opacity={0.35}
              />
              {/* Midpoint badge */}
              <circle
                cx={vc.mx} cy={vc.my} r={10}
                fill="#0a0a0a" stroke={color} strokeWidth={1.5} opacity={0.5}
              />
              <text
                x={vc.mx} y={vc.my + 4}
                textAnchor="middle" fill={color}
                fontFamily="'Courier New', monospace" fontSize="12px" fontWeight="bold"
                opacity={0.5} pointerEvents="none"
              >
                {vc.isUp ? '\u2191' : '\u2193'}
              </text>
            </g>
          )
        })}
      </svg>

      {/* Navigation buttons */}
      {onNavigate && (
        <NavButtons
          availableDirections={availableDirections}
          onNavigate={(dir) => { setTooltip(null); onNavigate(dir) }}
        />
      )}

      {/* Tooltip */}
      {tooltip && (
        <div style={{
          position: 'fixed',
          left: tooltip.x + 12,
          top: tooltip.y - 10,
          background: '#1a1a1a',
          border: '1px solid #444',
          borderRadius: '4px',
          padding: '8px 12px',
          fontSize: '0.8em',
          color: '#d0d0d0',
          pointerEvents: 'none',
          zIndex: 100,
          maxWidth: '250px'
        }}>
          <div style={{ color: tileColor(tooltip.room), fontWeight: 'bold' }}>
            {tooltip.room.name}
          </div>
          {tooltip.room.room_type && tooltip.room.room_type !== 'standard' && (
            <div style={{ color: '#888', fontSize: '0.9em' }}>{tooltip.room.room_type}</div>
          )}
          {tooltip.room.hackr_count > 0 && (
            <div style={{ color: '#fbbf24', fontSize: '0.9em', marginTop: '4px' }}>
              {tooltip.room.hackr_aliases.join(', ')}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// --- Compact compass rose + vertical nav ---

const NAV_GRID: { dir: string; label: string; row: number; col: number }[] = [
  { dir: 'northwest', label: 'NW', row: 0, col: 0 },
  { dir: 'north', label: 'N', row: 0, col: 1 },
  { dir: 'northeast', label: 'NE', row: 0, col: 2 },
  { dir: 'west', label: 'W', row: 1, col: 0 },
  { dir: 'east', label: 'E', row: 1, col: 2 },
  { dir: 'southwest', label: 'SW', row: 2, col: 0 },
  { dir: 'south', label: 'S', row: 2, col: 1 },
  { dir: 'southeast', label: 'SE', row: 2, col: 2 }
]

const NAV_VERTICAL: { dir: string; label: string }[] = [
  { dir: 'up', label: '\u2191' },
  { dir: 'down', label: '\u2193' }
]

const NavButtons: React.FC<{
  availableDirections: Set<string>
  onNavigate: (dir: string) => void
}> = ({ availableDirections, onNavigate }) => {
  return (
    <div style={{
      position: 'absolute',
      bottom: 10,
      left: 10,
      zIndex: 15,
      display: 'flex',
      gap: '4px',
      alignItems: 'flex-end'
    }}>
      {/* Compass rose */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(3, 28px)',
        gridTemplateRows: 'repeat(3, 28px)',
        gap: '2px'
      }}>
        {NAV_GRID.map(({ dir, label, row, col }) => {
          const available = availableDirections.has(dir)
          return (
            <button
              key={dir}
              onClick={(e) => { e.stopPropagation(); if (available) onNavigate(dir) }}
              disabled={!available}
              style={{
                gridRow: row + 1,
                gridColumn: col + 1,
                width: 28,
                height: 28,
                background: available ? '#1a1a1a' : '#0e0e0e',
                color: available ? '#22d3ee' : '#333',
                border: `1px solid ${available ? '#333' : '#1a1a1a'}`,
                borderRadius: '3px',
                fontSize: '0.6em',
                fontFamily: '\'Courier New\', monospace',
                fontWeight: 'bold',
                cursor: available ? 'pointer' : 'default',
                padding: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              {label}
            </button>
          )
        })}
      </div>

      {/* Up / Down */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '2px' }}>
        {NAV_VERTICAL.map(({ dir, label }) => {
          const available = availableDirections.has(dir)
          const color = dir === 'up' ? '#a78bfa' : '#fb923c'
          return (
            <button
              key={dir}
              onClick={(e) => { e.stopPropagation(); if (available) onNavigate(dir) }}
              disabled={!available}
              style={{
                width: 28,
                height: 28,
                background: available ? '#1a1a1a' : '#0e0e0e',
                color: available ? color : '#333',
                border: `1px solid ${available ? '#333' : '#1a1a1a'}`,
                borderRadius: '3px',
                fontSize: '0.85em',
                fontFamily: '\'Courier New\', monospace',
                fontWeight: 'bold',
                cursor: available ? 'pointer' : 'default',
                padding: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              {label}
            </button>
          )
        })}
      </div>
    </div>
  )
}
