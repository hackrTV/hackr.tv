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

export interface MissionCompletionRewards {
  xp: number
  cred: number
  rep: Array<{ faction: string; delta: number }>
  items: Array<{ name: string }>
  achievements: Array<{ slug: string; name: string }>
}

export interface MissionCompletedEvent {
  type: 'mission_completed'
  mission: { slug: string; name: string; arc_name: string | null }
  rewards: MissionCompletionRewards
  leveled_up: boolean
  new_clearance: number | null
}

// Union of every event the channel fans out. The server discriminates on
// `type` so clients can filter without a separate channel per feature.
export type GridChannelEvent = AchievementUnlockEvent | MissionCompletedEvent

interface UseAchievementChannelOptions {
  enabled: boolean
  onUnlock?: (event: AchievementUnlockEvent) => void
  onMissionComplete?: (event: MissionCompletedEvent) => void
}

/**
 * Subscribes to the per-hackr AchievementChannel stream. Routes inbound
 * events by `type` to the appropriate callback. The channel carries
 * achievement unlocks AND mission completion broadcasts — one WebSocket
 * subscription serves both surfaces. Only active while `enabled` is true.
 *
 * Reuses the shared ActionCable consumer (`lib/actionCableConsumer`)
 * so there is one WebSocket for the whole app — this hook only
 * manages its own subscription lifecycle.
 */
export const useAchievementChannel = ({ enabled, onUnlock, onMissionComplete }: UseAchievementChannelOptions) => {
  const channelRef = useRef<Channel | null>(null)
  const unlockRef = useRef(onUnlock)
  const missionRef = useRef(onMissionComplete)

  useEffect(() => {
    unlockRef.current = onUnlock
  }, [onUnlock])
  useEffect(() => {
    missionRef.current = onMissionComplete
  }, [onMissionComplete])

  const connect = useCallback(() => {
    if (!enabled) return

    const cable = getActionCableConsumer()
    channelRef.current = cable.subscriptions.create(
      { channel: 'AchievementChannel' },
      {
        received (data: GridChannelEvent) {
          if (data?.type === 'achievement_unlocked') {
            unlockRef.current?.(data)
          } else if (data?.type === 'mission_completed') {
            missionRef.current?.(data)
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
