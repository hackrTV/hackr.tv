import React, { useEffect, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface TransitType {
  slug: string
  name: string
  category: string
  base_fare: number
  icon_key: string | null
}

interface TransitStop {
  position: number
  name: string
  room_slug: string
  is_terminus: boolean
}

interface TransitRoute {
  slug: string
  name: string
  transit_type: TransitType
  region: { slug: string; name: string }
  loop_route: boolean
  stop_count: number
  stops: TransitStop[]
}

interface SlipstreamLeg {
  position: number
  name: string
  has_forks: boolean
}

interface SlipstreamRoute {
  slug: string
  name: string
  origin_region: { slug: string; name: string }
  destination_region: { slug: string; name: string }
  min_clearance: number
  leg_count: number
  legs: SlipstreamLeg[]
}

interface RegionAssignment {
  slug: string
  name: string
  category: string
}

interface TransitResponse {
  slipstream_heat: number
  slipstream_heat_tier: string
  current_region: { slug: string; name: string } | null
  current_journey: object | null
  local_routes: TransitRoute[]
  slipstream_routes: SlipstreamRoute[]
  region_assignments: Record<string, RegionAssignment[]>
}

type TabKey = 'local' | 'slipstream' | 'network'

const HEAT_COLORS: Record<string, string> = {
  cold: '#34d399',
  warm: '#fbbf24',
  hot: '#f97316',
  burning: '#ef4444',
}

const CATEGORY_COLORS: Record<string, string> = {
  public: '#34d399',
  private: '#fbbf24',
  slipstream: '#a78bfa',
}

const TransitPage: React.FC = () => {
  const [data, setData] = useState<TransitResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<TabKey>('local')
  const [expandedRoutes, setExpandedRoutes] = useState<Set<string>>(new Set())

  useEffect(() => {
    apiJson<TransitResponse>('/api/grid/transit')
      .then(json => { setData(json); setLoading(false) })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load transit data')
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading transit map..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load transit data'}
        </div>
      </DefaultLayout>
    )
  }

  const toggleRoute = (slug: string) => {
    setExpandedRoutes(prev => {
      const next = new Set(prev)
      if (next.has(slug)) next.delete(slug)
      else next.add(slug)
      return next
    })
  }

  const tabs: { key: TabKey; label: string }[] = [
    { key: 'local', label: 'Local Transit' },
    { key: 'slipstream', label: 'Slipstream' },
    { key: 'network', label: 'Region Network' },
  ]

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 1100, margin: '30px auto', padding: '0 20px' }}>
        {/* Header */}
        <div style={{ borderBottom: '2px solid #a78bfa', paddingBottom: 15, marginBottom: 20 }}>
          <h1 style={{ color: '#22d3ee', fontFamily: 'monospace', margin: 0, fontSize: '1.4em' }}>
            TRANSIT SYSTEM
          </h1>
          {data.current_region && (
            <span style={{ color: '#9ca3af', fontFamily: 'monospace' }}>
              Current region: <span style={{ color: '#a78bfa' }}>{data.current_region.name}</span>
            </span>
          )}
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: 0, marginBottom: 20 }}>
          {tabs.map(tab => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key)}
              style={{
                background: activeTab === tab.key ? '#1a1a2e' : 'transparent',
                color: activeTab === tab.key ? '#22d3ee' : '#6b7280',
                border: `1px solid ${activeTab === tab.key ? '#22d3ee' : '#333'}`,
                borderBottom: activeTab === tab.key ? '1px solid #1a1a2e' : '1px solid #333',
                padding: '8px 20px',
                fontFamily: 'monospace',
                cursor: 'pointer',
                fontSize: '0.9em',
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Tab Content */}
        {activeTab === 'local' && <LocalTransitTab routes={data.local_routes} expandedRoutes={expandedRoutes} toggleRoute={toggleRoute} />}
        {activeTab === 'slipstream' && <SlipstreamTab routes={data.slipstream_routes} heat={data.slipstream_heat} heatTier={data.slipstream_heat_tier} />}
        {activeTab === 'network' && <NetworkTab assignments={data.region_assignments} />}
      </div>
    </DefaultLayout>
  )
}

const LocalTransitTab: React.FC<{
  routes: TransitRoute[]
  expandedRoutes: Set<string>
  toggleRoute: (slug: string) => void
}> = ({ routes, expandedRoutes, toggleRoute }) => {
  if (routes.length === 0) {
    return <div style={{ color: '#6b7280', fontFamily: 'monospace', padding: 20 }}>No transit routes available from your current location.</div>
  }

  const grouped = routes.reduce<Record<string, TransitRoute[]>>((acc, r) => {
    const key = `${r.transit_type.name} (${r.transit_type.category})`
    if (!acc[key]) acc[key] = []
    acc[key].push(r)
    return acc
  }, {})

  return (
    <div>
      {Object.entries(grouped).map(([typeName, typeRoutes]) => (
        <div key={typeName} style={{ marginBottom: 20 }}>
          <h3 style={{ color: CATEGORY_COLORS[typeRoutes[0].transit_type.category] || '#9ca3af', fontFamily: 'monospace', margin: '0 0 10px 0' }}>
            [{typeRoutes[0].transit_type.icon_key || 'TRANSIT'}] {typeName}
          </h3>
          {typeRoutes.map(route => (
            <div key={route.slug} style={{ border: '1px solid #333', marginBottom: 8, background: '#0a0a0a' }}>
              <div
                onClick={() => toggleRoute(route.slug)}
                style={{ padding: '10px 15px', cursor: 'pointer', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}
              >
                <div>
                  <span style={{ color: '#22d3ee', fontFamily: 'monospace', fontWeight: 'bold' }}>{route.name}</span>
                  <span style={{ color: '#6b7280', fontFamily: 'monospace', marginLeft: 10 }}>
                    {route.stop_count} stops {route.loop_route ? '(loop)' : ''} | {route.transit_type.base_fare} CRED
                  </span>
                </div>
                <span style={{ color: '#6b7280' }}>{expandedRoutes.has(route.slug) ? '[-]' : '[+]'}</span>
              </div>
              {expandedRoutes.has(route.slug) && (
                <div style={{ padding: '0 15px 15px', borderTop: '1px solid #222' }}>
                  {route.stops.map((stop, i) => (
                    <div key={i} style={{ padding: '4px 0', fontFamily: 'monospace', color: stop.is_terminus ? '#fbbf24' : '#9ca3af' }}>
                      {stop.is_terminus ? '◆' : '·'} {stop.name}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}

const SlipstreamTab: React.FC<{
  routes: SlipstreamRoute[]
  heat: number
  heatTier: string
}> = ({ routes, heat, heatTier }) => {
  return (
    <div>
      {/* Heat indicator */}
      <div style={{ padding: '10px 15px', border: '1px solid #333', marginBottom: 20, background: '#0a0a0a', fontFamily: 'monospace' }}>
        <span style={{ color: '#9ca3af' }}>Corridor Heat: </span>
        <span style={{ color: HEAT_COLORS[heatTier] || '#9ca3af', fontWeight: 'bold' }}>
          {heat}/100 ({heatTier})
        </span>
        <div style={{ marginTop: 8, height: 4, background: '#222', borderRadius: 2 }}>
          <div style={{ width: `${heat}%`, height: '100%', background: HEAT_COLORS[heatTier] || '#9ca3af', borderRadius: 2, transition: 'width 0.3s' }} />
        </div>
      </div>

      {routes.length === 0 ? (
        <div style={{ color: '#6b7280', fontFamily: 'monospace', padding: 20 }}>No Slipstream corridors available from your current region.</div>
      ) : (
        routes.map(route => (
          <div key={route.slug} style={{ border: '1px solid #a78bfa33', padding: 15, marginBottom: 10, background: '#0a0a0a' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
              <span style={{ color: '#a78bfa', fontFamily: 'monospace', fontWeight: 'bold' }}>[SLIP] {route.name}</span>
              <span style={{ color: '#6b7280', fontFamily: 'monospace', fontSize: '0.85em' }}>CL{route.min_clearance}+</span>
            </div>
            <div style={{ color: '#9ca3af', fontFamily: 'monospace', fontSize: '0.9em' }}>
              {route.origin_region.name} <span style={{ color: '#a78bfa' }}>→</span> {route.destination_region.name}
              <span style={{ color: '#6b7280', marginLeft: 15 }}>{route.leg_count} legs</span>
            </div>
            {route.legs.length > 0 && (
              <div style={{ marginTop: 10, paddingLeft: 10, borderLeft: '2px solid #a78bfa33' }}>
                {route.legs.map(leg => (
                  <div key={leg.position} style={{ padding: '3px 0', fontFamily: 'monospace', color: '#6b7280', fontSize: '0.85em' }}>
                    Leg {leg.position}: {leg.name} {leg.has_forks && <span style={{ color: '#fbbf24' }}>[FORK]</span>}
                  </div>
                ))}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}

const NetworkTab: React.FC<{
  assignments: Record<string, RegionAssignment[]>
}> = ({ assignments }) => {
  const regions = Object.entries(assignments).sort(([a], [b]) => a.localeCompare(b))

  return (
    <div>
      <p style={{ color: '#6b7280', fontFamily: 'monospace', marginBottom: 20 }}>
        Transit types available per region across THE PULSE GRID.
      </p>
      {regions.length === 0 ? (
        <div style={{ color: '#6b7280', fontFamily: 'monospace' }}>No transit assignments configured.</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 12 }}>
          {regions.map(([regionSlug, types]) => (
            <div key={regionSlug} style={{ border: '1px solid #333', padding: 12, background: '#0a0a0a' }}>
              <div style={{ color: '#a78bfa', fontFamily: 'monospace', fontWeight: 'bold', marginBottom: 8 }}>
                {regionSlug.replace(/-/g, ' ').replace(/\b\w/g, c => c.toUpperCase()).replace(/^The /, 'The ')}
              </div>
              {types.map(t => (
                <div key={t.slug} style={{ padding: '2px 0', fontFamily: 'monospace', fontSize: '0.85em' }}>
                  <span style={{ color: CATEGORY_COLORS[t.category] || '#9ca3af' }}>
                    {t.category === 'public' ? '■' : '◇'}
                  </span>{' '}
                  <span style={{ color: '#d0d0d0' }}>{t.name}</span>
                </div>
              ))}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default TransitPage
