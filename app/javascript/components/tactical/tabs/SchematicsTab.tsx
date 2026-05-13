import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface Ingredient {
  item_name: string
  rarity_color: string
  required: number
  owned: number
}

interface OutputDef {
  name: string
  description: string | null
  item_type: string
  rarity: string
  rarity_color: string
  rarity_label: string
  max_stack: number | null
  properties: Record<string, unknown>
}

interface Schematic {
  slug: string
  name: string
  output: OutputDef
  ingredients: Ingredient[]
  craftable: boolean
  has_ingredients: boolean
}

interface SchematicsResponse {
  schematics: Schematic[]
}

const ITEM_TYPE_LABELS: Record<string, string> = {
  gear: 'Gear', software: 'Software', module: 'Module', firmware: 'Firmware',
  consumable: 'Consumable', material: 'Material', data: 'Data', tool: 'Tool',
  rig_component: 'Rig Component', collectible: 'Collectible', faction: 'Faction', fixture: 'Fixture'
}

const EFFECT_LABELS: Record<string, string> = {
  heal: 'Restores Health', energy_restore: 'Restores Energy', psyche_restore: 'Restores Psyche',
  energize: 'Restores Energy', psyche_boost: 'Restores Psyche',
  inspire: 'Grants Inspiration', deck_recharge: 'Recharges DECK Battery', repair_deck: 'Repairs Fried DECK',
  signal_flare: 'Reduces Detection', emergency_jackout: 'Emergency BREACH Exit',
  dmg: 'Damage', detection_reduction: 'Detection Reduction'
}

function humanizeProperties (props: Record<string, unknown>): { label: string; value: string }[] {
  const result: { label: string; value: string }[] = []
  if (props.software_category) result.push({ label: 'Category', value: String(props.software_category) })
  if (props.effect_type) {
    const effectLabel = EFFECT_LABELS[String(props.effect_type)] || String(props.effect_type)
    const mag = Number(props.effect_magnitude) || Number(props.amount) || 0
    result.push({ label: 'Effect', value: mag > 0 ? `${effectLabel} (${mag})` : effectLabel })
  }
  if (props.target_types && Array.isArray(props.target_types) && props.target_types.length > 0) result.push({ label: 'Targets', value: props.target_types.join(', ') })
  if (props.slot_cost && Number(props.slot_cost) > 1) result.push({ label: 'Slot Cost', value: `${props.slot_cost} slots` })
  if (props.battery_cost && Number(props.battery_cost) > 0) result.push({ label: 'Battery Cost', value: String(props.battery_cost) })
  if (props.effects && typeof props.effects === 'object') {
    for (const [k, v] of Object.entries(props.effects as Record<string, unknown>)) {
      if (v && v !== 0 && v !== false) result.push({ label: k.replace(/_/g, ' '), value: `+${v}` })
    }
  }
  return result
}

export const SchematicsTab: React.FC<{ refreshToken: number; onCommand?: (cmd: string) => void }> = ({ refreshToken, onCommand }) => {
  const [data, setData] = useState<SchematicsResponse | null>(null)
  const [confirm, setConfirm] = useState<Schematic | null>(null)
  const [detail, setDetail] = useState<OutputDef | null>(null)

  useEffect(() => {
    apiJson<SchematicsResponse>('/api/grid/schematics').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  const ready = data.schematics.filter(s => s.craftable && s.has_ingredients)
  const available = data.schematics.filter(s => s.craftable && !s.has_ingredients)
  const locked = data.schematics.filter(s => !s.craftable)

  return (
    <div style={{ fontSize: '0.8em' }}>
      {ready.length > 0 && (
        <>
          <div style={{ color: '#34d399', fontSize: '0.85em', marginBottom: '4px' }}>READY ({ready.length})</div>
          {ready.map(s => (
            <div key={s.slug} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '2px 0' }}>
              <button onClick={() => setConfirm(s)} style={{
                background: '#34d399', color: '#0a0a0a', border: 'none', borderRadius: '2px',
                padding: '1px 5px', fontSize: '0.8em', cursor: 'pointer', fontWeight: 'bold',
                fontFamily: '\'Courier New\', monospace', lineHeight: 1
              }}>FAB</button>
              <span onClick={() => setDetail(s.output)}
                style={{ color: s.output.rarity_color, cursor: 'pointer' }}>{s.output.name}</span>
            </div>
          ))}
        </>
      )}

      {available.length > 0 && (
        <>
          <div style={{ color: '#fbbf24', fontSize: '0.85em', marginTop: '8px', marginBottom: '4px' }}>
            AVAILABLE ({available.length})
          </div>
          {available.map(s => (
            <div key={s.slug} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '2px 0' }}>
              <button onClick={() => setConfirm(s)} style={{
                background: 'transparent', color: '#fbbf24', border: '1px solid #fbbf24', borderRadius: '2px',
                padding: '1px 5px', fontSize: '0.8em', cursor: 'pointer', fontWeight: 'bold',
                fontFamily: '\'Courier New\', monospace', lineHeight: 1
              }}>FAB</button>
              <span onClick={() => setDetail(s.output)}
                style={{ color: '#888', cursor: 'pointer' }}>{s.output.name}</span>
            </div>
          ))}
        </>
      )}

      {locked.length > 0 && (
        <div style={{ color: '#444', fontSize: '0.85em', marginTop: '8px' }}>
          {locked.length} locked schematic{locked.length !== 1 ? 's' : ''}
        </div>
      )}

      {detail && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 200,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.7)'
        }} onClick={() => setDetail(null)}>
          <div style={{
            background: '#1a1a1a', border: '1px solid #444', borderRadius: '6px',
            padding: '24px 28px', maxWidth: '460px', fontSize: '1.05em',
            fontFamily: '\'Courier New\', monospace'
          }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <span style={{ color: detail.rarity_color, fontWeight: 'bold', fontSize: '1.15em' }}>{detail.name}</span>
              <span style={{ color: detail.rarity_color, fontSize: '0.8em' }}>{detail.rarity_label}</span>
            </div>

            <div style={{ display: 'flex', gap: '12px', fontSize: '0.85em', color: '#888', marginBottom: '12px' }}>
              <span>{ITEM_TYPE_LABELS[detail.item_type] || detail.item_type}</span>
              {detail.max_stack && detail.max_stack > 1 && <span>Stack: {detail.max_stack}</span>}
            </div>

            {detail.description && (
              <div style={{ color: '#aaa', fontSize: '0.9em', marginBottom: '14px', lineHeight: '1.4' }}>
                {detail.description}
              </div>
            )}

            {(() => {
              const props = humanizeProperties(detail.properties)
              if (props.length === 0) return null
              return (
                <div style={{ borderTop: '1px solid #333', paddingTop: '10px' }}>
                  {props.map((p, i) => (
                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0', fontSize: '0.9em' }}>
                      <span style={{ color: '#888', textTransform: 'capitalize' }}>{p.label}</span>
                      <span style={{ color: '#34d399' }}>{p.value}</span>
                    </div>
                  ))}
                </div>
              )
            })()}

            <div style={{ marginTop: '16px', textAlign: 'right' }}>
              <button onClick={() => setDetail(null)} style={{
                background: 'transparent', color: '#888', border: '1px solid #444',
                padding: '6px 16px', fontSize: '0.9em', cursor: 'pointer',
                borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
              }}>CLOSE</button>
            </div>
          </div>
        </div>
      )}

      {confirm && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 200,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.7)'
        }} onClick={() => setConfirm(null)}>
          <div style={{
            background: '#1a1a1a', border: '1px solid #444', borderRadius: '6px',
            padding: '24px 28px', maxWidth: '460px', fontSize: '1.15em',
            fontFamily: '\'Courier New\', monospace'
          }} onClick={e => e.stopPropagation()}>
            <div style={{ color: '#e0e0e0', marginBottom: '16px', fontSize: '1.2em' }}>
              Fabricate <span style={{ color: confirm.output.rarity_color, fontWeight: 'bold' }}>{confirm.output.name}</span>?
            </div>
            {confirm.ingredients.length > 0 && (
              <div style={{ marginBottom: '18px', fontSize: '0.95em' }}>
                <div style={{ color: '#888', marginBottom: '6px' }}>This will consume:</div>
                {confirm.ingredients.map((ing, i) => (
                  <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '3px 0', gap: '20px' }}>
                    <span style={{ color: ing.rarity_color }}>{ing.item_name}</span>
                    <span style={{ color: ing.owned >= ing.required ? '#34d399' : '#f87171', whiteSpace: 'nowrap' }}>
                      {ing.required}x <span style={{ color: '#555' }}>({ing.owned} owned)</span>
                    </span>
                  </div>
                ))}
              </div>
            )}
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setConfirm(null)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.95em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >
                CANCEL
              </button>
              <button
                onClick={() => { onCommand?.(`fab ${confirm.slug}`); setConfirm(null) }}
                style={{
                  background: '#34d399', color: '#0a0a0a', border: 'none',
                  padding: '8px 20px', fontSize: '0.95em', cursor: 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >
                FABRICATE
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
