import React, { useEffect, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface GearItem {
  id: number
  name: string
  rarity: string
  rarity_color: string
  rarity_label: string
  description: string | null
  gear_slot: string | null
  gear_slot_label: string | null
  equipped_slot: string | null
  effects: Record<string, number | boolean>
  required_clearance: number
}

interface LoadoutSlot {
  slot: string
  label: string
  item: GearItem | null
}

interface VitalInfo {
  current: number
  max: number
}

interface LoadoutResponse {
  slots: LoadoutSlot[]
  inventory_gear: GearItem[]
  active_effects: Record<string, number | boolean>
  vitals: {
    health: VitalInfo
    energy: VitalInfo
    psyche: VitalInfo
  }
}

const LoadoutPage: React.FC = () => {
  const [data, setData] = useState<LoadoutResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    apiJson<LoadoutResponse>('/api/grid/loadout')
      .then(json => { setData(json); setLoading(false) })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load loadout')
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading loadout..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load loadout'}
        </div>
      </DefaultLayout>
    )
  }

  const equippedCount = data.slots.filter(s => s.item).length
  const effectEntries = Object.entries(data.active_effects)

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 1100, margin: '30px auto' }}>
        <div
          className="tui-window white-text"
          style={{
            display: 'block',
            background: '#0a0a0a',
            border: '2px solid #22d3ee',
            boxShadow: '0 0 30px rgba(34, 211, 238, 0.3)'
          }}
        >
          <fieldset style={{ borderColor: '#22d3ee' }}>
            <legend
              className="center"
              style={{ color: '#22d3ee', textShadow: '0 0 15px rgba(34, 211, 238, 0.6)', letterSpacing: 3 }}
            >
              LOADOUT
            </legend>
            <div style={{ padding: 20 }}>
              {/* Equipped count */}
              <div style={{ marginBottom: 16, color: '#9ca3af', fontSize: '0.85em' }}>
                {equippedCount}/{data.slots.length} slots equipped
              </div>

              {/* Slot grid */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 10 }}>
                {data.slots.map(s => <SlotCard key={s.slot} slot={s} />)}
              </div>

              {/* Active effects */}
              {effectEntries.length > 0 && (
                <div style={{ marginTop: 24, padding: 14, background: '#0f0f0f', border: '1px solid #2a2a2a' }}>
                  <div style={{ color: '#fbbf24', fontWeight: 'bold', marginBottom: 8, fontFamily: 'monospace' }}>ACTIVE EFFECTS</div>
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 12 }}>
                    {effectEntries.map(([key, val]) => (
                      <span key={key} style={{ color: '#34d399', fontFamily: 'monospace', fontSize: '0.85em' }}>
                        {formatEffectLabel(key)}: +{String(val)}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Vitals with gear caps */}
              <div style={{ marginTop: 24, padding: 14, background: '#0f0f0f', border: '1px solid #2a2a2a' }}>
                <div style={{ color: '#fbbf24', fontWeight: 'bold', marginBottom: 8, fontFamily: 'monospace' }}>VITALS</div>
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, fontFamily: 'monospace', fontSize: '0.85em' }}>
                  <VitalBar label="HEALTH" vital={data.vitals.health} color="#34d399" />
                  <VitalBar label="ENERGY" vital={data.vitals.energy} color="#60a5fa" />
                  <VitalBar label="PSYCHE" vital={data.vitals.psyche} color="#c084fc" />
                </div>
              </div>

              {/* Unequipped gear in inventory */}
              {data.inventory_gear.length > 0 && (
                <div style={{ marginTop: 24 }}>
                  <div style={{ color: '#fbbf24', fontWeight: 'bold', marginBottom: 8, fontFamily: 'monospace' }}>
                    GEAR IN INVENTORY ({data.inventory_gear.length})
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 10 }}>
                    {data.inventory_gear.map(item => <InventoryGearCard key={item.id} item={item} />)}
                  </div>
                </div>
              )}

              <div style={{ marginTop: 20, color: '#6b7280', fontSize: '0.8em', textAlign: 'center' }}>
                Use <code style={{ color: '#22d3ee' }}>loadout</code> in the Terminal to view.
                Use <code style={{ color: '#34d399' }}>equip &lt;item&gt;</code> / <code style={{ color: '#34d399' }}>unequip &lt;item&gt;</code> to manage gear.
              </div>
            </div>
          </fieldset>
        </div>
      </div>
    </DefaultLayout>
  )
}

const SlotCard: React.FC<{ slot: LoadoutSlot }> = ({ slot: s }) => {
  const hasItem = !!s.item
  const borderColor = hasItem ? (s.item!.rarity_color || '#34d399') : '#2a2a2a'

  return (
    <div style={{ background: '#0f0f0f', border: `1px solid ${borderColor}`, padding: 12, fontFamily: 'monospace' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <span style={{ color: '#22d3ee', fontWeight: 'bold', fontSize: '0.8em' }}>{s.label}</span>
        {hasItem && (
          <span style={{
            color: s.item!.rarity_color,
            fontSize: '0.65em',
            background: '#1a1a1a',
            padding: '1px 6px',
            border: `1px solid ${s.item!.rarity_color}`
          }}>
            {s.item!.rarity_label}
          </span>
        )}
      </div>
      {hasItem ? (
        <>
          <div style={{ color: s.item!.rarity_color, fontWeight: 'bold' }}>{s.item!.name}</div>
          {s.item!.description && (
            <div style={{ color: '#6b7280', fontSize: '0.8em', marginTop: 4, lineHeight: 1.3 }}>{s.item!.description}</div>
          )}
          {Object.keys(s.item!.effects).length > 0 && (
            <div style={{ marginTop: 6, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
              {Object.entries(s.item!.effects).filter(([, v]) => v !== 0 && v !== false).map(([key, val]) => (
                <span key={key} style={{ color: '#34d399', fontSize: '0.75em', background: '#001a10', padding: '1px 4px', border: '1px solid #1a3a2a' }}>
                  +{String(val)} {formatEffectLabel(key)}
                </span>
              ))}
            </div>
          )}
        </>
      ) : (
        <div style={{ color: '#4b5563', fontStyle: 'italic' }}>-- empty --</div>
      )}
    </div>
  )
}

const InventoryGearCard: React.FC<{ item: GearItem }> = ({ item }) => (
  <div style={{ background: '#0f0f0f', border: '1px solid #2a2a2a', padding: 12, fontFamily: 'monospace' }}>
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
      <span style={{ color: item.rarity_color, fontWeight: 'bold' }}>{item.name}</span>
      <span style={{ color: '#6b7280', fontSize: '0.7em' }}>{item.gear_slot_label || item.gear_slot?.toUpperCase().replace(/_/g, ' ')}</span>
    </div>
    {item.description && <div style={{ color: '#6b7280', fontSize: '0.8em', lineHeight: 1.3 }}>{item.description}</div>}
    {Object.keys(item.effects).length > 0 && (
      <div style={{ marginTop: 6, display: 'flex', flexWrap: 'wrap', gap: 6 }}>
        {Object.entries(item.effects).filter(([, v]) => v !== 0 && v !== false).map(([key, val]) => (
          <span key={key} style={{ color: '#34d399', fontSize: '0.75em' }}>
            +{String(val)} {formatEffectLabel(key)}
          </span>
        ))}
      </div>
    )}
    {item.required_clearance > 0 && (
      <div style={{ marginTop: 4, color: '#fbbf24', fontSize: '0.75em' }}>CL{item.required_clearance}+</div>
    )}
    <div style={{ marginTop: 6, color: '#6b7280', fontSize: '0.7em' }}>
      equip {item.name.toLowerCase()}
    </div>
  </div>
)

const VitalBar: React.FC<{ label: string; vital: VitalInfo; color: string }> = ({ label, vital, color }) => {
  const boosted = vital.max > 100
  return (
    <div style={{ minWidth: 120 }}>
      <span style={{ color }}>{label}</span>{' '}
      <span style={{ color: '#d0d0d0' }}>{vital.current}/{vital.max}</span>
      {boosted && <span style={{ color: '#34d399', fontSize: '0.8em' }}> (+{vital.max - 100})</span>}
    </div>
  )
}

function formatEffectLabel (key: string): string {
  return key.replace(/_/g, ' ')
}

export default LoadoutPage
