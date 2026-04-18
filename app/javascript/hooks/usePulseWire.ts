import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'
import type { PulseWireMessage } from '../types/pulse'

interface UsePulseWireOptions {
  onMessage: (message: PulseWireMessage) => void
  enabled?: boolean
}

export const usePulseWire = ({ onMessage, enabled = true }: UsePulseWireOptions) => {
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
    if (!enabled) {
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

    // Subscribe to PulseWireChannel
    channelRef.current = cableRef.current.subscriptions.create(
      { channel: 'PulseWireChannel' },
      {
        connected () {
          console.log('PulseWire: Connected to the Wire')
          reconnectAttemptsRef.current = 0
          setIsConnected(true)
          setConnectionStatus('connected')
        },
        disconnected () {
          console.log('PulseWire: Disconnected from the Wire')
          setIsConnected(false)
          setConnectionStatus('disconnected')
          scheduleReconnect()
        },
        received (data: PulseWireMessage) {
          console.log('PulseWire: Received message:', data)
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

  // Connect when enabled changes
  useEffect(() => {
    reconnectAttemptsRef.current = 0
    if (enabled) {
      connect()
    } else {
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [enabled, connect, disconnect])

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
