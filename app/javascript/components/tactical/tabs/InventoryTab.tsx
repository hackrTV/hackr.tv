import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'
import { InventoryItem, InventoryResponse } from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'

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

const GEAR_SLOT_LABELS: Record<string, string> = {
  deck: 'DECK', back: 'BACK', chest: 'CHEST', head: 'HEAD', ears: 'EARS',
  eyes: 'EYES', left_wrist: 'L.WRIST', right_wrist: 'R.WRIST', hands: 'HANDS',
  neck: 'NECK', waist: 'WAIST', legs: 'LEGS', feet: 'FEET'
}

const ACTION_CONFIG: Record<string, { label: string; color: string }> = {
  use: { label: 'USE', color: '#34d399' },
  equip: { label: 'EQUIP', color: '#22d3ee' },
  drop: { label: 'DROP', color: '#fbbf24' },
  salvage: { label: 'SALVAGE', color: '#f97316' },
  place: { label: 'PLACE', color: '#22d3ee' },
  sell: { label: 'SELL', color: '#fbbf24' }
}

function actionHint (action: string, item: InventoryItem): string {
  switch (action) {
  case 'use': return item.item_type === 'consumable' ? 'Item will be consumed.' : ''
  case 'equip': {
    const slot = item.properties?.gear_slot
    const label = slot ? (GEAR_SLOT_LABELS[String(slot)] || String(slot).toUpperCase()) : null
    return label ? `Equips to ${label} slot.` : ''
  }
  case 'drop': return 'Item will be left on the ground.'
  case 'salvage': return 'Item will be destroyed for XP.'
  case 'place': return 'Fixture will be installed in your den.'
  case 'sell': return item.sell_price ? `Sells for ${item.sell_price} CRED.` : ''
  default: return ''
  }
}

function humanizeProperties (props: Record<string, unknown>): { label: string; value: string }[] {
  const result: { label: string; value: string }[] = []
  if (props.slot) result.push({ label: 'Slot', value: GEAR_SLOT_LABELS[String(props.slot)] || String(props.slot).toUpperCase() })
  if (props.software_category) result.push({ label: 'Category', value: String(props.software_category) })
  if (props.effect_type) {
    const effectLabel = EFFECT_LABELS[String(props.effect_type)] || String(props.effect_type)
    const mag = Number(props.effect_magnitude) || Number(props.amount) || 0
    result.push({ label: 'Effect', value: mag > 0 ? `${effectLabel} (${mag})` : effectLabel })
  }
  if (props.target_types && Array.isArray(props.target_types) && props.target_types.length > 0) result.push({ label: 'Targets', value: props.target_types.join(', ') })
  if (props.slot_cost && Number(props.slot_cost) > 1) result.push({ label: 'Slot Cost', value: `${props.slot_cost} slots` })
  if (props.battery_cost && Number(props.battery_cost) > 0) result.push({ label: 'Battery Cost', value: String(props.battery_cost) })
  if (props.storage_capacity) result.push({ label: 'Storage', value: `${props.storage_capacity} slots` })
  if (props.effects && typeof props.effects === 'object') {
    for (const [k, v] of Object.entries(props.effects as Record<string, unknown>)) {
      if (v && v !== 0 && v !== false) result.push({ label: k.replace(/_/g, ' '), value: `+${v}` })
    }
  }
  return result
}

export const InventoryTab: React.FC<{ refreshToken: number; onCommand?: (cmd: string) => void; hasVendor?: boolean }> = ({ refreshToken, onCommand, hasVendor }) => {
  const { executing } = useTactical()
  const [data, setData] = useState<InventoryResponse | null>(null)
  const [selectedItem, setSelectedItem] = useState<InventoryItem | null>(null)
  const [pendingAction, setPendingAction] = useState<{ item: InventoryItem; action: string } | null>(null)

  useEffect(() => {
    apiJson<InventoryResponse>('/api/grid/inventory').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  const { capacity, groups } = data
  const capacityPct = capacity.max > 0 ? Math.round((capacity.used / capacity.max) * 100) : 0
  const isFull = capacity.used >= capacity.max

  return (
    <div style={{ fontSize: '0.8em', maxWidth: '50%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', color: isFull ? '#f87171' : '#888', marginBottom: '4px' }}>
        <span>Inventory</span>
        <span>{capacity.used}/{capacity.max} slots</span>
      </div>
      <div style={{ background: '#1a1a1a', borderRadius: '2px', height: '6px', border: '1px solid #333', marginBottom: '10px' }}>
        <div style={{
          width: `${capacityPct}%`, height: '100%', borderRadius: '2px',
          background: isFull ? '#f87171' : capacity.used > capacity.max * 0.75 ? '#fbbf24' : '#34d399'
        }} />
      </div>

      {groups.length === 0 && (
        <div style={{ color: '#555' }}>Inventory empty</div>
      )}

      {groups.map(group => (
        <div key={group.item_type} style={{ marginBottom: '10px' }}>
          <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '4px' }}>
            {group.label} ({group.items.length})
          </div>
          {group.items.map(item => {
            const canSell = hasVendor && item.sell_price && item.sell_price > 0
            return (
              <div key={item.id}
                onClick={() => setSelectedItem(item)}
                style={{
                  display: 'flex', alignItems: 'baseline',
                  padding: '3px 0', borderBottom: '1px solid #1a1a1a', cursor: 'pointer', gap: '6px'
                }}
              >
                {canSell && (
                  <button
                    onClick={(e) => { e.stopPropagation(); setPendingAction({ item, action: 'sell' }) }}
                    disabled={executing}
                    style={{
                      background: executing ? '#333' : '#fbbf24',
                      color: executing ? '#666' : '#0a0a0a', border: 'none', borderRadius: '2px',
                      padding: '1px 5px', fontSize: '0.8em',
                      cursor: executing ? 'not-allowed' : 'pointer', fontWeight: 'bold',
                      fontFamily: '\'Courier New\', monospace', lineHeight: 1, flexShrink: 0
                    }}
                  >SELL</button>
                )}
                <span style={{ color: item.rarity_color, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flex: 1 }}>
                  {item.name}
                </span>
                <span style={{ whiteSpace: 'nowrap', flexShrink: 0, fontSize: '0.9em' }}>
                  {item.quantity > 1 && <span style={{ color: '#6b7280' }}>x{item.quantity} </span>}
                  <span style={{ color: item.rarity_color }}>[{item.rarity_label}]</span>
                </span>
              </div>
            )
          })}
        </div>
      ))}

      {selectedItem && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 200,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.7)'
        }} onClick={() => setSelectedItem(null)}>
          <div style={{
            background: '#1a1a1a', border: '1px solid #444', borderRadius: '6px',
            padding: '24px 28px', maxWidth: '460px', fontSize: '1.05em',
            fontFamily: '\'Courier New\', monospace'
          }} onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <span style={{ color: selectedItem.rarity_color, fontWeight: 'bold', fontSize: '1.15em' }}>{selectedItem.name}</span>
              <span style={{ color: selectedItem.rarity_color, fontSize: '0.8em' }}>{selectedItem.rarity_label}</span>
            </div>

            <div style={{ display: 'flex', gap: '12px', fontSize: '0.85em', color: '#888', marginBottom: '12px' }}>
              <span>{ITEM_TYPE_LABELS[selectedItem.item_type] || selectedItem.item_type}</span>
              {selectedItem.max_stack && selectedItem.max_stack > 1 && <span>Stack: {selectedItem.quantity}/{selectedItem.max_stack}</span>}
              {selectedItem.quantity > 1 && !selectedItem.max_stack && <span>Qty: {selectedItem.quantity}</span>}
            </div>

            {selectedItem.description && (
              <div style={{ color: '#aaa', fontSize: '0.9em', marginBottom: '14px', lineHeight: '1.4' }}>
                {selectedItem.description}
              </div>
            )}

            {(() => {
              const props = humanizeProperties(selectedItem.properties)
              if (props.length === 0) return null
              return (
                <div style={{ borderTop: '1px solid #333', paddingTop: '10px', marginBottom: '14px' }}>
                  {props.map((p, i) => (
                    <div key={i} style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0', fontSize: '0.9em' }}>
                      <span style={{ color: '#888', textTransform: 'capitalize' }}>{p.label}</span>
                      <span style={{ color: '#34d399' }}>{p.value}</span>
                    </div>
                  ))}
                </div>
              )
            })()}

            <div style={{ display: 'flex', gap: '8px', justifyContent: 'flex-end', borderTop: '1px solid #333', paddingTop: '14px' }}>
              <button onClick={() => setSelectedItem(null)} style={{
                background: 'transparent', color: '#888', border: '1px solid #444',
                padding: '6px 16px', fontSize: '0.9em', cursor: 'pointer',
                borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
              }}>CLOSE</button>
              {selectedItem.actions.map(action => {
                const config = ACTION_CONFIG[action]
                if (!config) return null
                return (
                  <button key={action} onClick={() => { setPendingAction({ item: selectedItem, action }); setSelectedItem(null) }} style={{
                    background: config.color, color: '#0a0a0a', border: 'none',
                    padding: '6px 16px', fontSize: '0.9em', cursor: 'pointer',
                    borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                  }}>{config.label}</button>
                )
              })}
              {hasVendor && selectedItem.sell_price && selectedItem.sell_price > 0 && (
                <button onClick={() => { setPendingAction({ item: selectedItem, action: 'sell' }); setSelectedItem(null) }} style={{
                  background: '#fbbf24', color: '#0a0a0a', border: 'none',
                  padding: '6px 16px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}>SELL</button>
              )}
            </div>
          </div>
        </div>
      )}

      {pendingAction && (
        <div style={{
          position: 'fixed', inset: 0, zIndex: 200,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: 'rgba(0,0,0,0.7)'
        }} onClick={() => setPendingAction(null)}>
          <div style={{
            background: '#1a1a1a', border: '1px solid #444', borderRadius: '6px',
            padding: '24px 28px', maxWidth: '460px', fontSize: '1.15em',
            fontFamily: '\'Courier New\', monospace'
          }} onClick={e => e.stopPropagation()}>
            <div style={{ color: '#e0e0e0', marginBottom: '16px', fontSize: '1.2em' }}>
              {ACTION_CONFIG[pendingAction.action]?.label}{' '}
              <span style={{ color: pendingAction.item.rarity_color, fontWeight: 'bold' }}>{pendingAction.item.name}</span>
              {pendingAction.item.quantity > 1 && (
                <span style={{ color: '#6b7280', fontWeight: 'normal' }}> x1</span>
              )}
              ?
            </div>
            {(() => {
              const hint = actionHint(pendingAction.action, pendingAction.item)
              if (!hint) return null
              return <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '18px' }}>{hint}</div>
            })()}
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button onClick={() => setPendingAction(null)} style={{
                background: 'transparent', color: '#888', border: '1px solid #444',
                padding: '8px 20px', fontSize: '0.95em', cursor: 'pointer',
                borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
              }}>CANCEL</button>
              <button onClick={() => {
                onCommand?.(`${pendingAction.action} ${pendingAction.item.name}`)
                setPendingAction(null)
              }} disabled={executing} style={{
                background: executing ? '#333' : (ACTION_CONFIG[pendingAction.action]?.color || '#34d399'),
                color: executing ? '#666' : '#0a0a0a', border: 'none',
                padding: '8px 20px', fontSize: '0.95em',
                cursor: executing ? 'not-allowed' : 'pointer',
                borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
              }}>{ACTION_CONFIG[pendingAction.action]?.label || pendingAction.action.toUpperCase()}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
