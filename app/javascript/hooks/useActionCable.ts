import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'

export interface GridEvent {
  type: 'movement' | 'say' | 'take' | 'drop'
  hackr_alias?: string
  message?: string
  item_name?: string
  direction?: string
  from_room_id?: number
  to_room_id?: number
}

interface UseActionCableOptions {
  roomId: number | null
  onEvent: (event: GridEvent) => void
  enabled: boolean
}

export const useActionCable = ({ roomId, onEvent, enabled }: UseActionCableOptions) => {
  const cableRef = useRef<Cable | null>(null)
  const channelRef = useRef<Channel | null>(null)
  const [isConnected, setIsConnected] = useState(false)

  const connect = useCallback(() => {
    if (!enabled || !roomId) {
      return
    }

    // Clean up existing connection
    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }

    // Create cable consumer if it doesn't exist
    if (!cableRef.current) {
      const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
      const wsUrl = `${wsProtocol}//${window.location.host}/cable`
      cableRef.current = createConsumer(wsUrl)
    }

    // Subscribe to GridChannel
    channelRef.current = cableRef.current.subscriptions.create(
      { channel: 'GridChannel' },
      {
        connected () {
          console.log('GridChannel: Connected to WebSocket')
          setIsConnected(true)
        },
        disconnected () {
          console.log('GridChannel: Disconnected from WebSocket')
          setIsConnected(false)
        },
        received (data: GridEvent) {
          console.log('GridChannel: Received event:', data)
          onEvent(data)
        }
      }
    )
  }, [roomId, onEvent, enabled])

  const disconnect = useCallback(() => {
    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }
    if (cableRef.current) {
      cableRef.current.disconnect()
      cableRef.current = null
    }
    setIsConnected(false)
  }, [])

  // Connect when roomId changes or when enabled
  useEffect(() => {
    if (enabled && roomId) {
      connect()
    } else {
      // eslint-disable-next-line react-hooks/set-state-in-effect
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [roomId, enabled, connect, disconnect])

  return {
    isConnected,
    reconnect: connect
  }
}
