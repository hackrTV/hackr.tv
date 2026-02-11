import React, { useState, useEffect, useCallback, useRef } from 'react'
import { Link } from 'react-router-dom'
import { ChannelTabs } from './ChannelTabs'
import { PacketList } from './PacketList'
import { PacketInput } from './PacketInput'
import { PresenceIndicator } from './PresenceIndicator'
import { ReconnectingBanner } from './ReconnectingBanner'
import { useUplink } from '../../hooks/useUplink'
import { useStreamStatus } from '../../hooks/useStreamStatus'
import { apiJson } from '~/utils/apiClient'
import type { ChatChannel, Packet, UplinkHackr, UplinkMessage, ChannelsResponse, CreatePacketResponse } from '../../types/uplink'

interface UplinkPanelProps {
  defaultChannel?: string
  livestreamOnly?: boolean
  allowPopout?: boolean
  onPopout?: () => void
}

export const UplinkPanel: React.FC<UplinkPanelProps> = ({
  defaultChannel = 'ambient',
  livestreamOnly = false,
  allowPopout = false,
  onPopout
}) => {
  const [channels, setChannels] = useState<ChatChannel[]>([])
  const [activeChannel, setActiveChannel] = useState<string>(defaultChannel)
  const [packets, setPackets] = useState<Packet[]>([])
  const [currentHackr, setCurrentHackr] = useState<UplinkHackr | null>(null)
  const [presenceCount, setPresenceCount] = useState(0)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const loadedPacketIds = useRef<Set<number>>(new Set())

  // Stream status for #live channel availability
  const { isLive } = useStreamStatus()

  // Fetch channels on mount
  useEffect(() => {
    const fetchChannels = async () => {
      try {
        const data = await apiJson<ChannelsResponse>('/api/uplink/channels')
        setChannels(data.channels)
        setCurrentHackr(data.current_hackr)
        setIsLoading(false)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load channels')
        setIsLoading(false)
      }
    }

    fetchChannels()
  }, [])

  // Handle WebSocket messages
  const handleMessage = useCallback((message: UplinkMessage) => {
    switch (message.type) {
    case 'initial_packets':
      if (message.packets) {
        setPackets(message.packets)
        loadedPacketIds.current = new Set(message.packets.map(p => p.id))
      }
      // Set initial presence count if provided
      if (message.presence_count !== undefined) {
        setPresenceCount(message.presence_count)
      }
      break

    case 'new_packet':
      if (message.packet && !loadedPacketIds.current.has(message.packet.id)) {
        setPackets(prev => [...prev, message.packet!])
        loadedPacketIds.current.add(message.packet.id)
      }
      break

    case 'packet_dropped':
      if (message.packet_id) {
        setPackets(prev => prev.map(p =>
          p.id === message.packet_id
            ? { ...p, dropped: true }
            : p
        ))
      }
      break

    case 'packet_restored':
      if (message.packet_id) {
        setPackets(prev => prev.map(p =>
          p.id === message.packet_id
            ? { ...p, dropped: false }
            : p
        ))
      }
      break

    case 'presence_update':
      if (message.count !== undefined) {
        setPresenceCount(message.count)
      }
      break
    }
  }, [])

  // Connect to WebSocket for current channel
  const { isConnected, connectionStatus, reconnect } = useUplink({
    channel: activeChannel,
    onMessage: handleMessage,
    enabled: !!activeChannel
  })

  // Clear packets and reset presence when switching channels
  const handleChannelChange = (slug: string) => {
    setPackets([])
    loadedPacketIds.current.clear()
    setPresenceCount(0)
    setActiveChannel(slug)
  }

  // Send a packet
  const handleSendPacket = async (content: string): Promise<CreatePacketResponse> => {
    try {
      const response = await fetch(`/api/uplink/channels/${activeChannel}/packets`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ packet: { content } }),
        credentials: 'same-origin'
      })

      const data = await response.json()
      return data
    } catch (err) {
      return {
        success: false,
        error: err instanceof Error ? err.message : 'Failed to send packet'
      }
    }
  }

  // Drop a packet
  const handleDropPacket = async (packetId: number) => {
    try {
      const response = await fetch(`/api/uplink/packets/${packetId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json'
        },
        credentials: 'same-origin'
      })

      if (!response.ok) {
        const data = await response.json()
        console.error('Failed to drop packet:', data.error)
      }
    } catch (err) {
      console.error('Failed to drop packet:', err)
    }
  }

  // Get current channel config
  const currentChannelConfig = channels.find(c => c.slug === activeChannel)
  const canAccessChannel = currentHackr && currentChannelConfig?.accessible
  const isChannelAvailable = currentChannelConfig?.currently_available ||
    (currentChannelConfig?.requires_livestream && isLive)

  if (isLoading) {
    return (
      <div
        style={{
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#666'
        }}
      >
        Establishing uplink...
      </div>
    )
  }

  if (error) {
    return (
      <div
        style={{
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#ff5555',
          gap: '12px'
        }}
      >
        <p>{error}</p>
        <button
          onClick={() => window.location.reload()}
          style={{
            padding: '8px 16px',
            backgroundColor: '#333',
            border: '1px solid #555',
            color: '#ccc',
            cursor: 'pointer'
          }}
        >
          Retry
        </button>
      </div>
    )
  }

  return (
    <div
      className="uplink-panel"
      style={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: '#0d0d0d',
        border: '1px solid #333',
        position: 'relative',
        overflow: 'hidden'
      }}
    >
      <ReconnectingBanner status={connectionStatus} onReconnect={reconnect} />

      {/* Header */}
      <div
        style={{
          padding: '12px 16px',
          borderBottom: '1px solid #333',
          backgroundColor: '#111',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between'
        }}
      >
        <h2
          style={{
            margin: 0,
            fontSize: '1rem',
            color: '#7c3aed',
            fontFamily: 'Terminus, monospace'
          }}
        >
          UPLINK
        </h2>

        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {currentHackr && (
            <span style={{ fontSize: '0.75rem', color: '#666' }}>
              @{currentHackr.hackr_alias}
            </span>
          )}
          {allowPopout && onPopout && (
            <button
              onClick={onPopout}
              title="Pop out Uplink"
              style={{
                background: 'none',
                border: '1px solid #444',
                color: '#888',
                padding: '4px 8px',
                fontSize: '0.75rem',
                cursor: 'pointer',
                fontFamily: 'Terminus, monospace',
                borderRadius: '2px'
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#7c3aed'
                e.currentTarget.style.color = '#7c3aed'
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = '#444'
                e.currentTarget.style.color = '#888'
              }}
            >
              [^]
            </button>
          )}
        </div>
      </div>

      {/* Channel tabs */}
      <ChannelTabs
        channels={livestreamOnly ? channels.filter(c => c.requires_livestream) : channels}
        activeChannel={activeChannel}
        onChannelChange={handleChannelChange}
        isLive={isLive}
      />

      {/* Presence indicator */}
      <PresenceIndicator count={presenceCount} isConnected={isConnected} />

      {/* Channel unavailable message */}
      {!isChannelAvailable && currentChannelConfig?.requires_livestream && (
        <div
          style={{
            padding: '20px',
            textAlign: 'center',
            color: '#666',
            backgroundColor: '#0a0a0a',
            flex: 1,
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center'
          }}
        >
          <p style={{ margin: 0 }}>
            {currentChannelConfig.name} is only available during livestreams.
          </p>
          <p style={{ margin: '10px 0 0 0', fontSize: '0.85rem' }}>
            Check back when we&apos;re live!
          </p>
        </div>
      )}

      {/* Packet list */}
      {isChannelAvailable && (
        <PacketList
          packets={packets}
          currentHackr={currentHackr}
          onDrop={handleDropPacket}
        />
      )}

      {/* Input area */}
      {isChannelAvailable && (
        currentHackr ? (
          currentHackr.is_blackouted ? (
            <div
              style={{
                padding: '16px',
                textAlign: 'center',
                backgroundColor: 'rgba(255, 0, 0, 0.1)',
                color: '#ff5555'
              }}
            >
              You have been blackedout from Uplink.
            </div>
          ) : currentHackr.is_squelched ? (
            <div
              style={{
                padding: '16px',
                textAlign: 'center',
                backgroundColor: 'rgba(255, 170, 0, 0.1)',
                color: '#ffaa00'
              }}
            >
              You have been squelched. Please wait for your squelch to expire.
            </div>
          ) : (
            <PacketInput
              onSubmit={handleSendPacket}
              disabled={!canAccessChannel}
              slowModeSeconds={currentChannelConfig?.slow_mode_seconds || 0}
            />
          )
        ) : (
          <div
            style={{
              padding: '16px',
              textAlign: 'center',
              backgroundColor: '#111',
              borderTop: '1px solid #333',
              color: '#999'
            }}
          >
            <Link
              to="/grid/login"
              style={{
                color: '#7c3aed',
                textDecoration: 'none'
              }}
            >
              Log in
            </Link>
            {' '}to transmit packets
          </div>
        )
      )}
    </div>
  )
}
