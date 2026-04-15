import React, { useState, useCallback } from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useAchievementChannel, type AchievementUnlockEvent } from '~/hooks/useAchievementChannel'

const TOAST_DURATION_MS = 6000

interface ToastEntry extends AchievementUnlockEvent {
  key: number
}

const categoryColor = (category: string): string => {
  switch (category) {
  case 'music': return '#f472b6'
  case 'social': return '#60a5fa'
  case 'meta': return '#a3e635'
  case 'progression': return '#c084fc'
  default: return '#22d3ee' // grid
  }
}

export const AchievementToastContainer: React.FC = () => {
  const { hackr } = useGridAuth()
  const [toasts, setToasts] = useState<ToastEntry[]>([])

  const remove = useCallback((key: number) => {
    setToasts(prev => prev.filter(t => t.key !== key))
  }, [])

  const onUnlock = useCallback((event: AchievementUnlockEvent) => {
    const entry: ToastEntry = { ...event, key: Date.now() + Math.random() }
    setToasts(prev => [entry, ...prev].slice(0, 5))
    window.setTimeout(() => remove(entry.key), TOAST_DURATION_MS)
  }, [remove])

  useAchievementChannel({ enabled: !!hackr, onUnlock })

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
        const color = categoryColor(t.achievement.category)
        return (
          <div
            key={t.key}
            onClick={() => remove(t.key)}
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
              <span style={{ color, marginLeft: '8px' }}>[{t.achievement.category.toUpperCase()}]</span>
            </div>
            <div style={{ fontSize: '1.05em', marginBottom: '4px' }}>
              {t.achievement.badge_icon ? (
                <span style={{ color: '#fbbf24', marginRight: '6px' }}>{t.achievement.badge_icon}</span>
              ) : null}
              <span style={{ color: '#22d3ee', fontWeight: 'bold' }}>{t.achievement.name}</span>
            </div>
            {t.achievement.description ? (
              <div style={{ color: '#9ca3af', fontSize: '0.85em', marginBottom: '6px' }}>
                {t.achievement.description}
              </div>
            ) : null}
            <div style={{ fontSize: '0.85em', display: 'flex', gap: '12px' }}>
              {t.achievement.xp_reward > 0 && (
                <span style={{ color: '#34d399' }}>+{t.achievement.xp_reward} XP</span>
              )}
              {t.achievement.cred_reward > 0 && (
                <span style={{ color: '#fbbf24' }}>+{t.achievement.cred_reward} CRED</span>
              )}
              {t.leveled_up && t.new_clearance != null && (
                <span style={{ color: '#fbbf24', fontWeight: 'bold' }}>▲ CL {t.new_clearance}</span>
              )}
            </div>
          </div>
        )
      })}
    </div>
  )
}

export default AchievementToastContainer
