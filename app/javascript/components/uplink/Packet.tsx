import React from 'react'
import { Link } from 'react-router-dom'
import type { Packet as PacketType, UplinkHackr } from '../../types/uplink'

interface PacketProps {
  packet: PacketType
  currentHackr: UplinkHackr | null
  onDrop?: (packetId: number) => void
}

export const Packet: React.FC<PacketProps> = ({ packet, currentHackr, onDrop }) => {
  const isOwnPacket = currentHackr?.id === packet.grid_hackr.id
  const canDrop = currentHackr && (
    isOwnPacket ||
    currentHackr.role === 'operator' ||
    currentHackr.role === 'admin'
  )

  const getRoleColor = (role: string): string => {
    switch (role) {
    case 'admin':
      return '#ff5555'
    case 'operator':
      return '#ffaa00'
    default:
      return '#00d4ff'
    }
  }

  const getRoleBadge = (role: string): string | null => {
    switch (role) {
    case 'admin':
      return '[ADMIN]'
    case 'operator':
      return '[OP]'
    default:
      return null
    }
  }

  // Highlight @mentions in content
  const renderContent = (content: string) => {
    const mentionRegex = /@([a-zA-Z0-9_]+)/g
    const parts = content.split(mentionRegex)

    return parts.map((part, index) => {
      // Odd indices are the captured groups (usernames)
      if (index % 2 === 1) {
        const isCurrentUser = currentHackr?.hackr_alias.toLowerCase() === part.toLowerCase()
        return (
          <Link
            key={index}
            to={`/wire/${part}`}
            style={{
              color: isCurrentUser ? '#ffff00' : '#a78bfa',
              textDecoration: 'none',
              fontWeight: isCurrentUser ? 'bold' : 'normal',
              backgroundColor: isCurrentUser ? 'rgba(255, 255, 0, 0.1)' : 'transparent',
              padding: isCurrentUser ? '0 2px' : '0'
            }}
          >
            @{part}
          </Link>
        )
      }
      return part
    })
  }

  const formatTime = (timestamp: string): string => {
    const date = new Date(timestamp)
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
  }

  return (
    <div
      className="packet"
      style={{
        padding: '8px 12px',
        borderBottom: '1px solid #222',
        opacity: packet.dropped ? 0.5 : 1,
        backgroundColor: packet.dropped ? 'rgba(255, 0, 0, 0.05)' : 'transparent'
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
        <span
          className="packet-time"
          style={{
            color: '#555',
            fontSize: '0.75rem',
            fontFamily: "'Courier New', monospace",
            flexShrink: 0,
            marginTop: '2px'
          }}
        >
          {formatTime(packet.created_at)}
        </span>

        <div style={{ flex: 1, minWidth: 0 }}>
          <span
            className="packet-author"
            style={{
              color: getRoleColor(packet.grid_hackr.role),
              fontWeight: 'bold',
              marginRight: '6px'
            }}
          >
            <Link
              to={`/wire/${packet.grid_hackr.hackr_alias}`}
              style={{ color: 'inherit', textDecoration: 'none' }}
            >
              @{packet.grid_hackr.hackr_alias}
            </Link>
            {getRoleBadge(packet.grid_hackr.role) && (
              <span style={{ fontSize: '0.7rem', marginLeft: '4px', opacity: 0.8 }}>
                {getRoleBadge(packet.grid_hackr.role)}
              </span>
            )}
          </span>

          <span
            className="packet-content"
            style={{
              color: packet.dropped ? '#666' : '#ccc',
              wordBreak: 'break-word'
            }}
          >
            {packet.dropped ? '[PACKET DROPPED]' : renderContent(packet.content)}
          </span>
        </div>

        {canDrop && !packet.dropped && onDrop && (
          <button
            onClick={() => onDrop(packet.id)}
            style={{
              background: 'transparent',
              border: 'none',
              color: '#555',
              cursor: 'pointer',
              padding: '2px 6px',
              fontSize: '0.7rem',
              opacity: 0.6,
              transition: 'opacity 0.2s'
            }}
            onMouseOver={(e) => (e.currentTarget.style.opacity = '1')}
            onMouseOut={(e) => (e.currentTarget.style.opacity = '0.6')}
            title="Drop packet"
          >
            ×
          </button>
        )}
      </div>
    </div>
  )
}
