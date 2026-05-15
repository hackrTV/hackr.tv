import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface VitalData {
  current: number
  max: number
}

interface AchievementProgress {
  name: string
  badge_icon: string | null
  current: number
  target: number
}

interface StandingSummary {
  name: string
  tier_label: string
  tier_color: string
  value: number
}

interface StatsResponse {
  alias: string
  clearance: number
  xp: number
  xp_to_next: number | null
  xp_current_floor: number
  xp_next_ceil: number
  max_clearance: boolean
  vitals: {
    health: VitalData
    energy: VitalData
    psyche: VitalData
  }
  cred: {
    default_label: string
    default_balance: number
    total_balance: number
  }
  debt: number
  deck_summary: {
    name: string
    rarity_color: string
    battery: [number, number]
    slots: [number, number]
  } | null
  loadout_summary: { equipped: number; total: number }
  achievements: {
    earned: number
    total: number
    in_progress: AchievementProgress[]
  }
  standings_summary: StandingSummary[]
}

const VitalBar: React.FC<{ label: string; current: number; max: number; color: string }> = ({
  label, current, max, color
}) => {
  const pct = max > 0 ? Math.round((current / max) * 100) : 0
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '3px' }}>
      <span style={{ color, fontSize: '0.85em', fontWeight: 'bold', width: '52px' }}>{label}</span>
      <div style={{
        flex: 1, background: '#1a1a1a', borderRadius: '2px', height: '8px',
        border: '1px solid #333', overflow: 'hidden'
      }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: '2px',
          background: color, transition: 'width 0.3s'
        }} />
      </div>
      <span style={{ color: '#888', fontSize: '0.85em', minWidth: '52px', textAlign: 'right' }}>
        {current}/{max}
      </span>
    </div>
  )
}

const SectionLabel: React.FC<{ children: React.ReactNode; hint?: string }> = ({ children, hint }) => (
  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: '12px', marginBottom: '4px' }}>
    <span style={{ color: '#fbbf24', fontSize: '0.85em', fontWeight: 'bold' }}>{children}</span>
    {hint && <span style={{ color: '#444', fontSize: '0.75em' }}>{hint}</span>}
  </div>
)

const formatCred = (amount: number): string => amount.toLocaleString()

export const StatsTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<StatsResponse | null>(null)

  useEffect(() => {
    apiJson<StatsResponse>('/api/grid/stats').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  // XP progress within current clearance level
  const xpInLevel = data.xp - data.xp_current_floor
  const xpLevelRange = data.xp_next_ceil - data.xp_current_floor
  const xpPct = data.max_clearance ? 100 : (xpLevelRange > 0 ? Math.round((xpInLevel / xpLevelRange) * 100) : 0)

  return (
    <div style={{ fontSize: '0.8em', maxWidth: '50%', fontFamily: '\'Courier New\', monospace' }}>
      {/* Clearance + XP */}
      <div style={{ marginBottom: '4px' }}>
        <span style={{ color: '#fbbf24', fontWeight: 'bold' }}>CL{data.clearance}</span>
        <span style={{ color: '#555' }}> :: </span>
        <span style={{ color: '#22d3ee' }}>{data.alias}</span>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '2px' }}>
        <span style={{ color: '#888', fontSize: '0.85em', width: '52px' }}>XP</span>
        <div style={{
          flex: 1, background: '#1a1a1a', borderRadius: '2px', height: '8px',
          border: '1px solid #333', overflow: 'hidden'
        }}>
          <div style={{
            width: `${xpPct}%`, height: '100%', borderRadius: '2px',
            background: '#22d3ee', transition: 'width 0.3s'
          }} />
        </div>
        <span style={{ color: '#888', fontSize: '0.85em', minWidth: '52px', textAlign: 'right' }}>
          {data.xp.toLocaleString()}
        </span>
      </div>
      <div style={{ color: '#555', fontSize: '0.8em', textAlign: 'right', marginBottom: '4px' }}>
        {data.max_clearance
          ? <span style={{ color: '#fbbf24' }}>[MAX CLEARANCE]</span>
          : <>{data.xp_to_next?.toLocaleString()} to CL{data.clearance + 1}</>
        }
      </div>

      {/* Vitals */}
      <SectionLabel>VITALS</SectionLabel>
      <VitalBar label="HEALTH" current={data.vitals.health.current} max={data.vitals.health.max}
        color={data.vitals.health.max > 0 && data.vitals.health.current / data.vitals.health.max <= 0.3 ? '#f87171' : '#34d399'} />
      <VitalBar label="ENERGY" current={data.vitals.energy.current} max={data.vitals.energy.max} color="#fbbf24" />
      <VitalBar label="PSYCHE" current={data.vitals.psyche.current} max={data.vitals.psyche.max} color="#a78bfa" />

      {/* CRED + Debt */}
      <SectionLabel hint="→ CRED tab">CRED</SectionLabel>
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0' }}>
        <span style={{ color: '#888' }}>Default ({data.cred.default_label})</span>
        <span style={{ color: '#34d399' }}>{formatCred(data.cred.default_balance)}</span>
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: '2px 0' }}>
        <span style={{ color: '#888' }}>Total</span>
        <span style={{ color: '#34d399' }}>{formatCred(data.cred.total_balance)}</span>
      </div>
      {data.debt > 0 && (
        <div style={{
          display: 'flex', justifyContent: 'space-between', padding: '4px 6px', marginTop: '4px',
          background: '#2a1a1a', border: '1px solid #f8717133', borderRadius: '3px'
        }}>
          <span style={{ color: '#f87171', fontWeight: 'bold' }}>GovCorp DEBT</span>
          <span style={{ color: '#f87171' }}>-{formatCred(data.debt)}</span>
        </div>
      )}

      {/* DECK summary */}
      <SectionLabel hint="→ DECK tab">DECK</SectionLabel>
      {data.deck_summary ? (
        <div>
          <div style={{ color: data.deck_summary.rarity_color, marginBottom: '2px' }}>{data.deck_summary.name}</div>
          <div style={{ display: 'flex', gap: '16px', color: '#888', fontSize: '0.9em' }}>
            <span>Battery: {data.deck_summary.battery[0]}/{data.deck_summary.battery[1]}</span>
            <span>Slots: {data.deck_summary.slots[0]}/{data.deck_summary.slots[1]}</span>
          </div>
        </div>
      ) : (
        <div style={{ color: '#555' }}>No DECK equipped</div>
      )}

      {/* Loadout summary */}
      <SectionLabel hint="→ GEAR tab">LOADOUT</SectionLabel>
      <div style={{ color: '#888' }}>
        {data.loadout_summary.equipped}/{data.loadout_summary.total} slots equipped
      </div>

      {/* Achievements */}
      <SectionLabel>ACHIEVEMENTS</SectionLabel>
      <div style={{ color: '#888', marginBottom: '4px' }}>
        {data.achievements.earned}/{data.achievements.total} earned
      </div>
      {data.achievements.in_progress.map(a => {
        const pct = a.target > 0 ? Math.round((a.current / a.target) * 100) : 0
        return (
          <div key={a.name} style={{ marginBottom: '6px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.9em', marginBottom: '2px' }}>
              <span style={{ color: '#d0d0d0' }}>
                {a.badge_icon && <>{a.badge_icon} </>}{a.name}
              </span>
              <span style={{ color: '#555' }}>{a.current}/{a.target}</span>
            </div>
            <div style={{
              background: '#1a1a1a', borderRadius: '2px', height: '4px',
              border: '1px solid #333', overflow: 'hidden'
            }}>
              <div style={{
                width: `${pct}%`, height: '100%', borderRadius: '2px',
                background: '#a78bfa', transition: 'width 0.3s'
              }} />
            </div>
          </div>
        )
      })}

      {/* Standings */}
      {data.standings_summary.length > 0 && (
        <>
          <SectionLabel hint="→ REP tab">STANDING</SectionLabel>
          {data.standings_summary.map(s => (
            <div key={s.name} style={{
              display: 'flex', justifyContent: 'space-between', padding: '2px 0'
            }}>
              <span style={{ color: '#d0d0d0' }}>{s.name}</span>
              <span style={{ color: s.tier_color }}>[{s.tier_label}]</span>
            </div>
          ))}
        </>
      )}
    </div>
  )
}
