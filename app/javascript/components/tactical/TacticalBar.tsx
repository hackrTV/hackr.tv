import React from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useNavigate } from 'react-router-dom'

interface TacticalBarProps {
  connectionStatus: 'connected' | 'connecting' | 'reconnecting' | 'disconnected'
}

export const TacticalBar: React.FC<TacticalBarProps> = ({ connectionStatus }) => {
  const { hackr, disconnect } = useGridAuth()
  const navigate = useNavigate()

  const handleDisconnect = async () => {
    if (confirm('Disconnect from THE PULSE GRID?')) {
      await disconnect()
      navigate('/grid/login')
    }
  }

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      padding: '0 12px',
      height: '100%',
      borderBottom: '1px solid #333',
      background: '#111'
    }}>
      <div style={{ fontSize: '0.85em', display: 'flex', alignItems: 'center', gap: '12px' }}>
        <span style={{ color: '#a78bfa', fontWeight: 'bold', letterSpacing: '1px' }}>TACTICAL</span>
        <span style={{ color: '#333' }}>|</span>
        <span style={{ color: '#e0e0e0' }}>{hackr?.hackr_alias}</span>
        <span style={{ color: '#333' }}>|</span>
        <span style={{
          color: connectionStatus === 'connected' ? '#34d399'
            : connectionStatus === 'reconnecting' ? '#fbbf24' : '#f87171',
          fontSize: '0.8em'
        }}>
          {connectionStatus === 'connected' ? 'LIVE'
            : connectionStatus === 'reconnecting' ? 'RECONNECTING'
              : connectionStatus === 'connecting' ? 'CONNECTING' : 'OFFLINE'}
        </span>
        {hackr?.role === 'admin' && (
          <a href="/root" style={{ color: '#f87171', fontSize: '0.85em', textDecoration: 'none' }}>[ADMIN]</a>
        )}
      </div>
      <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
        <a href="/grid" style={{
          color: '#666',
          fontSize: '0.8em',
          textDecoration: 'none'
        }}>
          STANDARD VIEW
        </a>
        <button
          onClick={handleDisconnect}
          style={{
            background: '#dc2626',
            color: 'white',
            border: 'none',
            padding: '4px 12px',
            fontSize: '0.8em',
            cursor: 'pointer',
            borderRadius: '3px'
          }}
        >
          KILLSWITCH
        </button>
      </div>
    </div>
  )
}
