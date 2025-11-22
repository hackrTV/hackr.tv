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
  const [isConnected, setIsConnected] = useState(false)

  const connect = useCallback(() => {
    if (!enabled) {
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

    // Subscribe to PulseWireChannel
    channelRef.current = cableRef.current.subscriptions.create(
      { channel: 'PulseWireChannel' },
      {
        connected () {
          console.log('PulseWire: Connected to the Wire')
          setIsConnected(true)
        },
        disconnected () {
          console.log('PulseWire: Disconnected from the Wire')
          setIsConnected(false)
        },
        received (data: PulseWireMessage) {
          console.log('PulseWire: Received message:', data)
          onMessage(data)
        }
      }
    )
  }, [onMessage, enabled])

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

  // Connect when enabled changes
  useEffect(() => {
    if (enabled) {
      connect()
    }

    return () => {
      if (channelRef.current) {
        channelRef.current.unsubscribe()
        channelRef.current = null
      }
      if (cableRef.current) {
        cableRef.current.disconnect()
        cableRef.current = null
      }
      setIsConnected(false)
    }
  }, [enabled, connect])

  return {
    isConnected,
    reconnect: connect,
    disconnect
  }
}
