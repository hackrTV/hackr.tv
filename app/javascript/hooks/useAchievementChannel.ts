import { useEffect, useRef, useCallback } from 'react'
import { Channel } from '@rails/actioncable'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

export interface AchievementUnlock {
  slug: string
  name: string
  description: string | null
  badge_icon: string | null
  category: string
  xp_reward: number
  cred_reward: number
}

export interface AchievementUnlockEvent {
  type: 'achievement_unlocked'
  achievement: AchievementUnlock
  leveled_up: boolean
  new_clearance: number | null
}

interface UseAchievementChannelOptions {
  enabled: boolean
  onUnlock: (event: AchievementUnlockEvent) => void
}

/**
 * Subscribes to the per-hackr AchievementChannel stream. When any
 * achievement unlocks (via Terminal action, content-surface trigger, or
 * login sweep job), the server broadcasts to this channel and the hook
 * invokes `onUnlock`. Only active while `enabled` is true (logged in).
 *
 * Reuses the shared ActionCable consumer (`lib/actionCableConsumer`)
 * so there is one WebSocket for the whole app — this hook only
 * manages its own subscription lifecycle.
 */
export const useAchievementChannel = ({ enabled, onUnlock }: UseAchievementChannelOptions) => {
  const channelRef = useRef<Channel | null>(null)
  const handlerRef = useRef(onUnlock)

  useEffect(() => {
    handlerRef.current = onUnlock
  }, [onUnlock])

  const connect = useCallback(() => {
    if (!enabled) return

    const cable = getActionCableConsumer()
    channelRef.current = cable.subscriptions.create(
      { channel: 'AchievementChannel' },
      {
        received (data: AchievementUnlockEvent) {
          if (data?.type === 'achievement_unlocked') {
            handlerRef.current(data)
          }
        }
      }
    )
  }, [enabled])

  const disconnect = useCallback(() => {
    // Unsubscribe THIS channel only; do not disconnect the shared
    // cable — other hooks may still be subscribed on it.
    channelRef.current?.unsubscribe()
    channelRef.current = null
  }, [])

  useEffect(() => {
    if (enabled) {
      connect()
    } else {
      disconnect()
    }
    return disconnect
  }, [enabled, connect, disconnect])
}
