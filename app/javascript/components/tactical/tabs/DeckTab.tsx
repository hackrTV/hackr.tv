import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface DeckResponse {
  deck: {
    name: string
    rarity: string
    rarity_color: string
    battery_current: number
    battery_max: number
    slot_count: number
    slots_used: number
    module_slot_count: number
    modules_used: number
  } | null
  software: {
    id: number
    name: string
    rarity_color: string
    software_category: string
    slot_cost: number
    battery_cost: number
    effect_type: string | null
    effect_magnitude: number
    target_types: string[] | null
    level: number
  }[]
  modules: {
    id: number
    name: string
    rarity_color: string
    description: string | null
    firmware: string | null
  }[]
}

export const DeckTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<DeckResponse | null>(null)

  useEffect(() => {
    apiJson<DeckResponse>('/api/grid/deck').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>
  if (!data.deck) return <div style={{ color: '#666', fontSize: '0.8em' }}>No DECK equipped</div>

  const { deck, software } = data
  const batteryPct = deck.battery_max > 0 ? Math.round((deck.battery_current / deck.battery_max) * 100) : 0

  return (
    <div style={{ fontSize: '0.8em', maxWidth: '50%' }}>
      <div style={{ color: deck.rarity_color, fontWeight: 'bold', marginBottom: '8px' }}>
        {deck.name}
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', color: '#888', marginBottom: '4px' }}>
        <span>Battery</span>
        <span>{deck.battery_current}/{deck.battery_max}</span>
      </div>
      <div style={{ background: '#1a1a1a', borderRadius: '2px', height: '6px', border: '1px solid #333', marginBottom: '8px' }}>
        <div style={{
          width: `${batteryPct}%`, height: '100%', borderRadius: '2px',
          background: batteryPct > 25 ? '#34d399' : '#f87171'
        }} />
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', color: '#888', marginBottom: '8px', fontSize: '0.9em' }}>
        <span>Slots: {deck.slots_used}/{deck.slot_count}</span>
        <span>Modules: {deck.modules_used}/{deck.module_slot_count}</span>
      </div>

      {data.modules.length > 0 && (
        <>
          <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '4px' }}>INSTALLED MODULES</div>
          {data.modules.map(mod => (
            <div key={mod.id} style={{ padding: '2px 0', borderBottom: '1px solid #1a1a1a' }}>
              <span style={{ color: mod.rarity_color }}>{mod.name}</span>
              {mod.firmware && (
                <span style={{ color: '#888', fontSize: '0.85em' }}> &larr; {mod.firmware}</span>
              )}
            </div>
          ))}
          <div style={{ height: '8px' }} />
        </>
      )}

      {software.length > 0 && (
        <>
          <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '4px' }}>LOADED SOFTWARE</div>
          {software.map(sw => {
            const specs: string[] = []
            if (sw.battery_cost > 0) specs.push(`${sw.battery_cost} bat`)
            if (sw.effect_magnitude > 0) specs.push(`${sw.effect_magnitude} ${sw.effect_type || 'dmg'}`)
            if (sw.target_types?.length) specs.push(sw.target_types.join('/'))

            return (
              <div key={sw.id} style={{ padding: '3px 0', borderBottom: '1px solid #1a1a1a' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: sw.rarity_color }}>
                    {sw.name}
                    {sw.slot_cost > 1 && <span style={{ color: '#888', fontSize: '0.85em' }}> [{sw.slot_cost} slots]</span>}
                  </span>
                  <span style={{ color: '#555' }}>{sw.software_category}</span>
                </div>
                {specs.length > 0 && (
                  <div style={{ fontSize: '0.85em', color: '#666', marginTop: '1px' }}>
                    {specs.join(' · ')}
                  </div>
                )}
              </div>
            )
          })}
        </>
      )}
    </div>
  )
}
