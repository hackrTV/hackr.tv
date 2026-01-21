import React from 'react'
import type { ChatChannel } from '../../types/uplink'

interface ChannelTabsProps {
  channels: ChatChannel[]
  activeChannel: string
  onChannelChange: (slug: string) => void
  isLive: boolean
}

export const ChannelTabs: React.FC<ChannelTabsProps> = ({
  channels,
  activeChannel,
  onChannelChange,
  isLive
}) => {
  return (
    <div
      className="channel-tabs"
      style={{
        display: 'flex',
        borderBottom: '1px solid #333',
        backgroundColor: '#111'
      }}
    >
      {channels.map(channel => {
        const isActive = channel.slug === activeChannel
        const isAvailable = channel.currently_available || (channel.requires_livestream && isLive)
        const isDisabled = !isAvailable && !isActive

        return (
          <button
            key={channel.slug}
            onClick={() => !isDisabled && !isActive && onChannelChange(channel.slug)}
            disabled={isDisabled}
            title={channel.description}
            style={{
              flex: 1,
              padding: '12px 16px',
              backgroundColor: isActive ? '#1a1a1a' : 'transparent',
              border: 'none',
              borderBottom: isActive ? '2px solid #7c3aed' : '2px solid transparent',
              color: isActive ? '#7c3aed' : isDisabled ? '#444' : '#888',
              fontFamily: 'Terminus, monospace',
              fontSize: '0.9rem',
              cursor: isDisabled ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
              position: 'relative'
            }}
          >
            {channel.name}

            {channel.requires_livestream && (
              <span
                style={{
                  display: 'inline-block',
                  width: '6px',
                  height: '6px',
                  borderRadius: '50%',
                  backgroundColor: isLive ? '#00ff00' : '#555',
                  marginLeft: '6px',
                  verticalAlign: '1px'
                }}
                title={isLive ? 'LIVE' : 'Offline'}
              />
            )}

            {channel.slow_mode_seconds > 0 && isActive && (
              <span
                style={{
                  position: 'absolute',
                  top: '4px',
                  right: '8px',
                  fontSize: '0.6rem',
                  color: '#555'
                }}
              >
                {channel.slow_mode_seconds}s
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}
