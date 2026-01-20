import React from 'react'

interface ReconnectingBannerProps {
  status: 'connected' | 'connecting' | 'reconnecting' | 'disconnected'
  onReconnect?: () => void
}

export const ReconnectingBanner: React.FC<ReconnectingBannerProps> = ({ status, onReconnect }) => {
  if (status === 'connected') {
    return null
  }

  const getStatusText = () => {
    switch (status) {
    case 'connecting':
      return 'Establishing uplink...'
    case 'reconnecting':
      return 'Reconnecting to uplink...'
    case 'disconnected':
      return 'Uplink disconnected'
    default:
      return 'Connection issue'
    }
  }

  const getStatusColor = () => {
    switch (status) {
    case 'connecting':
    case 'reconnecting':
      return '#ffaa00'
    case 'disconnected':
      return '#ff5555'
    default:
      return '#888'
    }
  }

  return (
    <div
      className="reconnecting-banner"
      style={{
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        padding: '8px 16px',
        backgroundColor: 'rgba(0, 0, 0, 0.9)',
        borderBottom: `2px solid ${getStatusColor()}`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: '12px',
        zIndex: 10
      }}
    >
      <span
        style={{
          display: 'inline-block',
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          backgroundColor: getStatusColor(),
          animation: status === 'connecting' || status === 'reconnecting'
            ? 'pulse 1.5s ease-in-out infinite'
            : 'none'
        }}
      />

      <span style={{ color: getStatusColor(), fontSize: '0.85rem' }}>
        {getStatusText()}
      </span>

      {status === 'disconnected' && onReconnect && (
        <button
          onClick={onReconnect}
          style={{
            padding: '4px 12px',
            backgroundColor: '#333',
            border: '1px solid #555',
            color: '#ccc',
            fontSize: '0.75rem',
            cursor: 'pointer',
            fontFamily: "'Courier New', monospace"
          }}
        >
          Reconnect
        </button>
      )}

      <style>
        {`
          @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.3; }
          }
        `}
      </style>
    </div>
  )
}
