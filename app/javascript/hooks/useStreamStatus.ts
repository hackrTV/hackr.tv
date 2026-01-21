import { useEffect, useRef, useCallback, useState } from 'react'
import { createConsumer, Cable, Channel } from '@rails/actioncable'
import type { StreamStatusMessage, StreamInfo } from '../types/uplink'

interface UseStreamStatusOptions {
  enabled?: boolean
}

export const useStreamStatus = ({ enabled = true }: UseStreamStatusOptions = {}) => {
  const cableRef = useRef<Cable | null>(null)
  const channelRef = useRef<Channel | null>(null)
  const reconnectTimeoutRef = useRef<number | null>(null)
  const reconnectAttemptsRef = useRef(0)
  const connectRef = useRef<() => void>(() => {})
  const [isLive, setIsLive] = useState(false)
  const [streamInfo, setStreamInfo] = useState<StreamInfo | null>(null)
  const [isConnected, setIsConnected] = useState(false)

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
    reconnectTimeoutRef.current = window.setTimeout(() => {
      connectRef.current()
    }, delay)
  }, [clearReconnectTimeout, enabled])

  const handleMessage = useCallback((message: StreamStatusMessage) => {
    console.log('StreamStatus: Received message:', message)

    switch (message.type) {
    case 'stream_status':
    case 'stream_live':
      setIsLive(message.is_live)
      setStreamInfo(message.stream)
      break
    case 'stream_ended':
      setIsLive(false)
      setStreamInfo(null)
      break
    }
  }, [])

  const connect = useCallback(() => {
    if (!enabled) {
      return
    }

    clearReconnectTimeout()

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

    // Subscribe to StreamStatusChannel
    channelRef.current = cableRef.current.subscriptions.create(
      { channel: 'StreamStatusChannel' },
      {
        connected () {
          console.log('StreamStatus: Connected')
          reconnectAttemptsRef.current = 0
          setIsConnected(true)
        },
        disconnected () {
          console.log('StreamStatus: Disconnected')
          setIsConnected(false)
          scheduleReconnect()
        },
        received (data: StreamStatusMessage) {
          handleMessage(data)
        }
      }
    )
  }, [enabled, clearReconnectTimeout, scheduleReconnect, handleMessage])

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
      // eslint-disable-next-line react-hooks/set-state-in-effect -- intentional: cleanup WebSocket on disable
      disconnect()
    }

    return () => {
      disconnect()
    }
  }, [enabled, connect, disconnect])

  return {
    isLive,
    streamInfo,
    isConnected
  }
}
