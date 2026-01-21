import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'
import type { UplinkMessage } from '../types/uplink'

interface UseUplinkOptions {
  channel: string
  onMessage: (message: UplinkMessage) => void
  enabled?: boolean
}

export const useUplink = ({ channel, onMessage, enabled = true }: UseUplinkOptions) => {
  const cableRef = useRef<Cable | null>(null)
  const channelRef = useRef<Channel | null>(null)
  const reconnectTimeoutRef = useRef<number | null>(null)
  const reconnectAttemptsRef = useRef(0)
  const connectRef = useRef<() => void>(() => {})
  const [isConnected, setIsConnected] = useState(false)
  const [connectionStatus, setConnectionStatus] = useState<'connected' | 'connecting' | 'reconnecting' | 'disconnected'>('disconnected')
  const currentChannelRef = useRef(channel)

  const clearReconnectTimeout = useCallback(() => {
    if (reconnectTimeoutRef.current !== null) {
      window.clearTimeout(reconnectTimeoutRef.current)
      reconnectTimeoutRef.current = null
    }
  }, [])

  const scheduleReconnect = useCallback(() => {
    if (!enabled) {
      return
    }

    clearReconnectTimeout()
    reconnectAttemptsRef.current += 1
    const delay = Math.min(1000 * 2 ** (reconnectAttemptsRef.current - 1), 10000)
    setConnectionStatus('reconnecting')
    reconnectTimeoutRef.current = window.setTimeout(() => {
      connectRef.current()
    }, delay)
  }, [clearReconnectTimeout, enabled])

  const connect = useCallback(() => {
    if (!enabled || !currentChannelRef.current) {
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

    // Subscribe to LiveChatChannel with the chat channel slug
    channelRef.current = cableRef.current.subscriptions.create(
      { channel: 'LiveChatChannel', chat_channel: currentChannelRef.current },
      {
        connected () {
          console.log(`Uplink: Connected to #${currentChannelRef.current}`)
          reconnectAttemptsRef.current = 0
          setIsConnected(true)
          setConnectionStatus('connected')
        },
        disconnected () {
          console.log(`Uplink: Disconnected from #${currentChannelRef.current}`)
          setIsConnected(false)
          setConnectionStatus('disconnected')
          scheduleReconnect()
        },
        rejected () {
          console.log(`Uplink: Connection rejected for #${currentChannelRef.current}`)
          setIsConnected(false)
          setConnectionStatus('disconnected')
        },
        received (data: UplinkMessage) {
          console.log('Uplink: Received message:', data)
          onMessage(data)
        }
      }
    )
  }, [onMessage, enabled, clearReconnectTimeout, scheduleReconnect])

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

  // Update channel reference
  useEffect(() => {
    currentChannelRef.current = channel
  }, [channel])

  // Connect when enabled or channel changes
  useEffect(() => {
    reconnectAttemptsRef.current = 0
    if (enabled && channel) {
      // eslint-disable-next-line react-hooks/set-state-in-effect -- intentional: establish WebSocket on mount
      connect()
    } else {
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [enabled, channel, connect, disconnect])

  const reconnect = useCallback(() => {
    reconnectAttemptsRef.current = 0
    connect()
  }, [connect])

  return {
    isConnected,
    connectionStatus,
    reconnect,
    disconnect
  }
}
