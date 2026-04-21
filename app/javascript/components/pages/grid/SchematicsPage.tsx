import React, { useEffect, useMemo, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import type { SchematicsIndexResponse, Schematic, SchematicIngredient } from '~/types/schematic'

type Tab = 'all' | 'ready' | 'available' | 'locked'

const SchematicsPage: React.FC = () => {
  const [data, setData] = useState<SchematicsIndexResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<Tab>('all')

  useEffect(() => {
    apiJson<SchematicsIndexResponse>('/api/grid/schematics')
      .then(json => { setData(json); setLoading(false) })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load schematics')
        setLoading(false)
      })
  }, [])

  const counts = useMemo(() => {
    if (!data) return { all: 0, ready: 0, available: 0, locked: 0 }
    const ready = data.schematics.filter(s => s.craftable && s.has_ingredients).length
    const available = data.schematics.filter(s => s.craftable && !s.has_ingredients).length
    const locked = data.schematics.filter(s => !s.craftable).length
    return { all: data.schematics.length, ready, available, locked }
  }, [data])

  const filtered = useMemo(() => {
    if (!data) return []
    switch (activeTab) {
    case 'ready': return data.schematics.filter(s => s.craftable && s.has_ingredients)
    case 'available': return data.schematics.filter(s => s.craftable && !s.has_ingredients)
    case 'locked': return data.schematics.filter(s => !s.craftable)
    default: return data.schematics
    }
  }, [data, activeTab])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading schematics..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load schematics'}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 1100, margin: '30px auto' }}>
        <div
          className="tui-window white-text"
          style={{
            display: 'block',
            background: '#0a0a0a',
            border: '2px solid #a78bfa',
            boxShadow: '0 0 30px rgba(167, 139, 250, 0.3)'
          }}
        >
          <fieldset style={{ borderColor: '#a78bfa' }}>
            <legend
              className="center"
              style={{ color: '#a78bfa', textShadow: '0 0 15px rgba(167, 139, 250, 0.6)', letterSpacing: 3 }}
            >
              FABRICATION SCHEMATICS
            </legend>
            <div style={{ padding: 20 }}>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
                <TabButton label={`ALL (${counts.all})`} color="#a78bfa" active={activeTab === 'all'} onClick={() => setActiveTab('all')} />
                <TabButton label={`READY (${counts.ready})`} color="#34d399" active={activeTab === 'ready'} onClick={() => setActiveTab('ready')} />
                <TabButton label={`AVAILABLE (${counts.available})`} color="#60a5fa" active={activeTab === 'available'} onClick={() => setActiveTab('available')} />
                <TabButton label={`LOCKED (${counts.locked})`} color="#6b7280" active={activeTab === 'locked'} onClick={() => setActiveTab('locked')} />
              </div>

              {filtered.length === 0 ? (
                <div style={{ padding: 40, textAlign: 'center', color: '#6b7280' }}>
                  {activeTab === 'ready'
                    ? 'No schematics ready to fabricate. Gather more materials via salvaging.'
                    : activeTab === 'available'
                      ? 'No available schematics missing ingredients.'
                      : activeTab === 'locked'
                        ? 'No locked schematics.'
                        : 'No schematics available. Increase your clearance to unlock more.'}
                </div>
              ) : (
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 12 }}>
                  {filtered.map(s => <SchematicCard key={s.slug} schematic={s} />)}
                </div>
              )}

              <div style={{ marginTop: 20, color: '#6b7280', fontSize: '0.8em', textAlign: 'center' }}>
                Use <code style={{ color: '#a78bfa' }}>schematics</code> in the Terminal to browse.
                Use <code style={{ color: '#34d399' }}>fab &lt;slug&gt;</code> to fabricate.
              </div>
            </div>
          </fieldset>
        </div>
      </div>
    </DefaultLayout>
  )
}

const TabButton: React.FC<{ label: string; color: string; active: boolean; onClick: () => void }> = ({ label, color, active, onClick }) => (
  <button
    className="tui-button"
    onClick={onClick}
    style={{
      padding: '6px 14px',
      background: active ? color : '#222',
      color: active ? '#000' : color,
      fontWeight: 'bold',
      border: `1px solid ${color}`,
      cursor: 'pointer',
      boxShadow: 'none',
      fontFamily: 'monospace'
    }}
  >
    {label}
  </button>
)

const SchematicCard: React.FC<{ schematic: Schematic }> = ({ schematic: s }) => {
  const ready = s.craftable && s.has_ingredients
  const available = s.craftable && !s.has_ingredients
  const borderColor = !s.craftable ? '#4b5563' : ready ? '#34d399' : '#60a5fa'

  return (
    <div style={{ background: '#0f0f0f', border: `1px solid ${borderColor}`, padding: 14, fontFamily: 'monospace' }}>
      {/* Header */}
      <div style={{ marginBottom: 8 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
          <span style={{ color: '#a78bfa', fontWeight: 'bold', fontSize: '1.05em' }}>{s.name}</span>
          {ready && (
            <span style={{ color: '#34d399', fontSize: '0.7em', background: '#001a10', padding: '2px 6px', border: '1px solid #34d399' }}>
              READY
            </span>
          )}
          {available && (
            <span style={{ color: '#60a5fa', fontSize: '0.7em', background: '#001020', padding: '2px 6px', border: '1px solid #60a5fa' }}>
              AVAILABLE
            </span>
          )}
          {!s.craftable && (
            <span style={{ color: '#6b7280', fontSize: '0.7em', background: '#1a1a1a', padding: '2px 6px', border: '1px solid #4b5563' }}>
              LOCKED
            </span>
          )}
        </div>
        <div style={{ color: '#6b7280', fontSize: '0.75em' }}>{s.slug}</div>
      </div>

      {/* Description */}
      {s.description && (
        <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: 8, lineHeight: 1.4 }}>{s.description}</div>
      )}

      {/* Output */}
      <div style={{ marginBottom: 8 }}>
        <span style={{ color: '#fbbf24', fontSize: '0.8em' }}>Output: </span>
        <span style={{ color: s.output.rarity_color, fontWeight: 'bold' }}>{s.output.name}</span>
        {s.output_quantity > 1 && <span style={{ color: '#6b7280' }}> x{s.output_quantity}</span>}
      </div>

      {/* Ingredients */}
      <div style={{ marginTop: 8 }}>
        <div style={{ color: '#fbbf24', fontSize: '0.8em', marginBottom: 4 }}>Ingredients:</div>
        {s.ingredients.map(i => <IngredientRow key={i.item_slug} ingredient={i} />)}
      </div>

      {/* Footer */}
      <div style={{ marginTop: 10, paddingTop: 8, borderTop: '1px solid #2a2a2a', display: 'flex', flexWrap: 'wrap', gap: 10, fontSize: '0.8em' }}>
        {s.xp_reward > 0 && <span style={{ color: '#a78bfa' }}>+{s.xp_reward} XP</span>}
        {s.required_clearance > 0 && <span style={{ color: '#d0d0d0' }}>CL{s.required_clearance}+</span>}
        {s.required_room_type_label && (
          <span style={{ color: '#fbbf24' }}>Requires {s.required_room_type_label}</span>
        )}
      </div>

      {ready && (
        <div style={{ marginTop: 8, color: '#6b7280', fontSize: '0.75em' }}>
          Use <code style={{ color: '#34d399' }}>fab {s.slug}</code> in the Terminal.
        </div>
      )}
    </div>
  )
}

const IngredientRow: React.FC<{ ingredient: SchematicIngredient }> = ({ ingredient: i }) => {
  const met = i.owned >= i.required
  return (
    <div style={{ display: 'flex', gap: 6, alignItems: 'center', fontSize: '0.9em', color: met ? '#34d399' : '#d0d0d0' }}>
      <span style={{ color: met ? '#34d399' : '#f87171', minWidth: 12 }}>{met ? '✓' : '✗'}</span>
      <span style={{ flex: 1 }}>{i.item_name}</span>
      <span style={{ color: met ? '#34d399' : '#f87171', fontSize: '0.85em' }}>{i.owned}/{i.required}</span>
    </div>
  )
}

export default SchematicsPage
