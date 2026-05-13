import React, { useEffect, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface SoftwareItem {
  id: number
  name: string
  rarity: string
  rarity_color: string
  rarity_label: string
  description: string | null
  software_category: string
  slot_cost: number
  battery_cost: number
  effect_type: string | null
  effect_magnitude: number
  target_types: string[] | null
  level: number
  loaded: boolean
}

interface DeckInfo {
  id: number
  name: string
  rarity: string
  rarity_color: string
  rarity_label: string
  battery_current: number
  battery_max: number
  slot_count: number
  slots_used: number
  module_slot_count: number
  modules_used: number
}

interface ModuleItem {
  id: number
  name: string
  rarity_color: string
  description: string | null
  firmware: string | null
}

interface DeckResponse {
  deck: DeckInfo | null
  software: SoftwareItem[]
  modules: ModuleItem[]
  inventory_software: SoftwareItem[]
}

const CATEGORY_COLORS: Record<string, string> = {
  offensive: '#f87171',
  defensive: '#60a5fa',
  utility: '#fbbf24',
  exploit: '#a78bfa'
}

const ProgressBar: React.FC<{ current: number; max: number; color: string; label: string }> = ({ current, max, color, label }) => {
  const pct = max > 0 ? Math.min((current / max) * 100, 100) : 0
  return (
    <div style={{ marginBottom: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
        <span style={{ color: '#fbbf24', fontSize: '0.85em' }}>{label}</span>
        <span style={{ color: '#9ca3af', fontSize: '0.85em' }}>{current}/{max}</span>
      </div>
      <div style={{ background: '#1a1a1a', border: '1px solid #333', height: 12 }}>
        <div style={{ background: color, height: '100%', width: `${pct}%`, transition: 'width 0.3s' }} />
      </div>
    </div>
  )
}

const SoftwareCard: React.FC<{ item: SoftwareItem }> = ({ item }) => {
  const catColor = CATEGORY_COLORS[item.software_category] || '#9ca3af'
  return (
    <div style={{ background: '#0d0d0d', border: '1px solid #333', padding: '10px 14px', marginBottom: 6 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <span style={{ color: item.rarity_color, fontWeight: 'bold' }}>{item.name}</span>
        <span style={{ color: catColor, fontSize: '0.8em', textTransform: 'uppercase', border: `1px solid ${catColor}`, padding: '1px 6px' }}>
          {item.software_category}
        </span>
      </div>
      <div style={{ color: '#6b7280', fontSize: '0.85em', marginTop: 4 }}>
        <span>Slots: {item.slot_cost}</span>
        <span style={{ margin: '0 8px' }}>|</span>
        <span>Power: {item.battery_cost}</span>
        <span style={{ margin: '0 8px' }}>|</span>
        <span>DMG: {item.effect_magnitude}</span>
        {item.target_types && item.target_types.length > 0 && (
          <>
            <span style={{ margin: '0 8px' }}>|</span>
            <span>Targets: {item.target_types.join(', ').toUpperCase()}</span>
          </>
        )}
      </div>
      {item.description && (
        <div style={{ color: '#4b5563', fontSize: '0.8em', marginTop: 4, fontStyle: 'italic' }}>
          {item.description}
        </div>
      )}
    </div>
  )
}

const DeckPage: React.FC = () => {
  const [data, setData] = useState<DeckResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    apiJson<DeckResponse>('/api/grid/deck')
      .then(json => { setData(json); setLoading(false) })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load DECK')
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading DECK..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load DECK'}
        </div>
      </DefaultLayout>
    )
  }

  const { deck, software, modules, inventory_software } = data

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 900, margin: '30px auto', padding: '0 20px' }}>
        <div className="tui-window white-text" style={{ display: 'block', borderColor: '#22d3ee' }}>
          <fieldset style={{ border: '1px solid #22d3ee', padding: 20 }}>
            <legend style={{ color: '#22d3ee', padding: '0 10px' }}>DECK STATUS</legend>

            {!deck ? (
              <div style={{ padding: 40, textAlign: 'center' }}>
                <p style={{ color: '#9ca3af', fontSize: '1.1em' }}>No DECK equipped.</p>
                <p style={{ color: '#6b7280', fontSize: '0.9em', marginTop: 10 }}>
                  Equip a DECK from your inventory to use the BREACH system.
                </p>
                <p style={{ color: '#6b7280', fontSize: '0.85em', marginTop: 6 }}>
                  Terminal: <span style={{ color: '#22d3ee' }}>equip &lt;deck name&gt;</span>
                </p>
              </div>
            ) : (
              <>
                <div style={{ marginBottom: 20 }}>
                  <h2 style={{ color: deck.rarity_color, margin: '0 0 4px 0', fontSize: '1.3em' }}>{deck.name}</h2>
                  <span style={{ color: deck.rarity_color, fontSize: '0.85em', border: `1px solid ${deck.rarity_color}`, padding: '1px 8px' }}>
                    {deck.rarity_label}
                  </span>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginBottom: 20 }}>
                  <div>
                    <ProgressBar current={deck.battery_current} max={deck.battery_max} color="#fbbf24" label="BATTERY" />
                    <ProgressBar current={deck.slots_used} max={deck.slot_count} color="#22d3ee" label="SOFTWARE SLOTS" />
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                    <div style={{ color: '#9ca3af', fontSize: '0.9em' }}>
                      <span style={{ color: '#fbbf24' }}>Module Slots:</span> {deck.modules_used}/{deck.module_slot_count}
                    </div>
                    <div style={{ color: '#6b7280', fontSize: '0.85em', marginTop: 4 }}>
                      Terminal: <span style={{ color: '#22d3ee' }}>deck load &lt;name&gt;</span> / <span style={{ color: '#22d3ee' }}>deck unload &lt;name&gt;</span>
                    </div>
                  </div>
                </div>

                {modules.length > 0 && (
                  <div style={{ borderTop: '1px solid #333', paddingTop: 15, marginTop: 10 }}>
                    <h3 style={{ color: '#fbbf24', margin: '0 0 10px 0', fontSize: '1em' }}>INSTALLED MODULES</h3>
                    {modules.map(mod => (
                      <div key={mod.id} style={{
                        background: '#1a1a2e', border: '1px solid #333', borderRadius: 4,
                        padding: '8px 12px', marginBottom: 6
                      }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ color: mod.rarity_color, fontWeight: 'bold' }}>{mod.name}</span>
                          {mod.firmware && (
                            <span style={{ color: '#a78bfa', fontSize: '0.85em' }}>{mod.firmware}</span>
                          )}
                        </div>
                        {mod.description && (
                          <div style={{ color: '#6b7280', fontSize: '0.85em', marginTop: 4 }}>{mod.description}</div>
                        )}
                      </div>
                    ))}
                  </div>
                )}

                <div style={{ borderTop: '1px solid #333', paddingTop: 15, marginTop: 10 }}>
                  <h3 style={{ color: '#fbbf24', margin: '0 0 10px 0', fontSize: '1em' }}>LOADED SOFTWARE</h3>
                  {software.length > 0 ? (
                    software.map(s => <SoftwareCard key={s.id} item={s} />)
                  ) : (
                    <p style={{ color: '#4b5563', fontStyle: 'italic' }}>No software loaded.</p>
                  )}
                </div>

                {inventory_software.length > 0 && (
                  <div style={{ borderTop: '1px solid #333', paddingTop: 15, marginTop: 15 }}>
                    <h3 style={{ color: '#9ca3af', margin: '0 0 10px 0', fontSize: '1em' }}>INVENTORY SOFTWARE (not loaded)</h3>
                    {inventory_software.map(s => <SoftwareCard key={s.id} item={s} />)}
                  </div>
                )}
              </>
            )}
          </fieldset>
        </div>
      </div>
    </DefaultLayout>
  )
}

export default DeckPage
