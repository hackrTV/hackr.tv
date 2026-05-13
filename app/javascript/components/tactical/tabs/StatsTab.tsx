import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface LoadoutResponse {
  vitals: {
    health: { current: number; max: number }
    energy: { current: number; max: number }
    psyche: { current: number; max: number }
  }
  active_effects: Record<string, number | boolean>
}

const VitalBar: React.FC<{ label: string; current: number; max: number; color: string }> = ({
  label, current, max, color
}) => {
  const pct = max > 0 ? Math.round((current / max) * 100) : 0
  return (
    <div style={{ marginBottom: '8px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8em', marginBottom: '2px' }}>
        <span style={{ color }}>{label}</span>
        <span style={{ color: '#888' }}>{current}/{max}</span>
      </div>
      <div style={{ background: '#1a1a1a', borderRadius: '2px', height: '8px', border: '1px solid #333' }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: '2px',
          background: color, transition: 'width 0.3s'
        }} />
      </div>
    </div>
  )
}

export const StatsTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<LoadoutResponse | null>(null)

  useEffect(() => {
    apiJson<LoadoutResponse>('/api/grid/loadout').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  const { vitals, active_effects } = data
  const effectEntries = Object.entries(active_effects).filter(([, v]) => v !== 0 && v !== false)

  return (
    <div style={{ fontSize: '0.85em' }}>
      <VitalBar label="HEALTH" current={vitals.health.current} max={vitals.health.max} color="#f87171" />
      <VitalBar label="ENERGY" current={vitals.energy.current} max={vitals.energy.max} color="#fbbf24" />
      <VitalBar label="PSYCHE" current={vitals.psyche.current} max={vitals.psyche.max} color="#a78bfa" />

      {effectEntries.length > 0 && (
        <div style={{ marginTop: '12px' }}>
          <div style={{ color: '#666', fontSize: '0.8em', marginBottom: '4px' }}>ACTIVE EFFECTS</div>
          {effectEntries.map(([key, val]) => (
            <div key={key} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.8em', color: '#888' }}>
              <span>{key.replace(/_/g, ' ')}</span>
              <span style={{ color: '#34d399' }}>+{String(val)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
