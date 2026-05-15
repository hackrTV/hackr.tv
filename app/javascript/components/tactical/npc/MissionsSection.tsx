import React, { useState } from 'react'
import { NpcAvailableMission, NpcActiveMission, NpcDeliveryItem, NpcMissionReward } from '~/types/zoneMap'

interface MissionsSectionProps {
  availableMissions: NpcAvailableMission[]
  activeMissions: NpcActiveMission[]
  deliveryItems: NpcDeliveryItem[]
  mobName: string
  onCommand: (cmd: string) => void
  executing: boolean
}

interface ConfirmAction {
  type: 'accept' | 'abandon' | 'turn_in'
  slug: string
  name: string
}

export const MissionsSection: React.FC<MissionsSectionProps> = ({
  availableMissions, activeMissions, deliveryItems, mobName, onCommand, executing
}) => {
  const [confirm, setConfirm] = useState<ConfirmAction | null>(null)

  const deliveryByObj = new Map<number, NpcDeliveryItem>()
  deliveryItems.forEach(d => deliveryByObj.set(d.objective_id, d))

  const handleConfirm = () => {
    if (!confirm) return
    const cmd = confirm.type === 'turn_in' ? `turn_in ${confirm.slug}` : `${confirm.type} ${confirm.slug}`
    onCommand(cmd)
    setConfirm(null)
  }

  if (activeMissions.length === 0 && availableMissions.length === 0) {
    return <div style={{ color: '#555', fontSize: '0.8em', padding: '8px 0' }}>No missions from this NPC.</div>
  }

  return (
    <div style={{ fontSize: '0.8em' }}>
      {/* Active missions */}
      {activeMissions.length > 0 && (
        <div style={{ marginBottom: '16px' }}>
          <div style={{ color: '#22d3ee', fontWeight: 'bold', fontSize: '0.85em', letterSpacing: '0.5px', marginBottom: '8px' }}>
            ACTIVE
          </div>
          {activeMissions.map(hm => (
            <ActiveMissionRow
              key={hm.id}
              mission={hm}
              mobName={mobName}
              deliveryByObj={deliveryByObj}
              onCommand={onCommand}
              onConfirm={setConfirm}
              executing={executing}
            />
          ))}
        </div>
      )}

      {/* Available missions */}
      {availableMissions.length > 0 && (
        <div>
          <div style={{ color: '#34d399', fontWeight: 'bold', fontSize: '0.85em', letterSpacing: '0.5px', marginBottom: '8px' }}>
            AVAILABLE
          </div>
          {availableMissions.map(m => (
            <AvailableMissionRow
              key={m.slug}
              mission={m}
              onConfirm={setConfirm}
              executing={executing}
            />
          ))}
        </div>
      )}

      {/* Confirm modal */}
      {confirm && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(0,0,0,0.7)'
          }}
          onClick={() => setConfirm(null)}
        >
          <div
            style={{
              background: '#1a1a1a',
              border: `1px solid ${confirm.type === 'abandon' ? '#f87171' : '#c084fc'}`,
              borderRadius: '6px',
              padding: '24px 28px',
              maxWidth: '420px',
              fontFamily: '\'Courier New\', monospace'
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{
              color: confirm.type === 'abandon' ? '#f87171' : '#c084fc',
              fontWeight: 'bold',
              fontSize: '1.1em',
              letterSpacing: '1px',
              marginBottom: '12px'
            }}>
              {confirm.type === 'accept' && 'ACCEPT MISSION'}
              {confirm.type === 'abandon' && 'ABANDON MISSION'}
              {confirm.type === 'turn_in' && 'TURN IN MISSION'}
            </div>
            <div style={{ color: '#d0d0d0', marginBottom: '20px' }}>{confirm.name}</div>
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setConfirm(null)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >CANCEL</button>
              <button
                onClick={handleConfirm}
                disabled={executing}
                style={{
                  background: executing ? '#333' : (confirm.type === 'abandon' ? '#f87171' : '#c084fc'),
                  color: executing ? '#666' : '#0a0a0a', border: 'none',
                  padding: '8px 20px', fontSize: '0.9em',
                  cursor: executing ? 'not-allowed' : 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >
                {confirm.type === 'accept' && 'ACCEPT'}
                {confirm.type === 'abandon' && 'ABANDON'}
                {confirm.type === 'turn_in' && 'TURN IN'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// --- Active mission row ---

const ActiveMissionRow: React.FC<{
  mission: NpcActiveMission
  mobName: string
  deliveryByObj: Map<number, NpcDeliveryItem>
  onCommand: (cmd: string) => void
  onConfirm: (action: ConfirmAction) => void
  executing: boolean
}> = ({ mission, mobName, deliveryByObj, onCommand, onConfirm, executing }) => {
  const objectives = mission.mission.objectives
  const progressMap = new Map(mission.objective_progress.map(p => [p.objective_id, p]))

  return (
    <div style={{
      padding: '8px 0',
      borderBottom: '1px solid #1a1a1a'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
        <span style={{ color: '#22d3ee' }}>{mission.name}</span>
        {mission.ready_to_turn_in && (
          <span style={{ color: '#fbbf24', fontSize: '0.85em', fontWeight: 'bold' }}>READY</span>
        )}
      </div>

      {/* Objectives */}
      <div style={{ paddingLeft: '8px', marginBottom: '6px' }}>
        {objectives.map(obj => {
          const prog = progressMap.get(obj.id)
          const done = prog?.completed ?? false
          const current = prog?.progress ?? 0
          const delivery = deliveryByObj.get(obj.id)

          return (
            <div key={obj.id} style={{ display: 'flex', alignItems: 'center', gap: '6px', padding: '2px 0' }}>
              <span style={{ color: done ? '#34d399' : '#6b7280', fontSize: '0.9em' }}>
                {done ? '\u2713' : '\u25B8'}
              </span>
              <span style={{ color: done ? '#9ca3af' : '#d0d0d0', fontSize: '0.9em', flex: 1 }}>
                {obj.label}
                {obj.target_count > 1 && (
                  <span style={{ color: '#6b7280', marginLeft: '4px' }}>({current}/{obj.target_count})</span>
                )}
              </span>
              {delivery && !done && (
                <button
                  onClick={() => onCommand(`give ${delivery.item_name} to ${mobName}`)}
                  disabled={!delivery.in_inventory || executing}
                  style={{
                    background: delivery.in_inventory && !executing ? '#c084fc' : '#333',
                    color: delivery.in_inventory && !executing ? '#0a0a0a' : '#666',
                    border: 'none',
                    borderRadius: '3px',
                    padding: '2px 8px',
                    fontSize: '0.8em',
                    cursor: delivery.in_inventory ? 'pointer' : 'not-allowed',
                    fontWeight: 'bold',
                    fontFamily: '\'Courier New\', monospace',
                    flexShrink: 0
                  }}
                >
                  DELIVER{delivery.quantity_needed > 1 ? ` (${delivery.quantity_held}/${delivery.quantity_needed})` : ''}
                </button>
              )}
            </div>
          )
        })}
      </div>

      {/* Action buttons */}
      <div style={{ display: 'flex', gap: '6px' }}>
        {mission.ready_to_turn_in && mission.at_giver && (
          <button
            onClick={() => onConfirm({ type: 'turn_in', slug: mission.slug, name: mission.name })}
            disabled={executing}
            style={{
              background: executing ? '#333' : '#34d399',
              color: executing ? '#666' : '#0a0a0a', border: 'none',
              borderRadius: '3px', padding: '3px 10px', fontSize: '0.8em',
              cursor: executing ? 'not-allowed' : 'pointer',
              fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
            }}
          >TURN IN</button>
        )}
        <button
          onClick={() => onConfirm({ type: 'abandon', slug: mission.slug, name: mission.name })}
          disabled={executing}
          style={{
            background: 'transparent', color: '#f87171', border: '1px solid #f87171',
            borderRadius: '3px', padding: '2px 8px', fontSize: '0.75em',
            cursor: executing ? 'not-allowed' : 'pointer',
            opacity: executing ? 0.5 : 1,
            fontFamily: '\'Courier New\', monospace'
          }}
        >ABANDON</button>
      </div>
    </div>
  )
}

// --- Available mission row ---

const AvailableMissionRow: React.FC<{
  mission: NpcAvailableMission
  onConfirm: (action: ConfirmAction) => void
  executing: boolean
}> = ({ mission, onConfirm, executing }) => {
  const gates = mission.gates

  return (
    <div style={{
      padding: '8px 0',
      borderBottom: '1px solid #1a1a1a'
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
        <span style={{ color: '#d0d0d0' }}>{mission.name}</span>
        {mission.repeatable && (
          <span style={{ color: '#6b7280', fontSize: '0.75em' }}>REPEATABLE</span>
        )}
      </div>

      {mission.description && (
        <div style={{ color: '#888', fontSize: '0.9em', marginBottom: '6px' }}>
          {mission.description}
        </div>
      )}

      {/* Gate warnings */}
      {!gates.clearance_met && (
        <div style={{ color: '#f87171', fontSize: '0.8em', marginBottom: '2px' }}>
          [CLEARANCE {mission.min_clearance}]
        </div>
      )}
      {!gates.prereq_met && (
        <div style={{ color: '#f87171', fontSize: '0.8em', marginBottom: '2px' }}>
          [PREREQUISITE REQUIRED]
        </div>
      )}
      {!gates.rep_met && (
        <div style={{ color: '#f87171', fontSize: '0.8em', marginBottom: '2px' }}>
          [REPUTATION TOO LOW]
        </div>
      )}

      {/* Objectives preview */}
      <div style={{ paddingLeft: '8px', marginBottom: '6px' }}>
        {mission.objectives.map(obj => (
          <div key={obj.id} style={{ color: '#9ca3af', fontSize: '0.85em', padding: '1px 0' }}>
            <span style={{ color: '#6b7280' }}>{'\u25B8'}</span> {obj.label}
            {obj.target_count > 1 && <span style={{ color: '#6b7280' }}> (0/{obj.target_count})</span>}
          </div>
        ))}
      </div>

      {/* Rewards */}
      {mission.rewards.length > 0 && (
        <div style={{ fontSize: '0.8em', color: '#888', marginBottom: '6px' }}>
          Rewards: {formatRewards(mission.rewards)}
        </div>
      )}

      <button
        onClick={() => onConfirm({ type: 'accept', slug: mission.slug, name: mission.name })}
        disabled={!mission.can_accept || executing}
        style={{
          background: mission.can_accept && !executing ? '#34d399' : '#333',
          color: mission.can_accept && !executing ? '#0a0a0a' : '#666',
          border: 'none',
          borderRadius: '3px',
          padding: '3px 10px',
          fontSize: '0.8em',
          cursor: mission.can_accept ? 'pointer' : 'not-allowed',
          fontWeight: 'bold',
          fontFamily: '\'Courier New\', monospace'
        }}
      >ACCEPT</button>
    </div>
  )
}

function formatRewards (rewards: NpcMissionReward[]): string {
  return rewards.map(r => {
    switch (r.reward_type) {
    case 'xp': return `+${r.amount} XP`
    case 'cred': return `+${r.amount} CRED`
    case 'faction_rep': return `+${r.amount} REP`
    case 'item_grant': return `${r.target_slug}${r.quantity && r.quantity > 1 ? ` x${r.quantity}` : ''}`
    case 'grant_achievement': return `Achievement: ${r.target_slug}`
    default: return r.reward_type
    }
  }).join(', ')
}
