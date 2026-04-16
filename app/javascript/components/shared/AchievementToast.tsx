import React, { useState, useCallback } from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import {
  useAchievementChannel,
  type AchievementUnlockEvent,
  type MissionCompletedEvent
} from '~/hooks/useAchievementChannel'

const TOAST_DURATION_MS = 6000

// Toasts have two shapes (achievement unlock + mission completion).
// We union them and discriminate on `kind` at render time. Mission toasts
// reuse the same stack / auto-dismiss / click-to-dismiss machinery so the
// player sees one visual language regardless of source.
type ToastEntry =
  | ({ kind: 'achievement'; key: number } & AchievementUnlockEvent)
  | ({ kind: 'mission'; key: number } & MissionCompletedEvent)

const categoryColor = (category: string): string => {
  switch (category) {
  case 'music': return '#f472b6'
  case 'social': return '#60a5fa'
  case 'meta': return '#a3e635'
  case 'progression': return '#c084fc'
  default: return '#22d3ee' // grid
  }
}

const makeKey = (): number => Date.now() + Math.random()

export const AchievementToastContainer: React.FC = () => {
  const { hackr } = useGridAuth()
  const [toasts, setToasts] = useState<ToastEntry[]>([])

  const remove = useCallback((key: number) => {
    setToasts(prev => prev.filter(t => t.key !== key))
  }, [])

  const pushToast = useCallback((entry: ToastEntry) => {
    setToasts(prev => [entry, ...prev].slice(0, 5))
    window.setTimeout(() => remove(entry.key), TOAST_DURATION_MS)
  }, [remove])

  const onUnlock = useCallback((event: AchievementUnlockEvent) => {
    pushToast({ ...event, kind: 'achievement', key: makeKey() })
  }, [pushToast])

  const onMissionComplete = useCallback((event: MissionCompletedEvent) => {
    pushToast({ ...event, kind: 'mission', key: makeKey() })
    // Dispatch a DOM event so other components (e.g. MissionsPage) can
    // react to mission completions without opening a second ActionCable
    // subscription. Listeners use `window.addEventListener(...)`.
    window.dispatchEvent(new CustomEvent('grid:mission_completed', { detail: event }))
  }, [pushToast])

  useAchievementChannel({ enabled: !!hackr, onUnlock, onMissionComplete })

  if (toasts.length === 0) return null

  return (
    <div
      style={{
        position: 'fixed',
        bottom: '90px',
        right: '20px',
        zIndex: 9999,
        display: 'flex',
        flexDirection: 'column',
        gap: '10px',
        pointerEvents: 'none',
        maxWidth: '360px'
      }}
    >
      {toasts.map((t) => {
        if (t.kind === 'mission') return <MissionToast key={t.key} toast={t} onDismiss={() => remove(t.key)} />
        return <AchievementToast key={t.key} toast={t} onDismiss={() => remove(t.key)} />
      })}
    </div>
  )
}

const AchievementToast: React.FC<{ toast: AchievementUnlockEvent; onDismiss: () => void }> = ({ toast, onDismiss }) => {
  const color = categoryColor(toast.achievement.category)
  return (
    <div
      onClick={onDismiss}
      style={{
        pointerEvents: 'auto',
        cursor: 'pointer',
        background: '#111',
        border: '2px solid #fbbf24',
        padding: '12px 16px',
        fontFamily: 'monospace',
        color: '#d0d0d0',
        boxShadow: '0 0 20px rgba(251, 191, 36, 0.4)',
        animation: 'achievement-toast-slide-in 0.3s ease-out'
      }}
    >
      <div style={{ color: '#fbbf24', fontSize: '0.8em', fontWeight: 'bold', letterSpacing: '1px', marginBottom: '4px' }}>
        ACHIEVEMENT UNLOCKED
        <span style={{ color, marginLeft: '8px' }}>[{toast.achievement.category.toUpperCase()}]</span>
      </div>
      <div style={{ fontSize: '1.05em', marginBottom: '4px' }}>
        {toast.achievement.badge_icon ? (
          <span style={{ color: '#fbbf24', marginRight: '6px' }}>{toast.achievement.badge_icon}</span>
        ) : null}
        <span style={{ color: '#22d3ee', fontWeight: 'bold' }}>{toast.achievement.name}</span>
      </div>
      {toast.achievement.description ? (
        <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: '6px' }}>
          {toast.achievement.description}
        </div>
      ) : null}
      <div style={{ fontSize: '0.85em', display: 'flex', gap: '12px' }}>
        {toast.achievement.xp_reward > 0 && (
          <span style={{ color: '#34d399' }}>+{toast.achievement.xp_reward} XP</span>
        )}
        {toast.achievement.cred_reward > 0 && (
          <span style={{ color: '#fbbf24' }}>+{toast.achievement.cred_reward} CRED</span>
        )}
        {toast.leveled_up && toast.new_clearance != null && (
          <span style={{ color: '#fbbf24', fontWeight: 'bold' }}>▲ CL {toast.new_clearance}</span>
        )}
      </div>
    </div>
  )
}

const MissionToast: React.FC<{ toast: MissionCompletedEvent; onDismiss: () => void }> = ({ toast, onDismiss }) => {
  const { rewards } = toast
  return (
    <div
      onClick={onDismiss}
      style={{
        pointerEvents: 'auto',
        cursor: 'pointer',
        background: '#111',
        border: '2px solid #22d3ee',
        padding: '12px 16px',
        fontFamily: 'monospace',
        color: '#d0d0d0',
        boxShadow: '0 0 20px rgba(34, 211, 238, 0.4)',
        animation: 'achievement-toast-slide-in 0.3s ease-out'
      }}
    >
      <div style={{ color: '#22d3ee', fontSize: '0.8em', fontWeight: 'bold', letterSpacing: '1px', marginBottom: '4px' }}>
        MISSION COMPLETE
        {toast.mission.arc_name ? (
          <span style={{ color: '#a78bfa', marginLeft: '8px' }}>[{toast.mission.arc_name}]</span>
        ) : null}
      </div>
      <div style={{ fontSize: '1.05em', marginBottom: '6px' }}>
        <span style={{ color: '#fbbf24', fontWeight: 'bold' }}>{toast.mission.name}</span>
      </div>
      <div style={{ fontSize: '0.85em', display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
        {rewards.xp > 0 && <span style={{ color: '#34d399' }}>+{rewards.xp} XP</span>}
        {rewards.cred > 0 && <span style={{ color: '#fbbf24' }}>+{rewards.cred} CRED</span>}
        {rewards.rep.map((r, i) => (
          <span key={`rep-${i}`} style={{ color: r.delta >= 0 ? '#34d399' : '#ef4444' }}>
            {r.delta >= 0 ? '+' : ''}{r.delta} {r.faction}
          </span>
        ))}
        {rewards.items.map((item, i) => (
          <span key={`item-${i}`} style={{ color: '#60a5fa' }}>+ {item.name}</span>
        ))}
        {rewards.achievements.map((a, i) => (
          <span key={`ach-${i}`} style={{ color: '#fbbf24' }}>◆ {a.name}</span>
        ))}
        {toast.leveled_up && toast.new_clearance != null && (
          <span style={{ color: '#fbbf24', fontWeight: 'bold' }}>▲ CL {toast.new_clearance}</span>
        )}
      </div>
    </div>
  )
}

export default AchievementToastContainer
