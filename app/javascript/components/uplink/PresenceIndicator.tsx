import React from 'react'

interface PresenceIndicatorProps {
  count: number
  isConnected: boolean
}

export const PresenceIndicator: React.FC<PresenceIndicatorProps> = ({ count, isConnected }) => {
  return (
    <div
      className="presence-indicator"
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        padding: '8px 12px',
        backgroundColor: '#0a0a0a',
        borderBottom: '1px solid #222',
        fontSize: '0.75rem',
        color: '#666'
      }}
    >
      <span
        style={{
          display: 'inline-block',
          width: '6px',
          height: '6px',
          borderRadius: '50%',
          backgroundColor: isConnected ? '#00ff00' : '#ff5555'
        }}
      />

      <span>
        {isConnected ? (
          <>
            <span style={{ color: '#00d4ff' }}>{count}</span>
            {' '}operative{count !== 1 ? 's' : ''} connected
          </>
        ) : (
          <span style={{ color: '#ff5555' }}>Disconnected</span>
        )}
      </span>
    </div>
  )
}
