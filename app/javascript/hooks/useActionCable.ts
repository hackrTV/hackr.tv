import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'

export interface GridEvent {
  type: 'movement' | 'say' | 'take' | 'drop' | 'system_broadcast'
  hackr_alias?: string
  message?: string
  item_name?: string
  direction?: string
  from_room_id?: number
  to_room_id?: number
  sender?: string
}

interface UseActionCableOptions {
  roomId: number | null
  onEvent: (event: GridEvent) => void
  enabled: boolean
}

export const useActionCable = ({ roomId, onEvent, enabled }: UseActionCableOptions) => {
  const cableRef = useRef<Cable | null>(null)
  const channelRef = useRef<Channel | null>(null)
  const reconnectTimeoutRef = useRef<number | null>(null)
  const reconnectAttemptsRef = useRef(0)
  const connectRef = useRef<() => void>(() => {})
  const [isConnected, setIsConnected] = useState(false)
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'connecting' | 'reconnecting' | 'disconnected'>('disconnected')

  const clearReconnectTimeout = useCallback(() => {
    if (reconnectTimeoutRef.current !== null) {
      window.clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }
  }, [])

  const scheduleReconnect = useCallback(() => {
    if (!enabled || !roomId) {
      return
    }

    clearReconnectTimeout()
    reconnectAttemptsRef.current += 1
    const delay = Math.min(1000 * 2 ** (reconnectAttemptsRef.current - 1), 10000)
    setConnectionStatus('reconnecting')
    reconnectTimeoutRef.current = window.setTimeout(() => {
      connectRef.current()
    }, delay)
  }, [clearReconnectTimeout, enabled, roomId])

  const connect = useCallback(() => {
    if (!enabled || !roomId) {
      return
    }

    clearReconnectTimeout()
    setConnectionStatus(reconnectAttemptsRef.current > 0 ? 'reconnecting' : 'connecting')

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
          reconnectAttemptsRef.current = 0
          setIsConnected(true)
          setConnectionStatus('connected')
        },
        disconnected () {
          console.log('GridChannel: Disconnected from WebSocket')
          setIsConnected(false)
          setConnectionStatus('disconnected')
          scheduleReconnect()
        },
        received (data: GridEvent) {
          console.log('GridChannel: Received event:', data)
          onEvent(data)
        }
      }
    )
  }, [roomId, onEvent, enabled, clearReconnectTimeout, scheduleReconnect])

  const disconnect = useCallback(() => {
    clearReconnectTimeout()
    reconnectAttemptsRef.current = 0
    if (channelRef.current) {
      channelRef.current.unsubscribe()
      channelRef.current = null
    }
    if (cableRef.current) {
      cableRef.current.disconnect()
      cableRef.current = null
    }
    setIsConnected(false)
    setConnectionStatus('disconnected')
  }, [clearReconnectTimeout])

  useEffect(() => {
    connectRef.current = connect
  }, [connect])

  // Connect when roomId changes or when enabled
  useEffect(() => {
    reconnectAttemptsRef.current = 0
    if (enabled && roomId) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- intentional: establish WebSocket on mount
      connect()
    } else {
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [roomId, enabled, connect, disconnect])

  const reconnect = useCallback(() => {
    reconnectAttemptsRef.current = 0
    connect()
  }, [connect])

  return {
    isConnected,
    connectionStatus,
    reconnect
  }
}
