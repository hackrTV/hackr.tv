import React, { useEffect, useMemo, useState } from 'react'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import type {
  MissionsIndexResponse,
  Mission,
  HackrMission,
  MissionObjective,
  MissionReward,
  ObjectiveProgress
} from '~/types/mission'

type Tab = 'active' | 'available' | 'completed'

const formatDate = (iso: string | null): string => {
  if (!iso) return '—'
  try {
    const d = new Date(iso)
    return d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
  } catch {
    return iso
  }
}

const rewardLine = (r: MissionReward): string => {
  switch (r.reward_type) {
  case 'xp': return `+${r.amount} XP`
  case 'cred': return `+${r.amount} CRED`
  case 'faction_rep': return `${r.amount >= 0 ? '+' : ''}${r.amount} rep (${r.target_slug ?? '?'})`
  case 'item_grant': {
    const qty = r.quantity > 1 ? ` ×${r.quantity}` : ''
    return `+ ${r.target_slug ?? 'item'}${qty}`
  }
  case 'grant_achievement': return `◆ Achievement: ${r.target_slug ?? '?'}`
  default: return r.reward_type
  }
}

const rewardColor = (r: MissionReward): string => {
  switch (r.reward_type) {
  case 'xp': return '#34d399'
  case 'cred': return '#fbbf24'
  case 'faction_rep': return r.amount >= 0 ? '#34d399' : '#ef4444'
  case 'item_grant': return '#60a5fa'
  case 'grant_achievement': return '#fbbf24'
  default: return '#9ca3af'
  }
}

const MissionsPage: React.FC = () => {
  const [data, setData] = useState<MissionsIndexResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState<Tab>('active')
  const [refetchToken, setRefetchToken] = useState(0)

  useEffect(() => {
    apiJson<MissionsIndexResponse>('/api/grid/missions')
      .then(json => { setData(json); setLoading(false) })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load missions')
        setLoading(false)
      })
  }, [refetchToken])

  // Listen for the DOM event dispatched by AchievementToastContainer
  // when a mission completes. This avoids opening a second ActionCable
  // subscription — the toast container is the single subscriber, and
  // it fans out via CustomEvent for any component that needs to react.
  useEffect(() => {
    const handler = () => setRefetchToken(t => t + 1)
    window.addEventListener('grid:mission_completed', handler)
    return () => window.removeEventListener('grid:mission_completed', handler)
  }, [])

  const counts = useMemo(() => ({
    active: data?.active.length ?? 0,
    available: data?.available.length ?? 0,
    completed: data?.completed.length ?? 0
  }), [data])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto' }}>
          <LoadingSpinner message="Loading missions..." color="cyan-255-text" size="large" />
        </div>
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div style={{ maxWidth: 1100, margin: '30px auto', padding: 40, textAlign: 'center', color: '#f87171' }}>
          {error || 'Failed to load missions'}
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      <div style={{ maxWidth: 1100, margin: '30px auto' }}>
        <div
          className="tui-window white-text"
          style={{
            display: 'block',
            background: '#0a0a0a',
            border: '2px solid #22d3ee',
            boxShadow: '0 0 30px rgba(34, 211, 238, 0.3)'
          }}
        >
          <fieldset style={{ borderColor: '#22d3ee' }}>
            <legend
              className="center"
              style={{ color: '#22d3ee', textShadow: '0 0 15px rgba(34, 211, 238, 0.6)', letterSpacing: 3 }}
            >
              MISSIONS
            </legend>
            <div style={{ padding: 20 }}>
              <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginBottom: 20 }}>
                <TabButton label={`ACTIVE (${counts.active})`} color="#22d3ee" active={activeTab === 'active'} onClick={() => setActiveTab('active')} />
                <TabButton label={`AVAILABLE (${counts.available})`} color="#34d399" active={activeTab === 'available'} onClick={() => setActiveTab('available')} />
                <TabButton label={`COMPLETED (${counts.completed})`} color="#fbbf24" active={activeTab === 'completed'} onClick={() => setActiveTab('completed')} />
              </div>

              {activeTab === 'active' && (
                <MissionList empty="No active missions. Travel to an NPC and 'ask &lt;npc&gt; about missions' in the Terminal to find work.">
                  {data.active.map(hm => <ActiveMissionCard key={hm.id} hackrMission={hm} />)}
                </MissionList>
              )}

              {activeTab === 'available' && (
                <MissionList empty="Nothing available in your current room. Travel and talk to NPCs to find work.">
                  {data.available.map(m => <AvailableMissionCard key={m.slug} mission={m} />)}
                </MissionList>
              )}

              {activeTab === 'completed' && (
                <MissionList empty="You haven't completed any missions yet.">
                  {data.completed.map(hm => <CompletedMissionCard key={hm.id} hackrMission={hm} />)}
                </MissionList>
              )}
            </div>
          </fieldset>
        </div>
      </div>
    </DefaultLayout>
  )
}

const TabButton: React.FC<{ label: string; color: string; active: boolean; onClick: () => void }> = ({ label, color, active, onClick }) => (
  <button
    className="tui-button"
    onClick={onClick}
    style={{
      padding: '6px 14px',
      background: active ? color : '#222',
      color: active ? '#000' : color,
      fontWeight: 'bold',
      border: `1px solid ${color}`,
      cursor: 'pointer',
      boxShadow: 'none',
      fontFamily: 'monospace'
    }}
  >
    {label}
  </button>
)

const MissionList: React.FC<{ empty: string; children: React.ReactNode }> = ({ empty, children }) => {
  const count = React.Children.count(children)
  if (count === 0) {
    return (
      <div style={{ padding: 40, textAlign: 'center', color: '#6b7280' }}>
        {empty}
      </div>
    )
  }
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: 12 }}>
      {children}
    </div>
  )
}

const CardShell: React.FC<{ borderColor: string; children: React.ReactNode }> = ({ borderColor, children }) => (
  <div
    style={{
      background: '#0f0f0f',
      border: `1px solid ${borderColor}`,
      padding: 14,
      fontFamily: 'monospace'
    }}
  >
    {children}
  </div>
)

const MissionHeader: React.FC<{ mission: Mission; statusBadge?: React.ReactNode }> = ({ mission, statusBadge }) => (
  <div style={{ marginBottom: 8 }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
      <span style={{ color: '#22d3ee', fontWeight: 'bold', fontSize: '1.05em' }}>{mission.name}</span>
      {statusBadge}
    </div>
    <div style={{ color: '#6b7280', fontSize: '0.75em', display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      <span style={{ fontFamily: 'monospace' }}>{mission.slug}</span>
      {mission.arc ? <span style={{ color: '#a78bfa' }}>[{mission.arc.name}]</span> : null}
      {mission.giver ? <span>giver: {mission.giver.name}</span> : null}
      {mission.repeatable ? <span style={{ color: '#34d399' }}>(repeatable)</span> : null}
    </div>
  </div>
)

const ObjectivesList: React.FC<{ objectives: MissionObjective[]; progress?: ObjectiveProgress[] }> = ({ objectives, progress }) => {
  const progressById = new Map<number, ObjectiveProgress>()
  progress?.forEach(p => progressById.set(p.objective_id, p))

  return (
    <div style={{ marginTop: 8 }}>
      <div style={{ color: '#fbbf24', fontSize: '0.8em', marginBottom: 4 }}>Objectives:</div>
      {objectives.map(o => {
        const p = progressById.get(o.id)
        const done = p?.completed === true
        const current = p?.progress ?? 0
        const target = o.target_count
        return (
          <div key={o.id} style={{ display: 'flex', gap: 6, alignItems: 'flex-start', fontSize: '0.9em', color: done ? '#34d399' : '#d0d0d0' }}>
            <span style={{ color: done ? '#34d399' : '#6b7280', minWidth: 12 }}>{done ? '✓' : '▸'}</span>
            <span style={{ flex: 1 }}>{o.label}</span>
            {target > 1 && <span style={{ color: '#9ca3af', fontSize: '0.85em' }}>{current}/{target}</span>}
          </div>
        )
      })}
    </div>
  )
}

const RewardsList: React.FC<{ rewards: MissionReward[] }> = ({ rewards }) => {
  if (rewards.length === 0) return null
  return (
    <div style={{ marginTop: 10, paddingTop: 8, borderTop: '1px solid #2a2a2a', display: 'flex', flexWrap: 'wrap', gap: 10, fontSize: '0.8em' }}>
      {rewards.map((r) => (
        <span key={r.id} style={{ color: rewardColor(r) }}>{rewardLine(r)}</span>
      ))}
    </div>
  )
}

const ActiveMissionCard: React.FC<{ hackrMission: HackrMission }> = ({ hackrMission }) => {
  const m = hackrMission.mission
  const ready = hackrMission.ready_to_turn_in
  const badge = ready ? (
    <span style={{ color: '#fbbf24', fontSize: '0.7em', background: '#221a00', padding: '2px 6px', border: '1px solid #fbbf24' }}>
      READY FOR TURN-IN
    </span>
  ) : null

  return (
    <CardShell borderColor={ready ? '#fbbf24' : '#22d3ee'}>
      <MissionHeader mission={m} statusBadge={badge} />
      {m.description && <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: 6, lineHeight: 1.4 }}>{m.description}</div>}
      <ObjectivesList objectives={m.objectives} progress={hackrMission.objective_progress} />
      <RewardsList rewards={m.rewards} />
      <div style={{ marginTop: 10, color: '#6b7280', fontSize: '0.75em' }}>
        {ready
          ? `Return to ${m.giver?.name ?? 'the giver'}. Use 'turn_in ${m.slug}' in the Terminal.`
          : `Accepted ${formatDate(hackrMission.accepted_at)}.`}
      </div>
    </CardShell>
  )
}

const AvailableMissionCard: React.FC<{ mission: Mission }> = ({ mission }) => (
  <CardShell borderColor="#34d399">
    <MissionHeader mission={mission} />
    {mission.description && <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: 6, lineHeight: 1.4 }}>{mission.description}</div>}
    <ObjectivesList objectives={mission.objectives} />
    <RewardsList rewards={mission.rewards} />
    <div style={{ marginTop: 10, color: '#6b7280', fontSize: '0.75em' }}>
      Available. Use <code style={{ color: '#34d399' }}>accept {mission.slug}</code> in the Terminal
      {mission.giver ? ` while in the same room as ${mission.giver.name}` : ''}.
    </div>
  </CardShell>
)

const CompletedMissionCard: React.FC<{ hackrMission: HackrMission }> = ({ hackrMission }) => {
  const m = hackrMission.mission
  const badge = hackrMission.turn_in_count > 1
    ? (<span style={{ color: '#34d399', fontSize: '0.7em' }}>×{hackrMission.turn_in_count}</span>)
    : null

  return (
    <CardShell borderColor="#4b5563">
      <MissionHeader mission={m} statusBadge={badge} />
      <div style={{ color: '#6b7280', fontSize: '0.75em' }}>
        Completed {formatDate(hackrMission.completed_at)}
      </div>
      <RewardsList rewards={m.rewards} />
    </CardShell>
  )
}

export default MissionsPage
