import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'

interface PresenceEvent {
  type: 'presence_update'
  hackr_alias: string
  from_room_id: number
  to_room_id: number
}

interface UseZonePresenceOptions {
  enabled: boolean
  refreshToken: number
  onPresenceUpdate: (event: PresenceEvent) => void
}

export function useZonePresence ({ enabled, refreshToken, onPresenceUpdate }: UseZonePresenceOptions) {
  const cableRef = useRef<Cable | null>(null)
  const channelRef = useRef<Channel | null>(null)
  const [connected, setConnected] = useState(false)

  const connect = useCallback(() => {
    if (!enabled) return

    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }

    if (!cableRef.current) {
      const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
      const wsUrl = `${wsProtocol}//${window.location.host}/cable`
      cableRef.current = createConsumer(wsUrl)
    }

    channelRef.current = cableRef.current.subscriptions.create(
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
            onPresenceUpdate(data)
          }
        }
      }
    )
  }, [enabled, onPresenceUpdate])

  const disconnect = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }
    if (cableRef.current) {
      cableRef.current.disconnect()
      cableRef.current = null
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
  }, [enabled, refreshToken, connect, disconnect])

  return { connected }
}
