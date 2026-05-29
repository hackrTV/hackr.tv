import { useEffect, useRef, useCallback, useState } from 'react'
import { Channel } from '@rails/actioncable'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

interface PresenceEvent {
  type: 'presence_update'
  hackr_alias: string
  from_room_id: number
  to_room_id: number
}

interface UseZonePresenceOptions {
  enabled: boolean
  onPresenceUpdate: (event: PresenceEvent) => void
}

export function useZonePresence ({ enabled, onPresenceUpdate }: UseZonePresenceOptions) {
  const channelRef = useRef<Channel | null>(null)
  const [connected, setConnected] = useState(false)

  // Ref keeps connect() stable regardless of callback identity changes
  const onPresenceUpdateRef = useRef(onPresenceUpdate)
  useEffect(() => {
    onPresenceUpdateRef.current = onPresenceUpdate
  }, [onPresenceUpdate])

  const connect = useCallback(() => {
    if (!enabled) return

    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }

    const cable = getActionCableConsumer()

    channelRef.current = cable.subscriptions.create(
      { channel: 'ZoneChannel' },
      {
        connected () {
          setConnected(true)
        },
        disconnected () {
          setConnected(false)
        },
        received (data: PresenceEvent) {
          if (data.type === 'presence_update') {
            onPresenceUpdateRef.current(data)
          }
        }
      }
    )
  }, [enabled])

  const disconnect = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }
    setConnected(false)
  }, [])

  useEffect(() => {
    if (enabled) {
      connect()
    } else {
      disconnect()
    }
    return () => disconnect()
  }, [enabled, connect, disconnect])

  return { connected }
}
