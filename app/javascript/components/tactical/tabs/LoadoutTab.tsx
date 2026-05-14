import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface SlotData {
  slot: string
  label: string
  item: {
    name: string
    rarity: string
    rarity_color: string
  } | null
}

interface LoadoutResponse {
  slots: SlotData[]
  active_effects: Record<string, number | boolean>
}

const SLOT_ORDER = ['back', 'head', 'ears', 'eyes', 'neck', 'chest', 'left_wrist', 'right_wrist', 'hands', 'waist', 'legs', 'feet']

export const LoadoutTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<LoadoutResponse | null>(null)

  useEffect(() => {
    apiJson<LoadoutResponse>('/api/grid/loadout').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  const deckSlot = data.slots.find(s => s.slot === 'deck')
  const gearSlots = data.slots.filter(s => s.slot !== 'deck')
    .sort((a, b) => SLOT_ORDER.indexOf(a.slot) - SLOT_ORDER.indexOf(b.slot))
  const mid = Math.ceil(gearSlots.length / 2)
  const left = gearSlots.slice(0, mid)
  const right = gearSlots.slice(mid)
  const effectEntries = Object.entries(data.active_effects).filter(([, v]) => v !== 0 && v !== false)

  const renderSlot = (slot: SlotData) => (
    <div key={slot.slot} style={{
      display: 'flex', justifyContent: 'space-between',
      padding: '3px 0', borderBottom: '1px solid #1a1a1a'
    }}>
      <span style={{ color: '#888', minWidth: '55px', fontSize: '0.9em' }}>{slot.label}</span>
      {slot.item ? (
        <span style={{ color: slot.item.rarity_color }}>{slot.item.name}</span>
      ) : (
        <span style={{ color: '#333' }}>—</span>
      )}
    </div>
  )

  return (
    <div style={{ fontSize: '0.8em' }}>
      <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '6px' }}>LOADOUT</div>
      {deckSlot && (
        <div style={{
          display: 'flex', justifyContent: 'space-between',
          padding: '3px 0', marginBottom: '4px', borderBottom: '1px solid #333'
        }}>
          <span style={{ color: '#22d3ee', minWidth: '55px', fontSize: '0.9em' }}>{deckSlot.label}</span>
          {deckSlot.item ? (
            <span style={{ color: deckSlot.item.rarity_color }}>{deckSlot.item.name}</span>
          ) : (
            <span style={{ color: '#333' }}>—</span>
          )}
        </div>
      )}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 16px' }}>
        <div>{left.map(renderSlot)}</div>
        <div>{right.map(renderSlot)}</div>
      </div>
      {effectEntries.length > 0 && (
        <div style={{ marginTop: '12px' }}>
          <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '4px' }}>ACTIVE EFFECTS</div>
          {effectEntries.map(([key, val]) => (
            <div key={key} style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0', color: '#888' }}>
              <span>{key.replace(/_/g, ' ')}</span>
              <span style={{ color: '#34d399' }}>+{String(val)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
