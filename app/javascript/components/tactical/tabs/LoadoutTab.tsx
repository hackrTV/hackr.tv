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
}

export const LoadoutTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<LoadoutResponse | null>(null)

  useEffect(() => {
    apiJson<LoadoutResponse>('/api/grid/loadout').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  const mid = Math.ceil(data.slots.length / 2)
  const left = data.slots.slice(0, mid)
  const right = data.slots.slice(mid)

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
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 16px' }}>
        <div>{left.map(renderSlot)}</div>
        <div>{right.map(renderSlot)}</div>
      </div>
    </div>
  )
}
