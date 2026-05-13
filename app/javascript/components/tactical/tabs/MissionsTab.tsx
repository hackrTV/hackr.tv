import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface MissionObjective {
  description: string
  current: number
  target: number
  completed: boolean
}

interface HackrMission {
  mission: {
    name: string
    slug: string
  }
  status: string
  objectives: MissionObjective[]
}

interface MissionsResponse {
  active: HackrMission[]
  completed: HackrMission[]
}

export const MissionsTab: React.FC<{ refreshToken: number }> = ({ refreshToken }) => {
  const [data, setData] = useState<MissionsResponse | null>(null)

  useEffect(() => {
    apiJson<MissionsResponse>('/api/grid/missions').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  return (
    <div style={{ fontSize: '0.8em' }}>
      {data.active.length > 0 && (
        <>
          <div style={{ color: '#22d3ee', fontSize: '0.85em', marginBottom: '4px' }}>ACTIVE</div>
          {data.active.map(hm => (
            <div key={hm.mission.slug} style={{ marginBottom: '8px', paddingBottom: '6px', borderBottom: '1px solid #1a1a1a' }}>
              <div style={{ color: '#e0e0e0', fontWeight: 'bold' }}>{hm.mission.name}</div>
              {hm.objectives.map((obj, i) => (
                <div key={i} style={{
                  display: 'flex', justifyContent: 'space-between',
                  fontSize: '0.9em', color: obj.completed ? '#34d399' : '#888'
                }}>
                  <span>{obj.completed ? '✓' : '○'} {obj.description}</span>
                  <span>{obj.current}/{obj.target}</span>
                </div>
              ))}
            </div>
          ))}
        </>
      )}

      {data.active.length === 0 && (
        <div style={{ color: '#555' }}>No active missions</div>
      )}

      {data.completed.length > 0 && (
        <>
          <div style={{ color: '#666', fontSize: '0.85em', marginTop: '8px', marginBottom: '4px' }}>
            COMPLETED ({data.completed.length})
          </div>
          {data.completed.slice(0, 5).map(hm => (
            <div key={hm.mission.slug} style={{ color: '#444', fontSize: '0.9em' }}>
              ✓ {hm.mission.name}
            </div>
          ))}
        </>
      )}
    </div>
  )
}
