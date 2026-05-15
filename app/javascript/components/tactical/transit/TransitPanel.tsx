import React, { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { apiJson } from '~/utils/apiClient'
import {
  TransitData, TransitRoute, SlipstreamRoute,
  PrivateTransitType, PrivateDestination, TransitJourney
} from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'

interface TransitPanelProps {
  visible: boolean
  refreshToken: number
  onCommand: (cmd: string) => void
  onClose: () => void
}

type TabKey = 'local' | 'private' | 'slipstream'

const HEAT_COLORS: Record<string, string> = {
  cold: '#34d399',
  warm: '#fbbf24',
  hot: '#f97316',
  burning: '#ef4444'
}

export const TransitPanel: React.FC<TransitPanelProps> = ({
  visible, refreshToken, onCommand, onClose
}) => {
  const { executing } = useTactical()
  const [isRendered, setIsRendered] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [data, setData] = useState<TransitData | null>(null)
  const [activeTab, setActiveTab] = useState<TabKey>('local')
  const hadJourneyRef = useRef(false)

  // Slide animation: mount first, then open; close first, then unmount
  // Double-rAF ensures browser paints the closed state before transitioning to open
  useEffect(() => {
    if (visible) {
      setIsRendered(true) // eslint-disable-line react-hooks/set-state-in-effect -- must mount before animating
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setIsOpen(true))
      })
      return () => cancelAnimationFrame(raf)
    } else {
      setIsOpen(false)
      hadJourneyRef.current = false
      const timer = setTimeout(() => setIsRendered(false), 300)
      return () => clearTimeout(timer)
    }
  }, [visible])

  // Fetch transit data when panel is rendered
  useEffect(() => {
    if (isRendered) {
      apiJson<TransitData>('/api/grid/transit').then(fresh => {
        // Auto-close panel when journey ends (disembark, arrival, abandon)
        if (hadJourneyRef.current && !fresh.current_journey) {
          onClose()
        }
        hadJourneyRef.current = fresh.current_journey != null
        setData(fresh)
      }).catch(console.error)
    }
  }, [refreshToken, isRendered, onClose])

  // Derive available tabs from data
  const availableTabs = useMemo(() => {
    if (!data) return []
    const tabs: { key: TabKey; label: string }[] = []
    if (data.local_routes.length > 0) tabs.push({ key: 'local', label: 'LOCAL' })
    if (data.private_types.length > 0) tabs.push({ key: 'private', label: 'PRIVATE' })
    if (data.slipstream_routes.some(r => r.boardable)) tabs.push({ key: 'slipstream', label: 'SLIPSTREAM' })
    return tabs
  }, [data])

  // Reset active tab to first available when tabs change
  useEffect(() => {
    if (availableTabs.length > 0 && !availableTabs.find(t => t.key === activeTab)) {
      setActiveTab(availableTabs[0].key) // eslint-disable-line react-hooks/set-state-in-effect -- tab must sync with available data
    }
  }, [availableTabs, activeTab])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onClose()
  }, [onClose])

  if (!isRendered) return null

  const hasJourney = data?.current_journey != null

  return (
    <>
      {/* Backdrop */}
      <div
        onClick={handleBackdropClick}
        style={{
          position: 'absolute',
          inset: 0,
          zIndex: 29,
          background: isOpen ? 'rgba(0,0,0,0.2)' : 'transparent',
          transition: 'background 300ms ease-out'
        }}
      />

      {/* Panel */}
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          height: '50%',
          zIndex: 30,
          transform: isOpen ? 'translateY(0%)' : 'translateY(-100%)',
          transition: 'transform 300ms ease-out',
          display: 'flex',
          flexDirection: 'column',
          background: '#0d0d0d',
          borderBottom: '2px solid #22d3ee',
          borderRadius: '0 0 8px 8px',
          fontFamily: '\'Courier New\', monospace'
        }}
      >
        {/* Header */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '8px 12px',
          background: '#111',
          borderBottom: '1px solid #333',
          flexShrink: 0
        }}>
          <div>
            <span style={{ color: '#22d3ee', fontWeight: 'bold', fontSize: '0.8em', letterSpacing: '1px' }}>
              TRANSIT
            </span>
            {data?.current_region && (
              <>
                <span style={{ color: '#444', margin: '0 8px' }}>::</span>
                <span style={{ color: '#d0d0d0', fontSize: '0.8em' }}>{data.current_region.name}</span>
              </>
            )}
            {hasJourney && (
              <span style={{ color: '#f97316', fontSize: '0.65em', marginLeft: '8px' }}>IN TRANSIT</span>
            )}
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'transparent',
              color: '#888',
              border: '1px solid #444',
              padding: '3px 10px',
              fontSize: '0.7em',
              cursor: 'pointer',
              borderRadius: '3px',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            CLOSE
          </button>
        </div>

        {/* Tab bar (hidden during active journey) */}
        {!hasJourney && availableTabs.length > 0 && (
          <div style={{
            display: 'flex',
            borderBottom: '1px solid #333',
            background: '#0f0f0f',
            flexShrink: 0
          }}>
            {availableTabs.map(tab => {
              const tabColor = tab.key === 'local' ? '#34d399'
                : tab.key === 'private' ? '#fbbf24'
                  : '#a78bfa'
              return (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  style={{
                    flex: 1,
                    background: activeTab === tab.key ? '#1a1a1a' : 'transparent',
                    color: activeTab === tab.key ? tabColor : '#666',
                    border: 'none',
                    borderBottom: activeTab === tab.key ? `2px solid ${tabColor}` : '2px solid transparent',
                    padding: '6px 10px',
                    fontSize: '0.7em',
                    fontFamily: '\'Courier New\', monospace',
                    cursor: 'pointer',
                    fontWeight: activeTab === tab.key ? 'bold' : 'normal',
                    letterSpacing: '0.5px'
                  }}
                >
                  {tab.label}
                </button>
              )
            })}
          </div>
        )}

        {/* Content */}
        <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', overflowX: 'hidden', padding: '8px 10px' }}>
          {!data ? (
            <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>
          ) : hasJourney ? (
            <JourneySection journey={data.current_journey!} onCommand={onCommand} executing={executing} />
          ) : availableTabs.length === 0 ? (
            <div style={{ color: '#555', fontSize: '0.8em' }}>No transit options available here.</div>
          ) : (
            <>
              {activeTab === 'local' && (
                <LocalSection routes={data.local_routes} onCommand={onCommand} executing={executing} />
              )}
              {activeTab === 'private' && (
                <PrivateSection
                  types={data.private_types}
                  destinations={data.private_destinations}
                  onCommand={onCommand}
                  executing={executing}
                />
              )}
              {activeTab === 'slipstream' && (
                <SlipstreamSection
                  routes={data.slipstream_routes.filter(r => r.boardable)}
                  heat={data.slipstream_heat}
                  heatTier={data.slipstream_heat_tier}
                  onCommand={onCommand}
                  executing={executing}
                />
              )}
            </>
          )}
        </div>
      </div>
    </>
  )
}

// --- Active Journey ---

const JourneySection: React.FC<{
  journey: TransitJourney
  onCommand: (cmd: string) => void
  executing: boolean
}> = ({ journey, onCommand, executing }) => {
  const isSlipstream = journey.journey_type === 'slipstream'
  const isLocalPublic = journey.journey_type === 'local_public'
  const typeColor = isSlipstream ? '#a78bfa' : '#34d399'
  const typeLabel = isSlipstream ? 'SLIPSTREAM' : journey.journey_type === 'local_private' ? 'PRIVATE' : 'LOCAL'

  return (
    <div style={{ fontSize: '0.75em' }}>
      {/* Journey header */}
      <div style={{ marginBottom: '10px' }}>
        <span style={{ color: typeColor, fontWeight: 'bold', letterSpacing: '1px' }}>[{typeLabel}]</span>
        {journey.route_name && (
          <span style={{ color: '#d0d0d0', marginLeft: '8px' }}>{journey.route_name}</span>
        )}
        {!isSlipstream && journey.direction === 'reverse' && (
          <span style={{ color: '#888', fontSize: '0.85em', marginLeft: '6px' }}>(REV)</span>
        )}
      </div>

      {/* Breach mid-journey warning */}
      {journey.breach_mid_journey && (
        <div style={{
          padding: '6px 8px',
          marginBottom: '10px',
          border: '1px solid #f87171',
          borderRadius: '3px',
          color: '#f87171',
          fontSize: '0.9em'
        }}>
          BREACH IN PROGRESS — resolve before continuing transit
        </div>
      )}

      {/* Slipstream leg progress */}
      {isSlipstream && (
        <div style={{ marginBottom: '10px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
            <span style={{ color: '#888' }}>Progress</span>
            <span style={{ color: '#a78bfa' }}>{journey.legs_completed}/{journey.total_legs} legs</span>
          </div>
          <div style={{ height: 4, background: '#222', borderRadius: 2 }}>
            <div style={{
              width: journey.total_legs > 0 ? `${(journey.legs_completed / journey.total_legs) * 100}%` : '0%',
              height: '100%',
              background: '#a78bfa',
              borderRadius: 2,
              transition: 'width 0.3s'
            }} />
          </div>
          {journey.current_leg && (
            <div style={{ color: '#888', fontSize: '0.9em', marginTop: '4px' }}>
              Current leg: <span style={{ color: '#d0d0d0' }}>{journey.current_leg.name}</span>
            </div>
          )}
        </div>
      )}

      {/* Local transit current + next stop */}
      {!isSlipstream && journey.current_stop && (
        <div style={{ marginBottom: '10px' }}>
          <div style={{ color: '#888' }}>
            Current stop: <span style={{ color: '#d0d0d0' }}>{journey.current_stop.name}</span>
          </div>
          {journey.next_stop ? (
            <div style={{ color: '#888', fontSize: '0.9em', marginTop: '2px' }}>
              Next stop: <span style={{ color: '#22d3ee' }}>{journey.next_stop}</span>
            </div>
          ) : (
            <div style={{ color: '#fbbf24', fontSize: '0.9em', marginTop: '2px' }}>
              End of the line
            </div>
          )}
        </div>
      )}

      {/* Slipstream fork choices */}
      {isSlipstream && journey.pending_fork && journey.current_leg_forks && (
        <div style={{
          padding: '8px',
          marginBottom: '10px',
          border: '1px solid #fbbf24',
          borderRadius: '3px',
          background: '#1a1a0a'
        }}>
          <div style={{ color: '#fbbf24', fontWeight: 'bold', marginBottom: '6px' }}>FORK CHOICE</div>
          {journey.current_leg_forks.map(fork => (
            <div key={fork.key} style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '4px 0',
              borderBottom: '1px solid #1a1a1a'
            }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#d0d0d0' }}>{fork.label}</div>
                {fork.description && (
                  <div style={{ color: '#666', fontSize: '0.9em' }}>{fork.description}</div>
                )}
              </div>
              <button
                onClick={() => onCommand(`choose ${fork.key}`)}
                disabled={executing}
                style={actionBtnStyle('#fbbf24', executing)}
              >
                CHOOSE
              </button>
            </div>
          ))}
        </div>
      )}

      {/* Action buttons */}
      <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
        {!journey.breach_mid_journey && (
          <>
            {isSlipstream && !journey.pending_fork && (
              <button onClick={() => onCommand('advance')} disabled={executing} style={actionBtnStyle('#a78bfa', executing)}>
                ADVANCE
              </button>
            )}
            {!isSlipstream && (
              <button onClick={() => onCommand('wait')} disabled={executing} style={actionBtnStyle('#34d399', executing)}>
                WAIT
              </button>
            )}
            {isLocalPublic && (
              <button onClick={() => onCommand('disembark')} disabled={executing} style={actionBtnStyle('#fbbf24', executing)}>
                DISEMBARK
              </button>
            )}
          </>
        )}
        <button onClick={() => onCommand('abandon')} disabled={executing} style={actionBtnStyle('#f87171', executing)}>
          ABANDON
        </button>
        <button onClick={() => onCommand('status')} disabled={executing} style={actionBtnStyle('#888', executing)}>
          STATUS
        </button>
      </div>
    </div>
  )
}

// --- Local Public Routes ---

const LocalSection: React.FC<{
  routes: TransitRoute[]
  onCommand: (cmd: string) => void
  executing: boolean
}> = ({ routes, onCommand, executing }) => {
  if (routes.length === 0) {
    return <div style={{ color: '#555', fontSize: '0.8em' }}>No local routes at this stop.</div>
  }

  // Group routes by transit type
  const grouped = routes.reduce<Record<string, TransitRoute[]>>((acc, r) => {
    const key = r.transit_type.name
    if (!acc[key]) acc[key] = []
    acc[key].push(r)
    return acc
  }, {})

  return (
    <div style={{ fontSize: '0.75em' }}>
      {Object.entries(grouped).map(([typeName, typeRoutes]) => (
        <div key={typeName} style={{ marginBottom: '10px' }}>
          <div style={{ color: '#34d399', fontWeight: 'bold', marginBottom: '4px', fontSize: '0.9em' }}>
            [{typeRoutes[0].transit_type.icon_key || 'TRANSIT'}] {typeName}
          </div>
          {typeRoutes.map(route => (
            <RouteRow key={route.slug} route={route} onCommand={onCommand} executing={executing} />
          ))}
        </div>
      ))}
    </div>
  )
}

const RouteRow: React.FC<{
  route: TransitRoute
  onCommand: (cmd: string) => void
  executing: boolean
}> = ({ route, onCommand, executing }) => {
  const canForward = route.loop_route || !route.at_last_stop
  const canReverse = !route.loop_route && !route.at_first_stop
  const firstStop = route.stops[0]?.name
  const lastStop = route.stops[route.stops.length - 1]?.name

  return (
    <div style={{ borderBottom: '1px solid #1a1a1a', padding: '4px 0' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <span style={{ color: '#22d3ee' }}>{route.name}</span>
          <span style={{ color: '#666', marginLeft: '6px', fontSize: '0.9em' }}>
            {route.stop_count} stops {route.loop_route ? '(loop)' : ''} | {route.transit_type.base_fare} CRED
          </span>
        </div>
        <div style={{ display: 'flex', gap: '3px', flexShrink: 0, alignItems: 'center' }}>
          {canForward && (
            <button
              onClick={() => onCommand(`board ${route.slug}`)}
              disabled={executing}
              style={{ ...dirBtnStyle, ...(executing ? { opacity: 0.5, cursor: 'not-allowed' } : {}) }}
            >
              BOARD {'\u2192'} {lastStop}
            </button>
          )}
          {canReverse && (
            <button
              onClick={() => onCommand(`board ${route.slug} reverse`)}
              disabled={executing}
              style={{ ...dirBtnStyle, ...(executing ? { opacity: 0.5, cursor: 'not-allowed' } : {}) }}
            >
              BOARD {'\u2192'} {firstStop}
            </button>
          )}
        </div>
      </div>
      <div style={{ paddingLeft: '10px', paddingTop: '4px' }}>
        {route.stops.map((stop, i) => (
          <div key={i} style={{ padding: '2px 0', color: stop.is_terminus ? '#fbbf24' : '#888', fontSize: '0.9em' }}>
            {stop.is_terminus ? '\u25C6' : '\u00B7'} {stop.name}
          </div>
        ))}
      </div>
    </div>
  )
}

// --- Private Transit ---

const PrivateSection: React.FC<{
  types: PrivateTransitType[]
  destinations: PrivateDestination[]
  onCommand: (cmd: string) => void
  executing: boolean
}> = ({ types, destinations, onCommand, executing }) => {
  const [selectedType, setSelectedType] = useState<string | null>(null)
  const [selectedDest, setSelectedDest] = useState<string | null>(null)

  // Auto-select first type if only one
  const effectiveType = selectedType || (types.length === 1 ? types[0].slug : null)

  const handleHail = useCallback(() => {
    if (effectiveType && selectedDest) {
      onCommand(`hail ${effectiveType} ${selectedDest}`)
      setSelectedDest(null)
    }
  }, [effectiveType, selectedDest, onCommand])

  if (types.length === 0) {
    return <div style={{ color: '#555', fontSize: '0.8em' }}>No private transit available here.</div>
  }

  return (
    <div style={{ fontSize: '0.75em' }}>
      {/* Type selector */}
      {types.length > 1 && (
        <div style={{ marginBottom: '10px' }}>
          <div style={{ color: '#888', marginBottom: '4px', fontSize: '0.9em' }}>Select transport:</div>
          <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
            {types.map(t => (
              <button
                key={t.slug}
                onClick={() => setSelectedType(t.slug)}
                style={{
                  background: effectiveType === t.slug ? '#1a1a1a' : 'transparent',
                  color: effectiveType === t.slug ? '#fbbf24' : '#888',
                  border: `1px solid ${effectiveType === t.slug ? '#fbbf24' : '#333'}`,
                  borderRadius: '3px',
                  padding: '4px 10px',
                  fontSize: '0.9em',
                  cursor: 'pointer',
                  fontFamily: '\'Courier New\', monospace'
                }}
              >
                {t.name} ({t.base_fare} CRED)
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Single type info */}
      {types.length === 1 && (
        <div style={{ color: '#fbbf24', fontWeight: 'bold', marginBottom: '8px', fontSize: '0.9em' }}>
          [{types[0].icon_key || 'PRIVATE'}] {types[0].name}
          <span style={{ color: '#888', fontWeight: 'normal', marginLeft: '8px' }}>{types[0].base_fare} CRED</span>
        </div>
      )}

      {/* Destination picker */}
      {effectiveType && (
        <>
          <div style={{ color: '#888', marginBottom: '4px', fontSize: '0.9em' }}>Destination:</div>
          {destinations.length === 0 ? (
            <div style={{ color: '#555', fontSize: '0.9em' }}>No destinations available.</div>
          ) : (
            <div>
              {destinations.map(dest => {
                const isSelected = selectedDest === dest.name
                return (
                  <div key={dest.name} style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '4px 0',
                    borderBottom: '1px solid #1a1a1a',
                    cursor: 'pointer',
                    background: isSelected ? '#1a1a1a' : 'transparent'
                  }}
                  onClick={() => setSelectedDest(dest.name)}
                  >
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <span style={{ color: isSelected ? '#fbbf24' : '#d0d0d0' }}>
                        {dest.name}
                      </span>
                      <span style={{ color: '#555', marginLeft: '6px', fontSize: '0.9em' }}>({dest.zone_name})</span>
                    </div>
                    {isSelected && (
                      <button onClick={handleHail} disabled={executing} style={actionBtnStyle('#fbbf24', executing)}>
                        HAIL
                      </button>
                    )}
                  </div>
                )
              })}
            </div>
          )}
        </>
      )}
    </div>
  )
}

// --- Slipstream ---

const SlipstreamSection: React.FC<{
  routes: SlipstreamRoute[]
  heat: number
  heatTier: string
  onCommand: (cmd: string) => void
  executing: boolean
}> = ({ routes, heat, heatTier, onCommand, executing }) => {
  return (
    <div style={{ fontSize: '0.75em' }}>
      {/* Heat indicator */}
      <div style={{ marginBottom: '10px', padding: '6px 8px', border: '1px solid #333', borderRadius: '3px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
          <span style={{ color: '#888' }}>Corridor Heat</span>
          <span style={{ color: HEAT_COLORS[heatTier] || '#888', fontWeight: 'bold' }}>
            {heat}/100 ({heatTier})
          </span>
        </div>
        <div style={{ height: 4, background: '#222', borderRadius: 2 }}>
          <div style={{
            width: `${heat}%`,
            height: '100%',
            background: HEAT_COLORS[heatTier] || '#888',
            borderRadius: 2,
            transition: 'width 0.3s'
          }} />
        </div>
      </div>

      {/* Routes */}
      {routes.length === 0 ? (
        <div style={{ color: '#555' }}>No Slipstream corridors from this region.</div>
      ) : (
        routes.map(route => (
          <div key={route.slug} style={{
            padding: '6px 0',
            borderBottom: '1px solid #1a1a1a'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div>
                  <span style={{ color: '#a78bfa', fontWeight: 'bold' }}>{route.name}</span>
                  <span style={{ color: '#666', marginLeft: '8px', fontSize: '0.9em' }}>CL{route.min_clearance}+</span>
                </div>
                <div style={{ color: '#888', fontSize: '0.9em' }}>
                  {route.origin_region.name} <span style={{ color: '#a78bfa' }}>{'\u2192'}</span> {route.destination_region.name}
                  <span style={{ color: '#555', marginLeft: '8px' }}>{route.leg_count} legs</span>
                </div>
              </div>
              <button
                onClick={() => onCommand(`slipstream ${route.slug}`)}
                disabled={executing}
                style={actionBtnStyle('#a78bfa', executing)}
              >
                BOARD
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  )
}

// --- Shared ---

function actionBtnStyle (color: string, disabled?: boolean): React.CSSProperties {
  return {
    background: disabled ? '#333' : color,
    color: disabled ? '#666' : '#0a0a0a',
    border: 'none',
    borderRadius: '3px',
    padding: '3px 8px',
    fontSize: '0.9em',
    cursor: disabled ? 'not-allowed' : 'pointer',
    fontWeight: 'bold',
    fontFamily: '\'Courier New\', monospace',
    flexShrink: 0
  }
}

const dirBtnStyle: React.CSSProperties = {
  background: '#1a1a1a',
  color: '#34d399',
  border: '1px solid #333',
  borderRadius: '3px',
  padding: '2px 8px',
  fontSize: '0.8em',
  cursor: 'pointer',
  fontFamily: '\'Courier New\', monospace',
  whiteSpace: 'nowrap',
  flexShrink: 0
}
