import React from 'react'
import { Link } from 'react-router-dom'
import type { Packet as PacketType, UplinkHackr } from '../../types/uplink'
import { processUrls } from '../../utils/urlContent'

interface PacketProps {
  packet: PacketType
  currentHackr: UplinkHackr | null
  onDrop?: (packetId: number) => void
}

const PLATFORM_COLORS: Record<string, { badge: string; username: string }> = {
  TTV: { badge: '#a78bfa', username: '#c4b5fd' },
  YT_: { badge: '#ff5555', username: '#fca5a5' },
  SYNTHIA: { badge: '#00ff88', username: '#00ff88' }
}

const parseBridgedContent = (content: string) => {
  const match = content.match(/^\[.+?\]\s*(.+?):\s(.+)$/)
  if (match) return { username: match[1], message: match[2] }
  return null
}

export const Packet: React.FC<PacketProps> = ({ packet, currentHackr, onDrop }) => {
  const isBotSource = packet.source === 'SYNTHIA'
  const isBridged = !!packet.source && !isBotSource
  const isOwnPacket = currentHackr?.id === packet.grid_hackr.id
  const canDrop = currentHackr && (
    isOwnPacket ||
    currentHackr.role === 'operator' ||
    currentHackr.role === 'admin'
  )

  const getRoleColor = (role: string): string => {
    switch (role) {
    case 'admin':
      return '#00d4ff'
    case 'operator':
      return '#ffaa00'
    default:
      return '#cc0088'
    }
  }

  const getRoleBadge = (role: string): string | null => {
    switch (role) {
    case 'admin':
      return 'ADMIN'
    case 'operator':
      return 'OP'
    default:
      return null
    }
  }

  // Highlight @mentions in a plain string fragment
  const renderMentions = (text: string, keyPrefix: string) => {
    const mentionRegex = /@([a-zA-Z0-9_]+)/g
    const parts = text.split(mentionRegex)

    return parts.map((part, index) => {
      // Odd indices are the captured groups (usernames)
      if (index % 2 === 1) {
        const isCurrentUser = currentHackr?.hackr_alias.toLowerCase() === part.toLowerCase()
        return (
          <Link
            key={`${keyPrefix}-${index}`}
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

  // Process URLs then @mentions in content
  const renderContent = (content: string) => {
    const allowLinks = !packet.source && packet.grid_hackr.role === 'admin'
    const urlProcessed = processUrls(content, allowLinks)

    return urlProcessed.flatMap((part, i) => {
      if (typeof part === 'string') {
        return renderMentions(part, `m${i}`)
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

  const platformColors = packet.source ? PLATFORM_COLORS[packet.source] : null

  return (
    <div
      className="packet"
      style={{
        padding: '8px 12px',
        borderBottom: '1px solid #222',
        opacity: packet.dropped ? 0.3 : isBridged ? 0.5 : 1,
        backgroundColor: packet.dropped ? 'rgba(255, 0, 0, 0.05)' : 'transparent'
      }}
    >
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: '8px' }}>
        <div style={{ flexShrink: 0, marginTop: '2px', textAlign: 'center' }}>
          <span
            className="packet-time"
            style={{
              color: '#555',
              fontSize: '0.75rem',
              fontFamily: 'Terminus, monospace',
              display: 'block'
            }}
          >
            {formatTime(packet.created_at)}
          </span>
          {(isBridged || isBotSource) && platformColors ? (
            <span
              style={{
                color: platformColors.badge,
                fontSize: '0.6rem',
                fontFamily: 'Terminus, monospace',
                fontWeight: 'bold',
                display: 'block',
                lineHeight: 1,
                marginTop: '2px'
              }}
            >
              {packet.source}
            </span>
          ) : getRoleBadge(packet.grid_hackr.role) && (
            <span
              style={{
                color: getRoleColor(packet.grid_hackr.role),
                fontSize: '0.6rem',
                fontFamily: 'Terminus, monospace',
                fontWeight: 'bold',
                display: 'block',
                lineHeight: 1,
                marginTop: '2px'
              }}
            >
              {getRoleBadge(packet.grid_hackr.role)}
            </span>
          )}
        </div>

        <div style={{ flex: 1, minWidth: 0 }}>
          {isBridged ? (
            // Bridged message rendering
            (() => {
              const parsed = parseBridgedContent(packet.content)
              if (parsed) {
                return (
                  <span
                    className="packet-content"
                    style={{ wordBreak: 'break-word' }}
                  >
                    <span
                      style={{
                        color: platformColors?.username || '#ccc',
                        fontWeight: 'bold',
                        marginRight: '6px'
                      }}
                    >
                      {parsed.username}:
                    </span>
                    <span style={{ color: packet.dropped ? '#666' : '#ccc' }}>
                      {packet.dropped ? '[PACKET DROPPED]' : renderContent(parsed.message)}
                    </span>
                  </span>
                )
              }
              // Fallback: render raw content if parsing fails
              return (
                <span
                  className="packet-content"
                  style={{ color: packet.dropped ? '#666' : '#ccc', wordBreak: 'break-word' }}
                >
                  {packet.dropped ? '[PACKET DROPPED]' : renderContent(packet.content)}
                </span>
              )
            })()
          ) : (
            // Native message rendering
            <>
              {!isBotSource && (
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
                </span>
              )}

              <span
                className="packet-content"
                style={{
                  color: packet.dropped ? '#666' : isBotSource ? platformColors!.username : '#ccc',
                  wordBreak: 'break-word'
                }}
              >
                {packet.dropped ? '[PACKET DROPPED]' : renderContent(packet.content)}
              </span>
            </>
          )}
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
