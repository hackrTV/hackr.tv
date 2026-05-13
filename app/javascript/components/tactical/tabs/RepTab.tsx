import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface FactionStanding {
  faction_name: string
  faction_slug: string
  effective: number
  tier_key: string
  tier_label: string
  tier_color: string
  next_tier_label: string | null
  next_tier_diff: number | null
  aggregate: boolean
  depth: number
}

interface ReputationResponse {
  standings: FactionStanding[]
}

function repBar (value: number): string {
  const half = 10
  const maxVal = 1000
  const clamped = Math.max(-maxVal, Math.min(maxVal, value))
  const fillCells = Math.round((Math.abs(clamped) * half) / maxVal)

  const left = value < 0
    ? '░'.repeat(half - fillCells) + '█'.repeat(fillCells)
    : '░'.repeat(half)
  const right = value > 0
    ? '█'.repeat(fillCells) + '░'.repeat(half - fillCells)
    : '░'.repeat(half)
  return `${left}│${right}`
}

export const RepTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<ReputationResponse | null>(null)

  useEffect(() => {
    apiJson<ReputationResponse>('/api/grid/reputation').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  if (data.standings.length === 0) {
    return (
      <div style={{ fontSize: '0.8em' }}>
        <div style={{ color: '#555' }}>No factions on file. The Grid doesn&apos;t know you yet.</div>
      </div>
    )
  }

  // Column widths matching terminal rep_command: name(dynamic), tier badge(13), bar(21), value(5)
  const maxNameWidth = Math.max(...data.standings.map(s => {
    const indentLen = s.depth > 0 ? 2 * (s.depth - 1) + 3 : 0
    return indentLen + s.faction_name.length
  }))
  const tierBadgeWidth = 13 // [BLACKLISTED] = longest possible tier badge
  const valueWidth = 5 // +1000 / -1000
  const sep = '\u00A0\u00A0'

  return (
    <div style={{ fontSize: '0.75em', fontFamily: '\'Courier New\', monospace', lineHeight: '1.6' }}>
      {data.standings.map(s => {
        const indent = s.depth > 0 ? '\u00A0\u00A0'.repeat(s.depth - 1) + '└─ ' : ''
        const nameCol = `${indent}${s.faction_name}`.padEnd(maxNameWidth, '\u00A0')
        const tierCol = `[${s.tier_label}]`.padEnd(tierBadgeWidth, '\u00A0')
        const barCol = repBar(s.effective)
        const valCol = ((s.effective >= 0 ? '+' : '') + s.effective).padStart(valueWidth, '\u00A0')
        const nextCol = s.next_tier_diff !== null
          ? `${s.next_tier_diff} to ${s.next_tier_label}`
          : '[MAX]'

        return (
          <div key={s.faction_slug} style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            <span style={{ color: '#d0d0d0' }}>{nameCol}</span>
            {sep}
            <span style={{ color: s.tier_color }}>{tierCol}</span>
            {sep}
            <span style={{ color: s.tier_color }}>{barCol}</span>
            {sep}
            <span style={{ color: '#9ca3af' }}>{valCol}</span>
            {sep}
            <span style={{ color: s.next_tier_diff !== null ? '#555' : '#fbbf24' }}>{nextCol}</span>
            {s.aggregate && <span style={{ color: '#555' }}>{sep}↻</span>}
          </div>
        )
      })}
    </div>
  )
}
