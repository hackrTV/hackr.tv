import React, { useEffect, useState } from 'react'
import { apiJson } from '~/utils/apiClient'

interface ObjectiveDefinition {
  id: number
  label: string
  target_count: number
}

interface ObjectiveProgress {
  objective_id: number
  progress: number
  target_count: number
  completed: boolean
}

interface HackrMission {
  mission: {
    name: string
    slug: string
    giver: { name: string; room_name: string | null } | null
    objectives: ObjectiveDefinition[]
  }
  status: string
  objective_progress?: ObjectiveProgress[]
  ready_to_turn_in?: boolean
}

interface MissionsResponse {
  active: HackrMission[]
  completed: HackrMission[]
}

export const MissionsTab: React.FC<{ refreshToken: number; onCommand?: (cmd: string) => void }> = ({ refreshToken, onCommand }) => {
  const [data, setData] = useState<MissionsResponse | null>(null)

  useEffect(() => {
    apiJson<MissionsResponse>('/api/grid/missions').then(setData).catch(console.error)
  }, [refreshToken])

  if (!data) return <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>

  return (
    <div style={{ fontSize: '0.8em', maxWidth: '50%' }}>
      {data.active.length > 0 && (
        <>
          <div style={{ color: '#22d3ee', fontSize: '0.85em', marginBottom: '4px' }}>ACTIVE</div>
          {data.active.map(hm => {
            const progressById = new Map(
              (hm.objective_progress || []).map(op => [op.objective_id, op])
            )
            return (
              <div key={hm.mission.slug} style={{ marginBottom: '8px', paddingBottom: '6px', borderBottom: '1px solid #1a1a1a', breakInside: 'avoid' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
                  <span style={{ color: '#e0e0e0', fontWeight: 'bold' }}>{hm.mission.name}</span>
                  {hm.mission.giver && (
                    <span style={{ color: '#666', fontSize: '0.85em' }}>
                      {hm.mission.giver.name}{hm.mission.giver.room_name && ` @ ${hm.mission.giver.room_name}`}
                    </span>
                  )}
                </div>
                {hm.mission.objectives.map(obj => {
                  const prog = progressById.get(obj.id)
                  const completed = prog?.completed ?? false
                  const current = prog?.progress ?? 0
                  return (
                    <div key={obj.id} style={{
                      display: 'flex', justifyContent: 'space-between',
                      fontSize: '0.9em', color: completed ? '#34d399' : '#888'
                    }}>
                      <span>{completed ? '✓' : '○'} {obj.label}</span>
                      <span>{current}/{obj.target_count}</span>
                    </div>
                  )
                })}
                {hm.ready_to_turn_in && (
                  <button
                    onClick={() => onCommand?.(`turn_in ${hm.mission.slug}`)}
                    style={{
                      marginTop: '4px',
                      background: '#34d399',
                      color: '#0a0a0a',
                      border: 'none',
                      padding: '3px 10px',
                      fontSize: '0.85em',
                      fontWeight: 'bold',
                      cursor: 'pointer',
                      borderRadius: '3px',
                      fontFamily: '\'Courier New\', monospace'
                    }}
                  >
                    TURN IN
                  </button>
                )}
              </div>
            )
          })}
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
