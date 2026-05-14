import React, { useEffect, useState } from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useNavigate } from 'react-router-dom'
import { apiJson } from '~/utils/apiClient'

interface TacticalBarProps {
  connectionStatus: 'connected' | 'connecting' | 'reconnecting' | 'disconnected'
  refreshToken: number
}

interface LoadoutData {
  clearance: number
  vitals: {
    health: { current: number; max: number }
    energy: { current: number; max: number }
    psyche: { current: number; max: number }
  }
}

const CompactVital: React.FC<{ label: string; current: number; max: number; color: string }> = ({
  label, current, max, color
}) => {
  const pct = max > 0 ? Math.round((current / max) * 100) : 0
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
      <span style={{ color, fontSize: '0.7em', fontWeight: 'bold', width: '18px' }}>{label}</span>
      <div style={{
        background: '#1a1a1a', borderRadius: '2px', height: '6px', width: '60px',
        border: '1px solid #333', overflow: 'hidden'
      }}>
        <div style={{
          width: `${pct}%`, height: '100%', borderRadius: '2px',
          background: color, transition: 'width 0.3s'
        }} />
      </div>
      <span style={{ color: '#999', fontSize: '0.65em', minWidth: '36px' }}>{current}/{max}</span>
    </div>
  )
}

export const TacticalBar: React.FC<TacticalBarProps> = ({ connectionStatus, refreshToken }) => {
  const { hackr, disconnect } = useGridAuth()
  const navigate = useNavigate()
  const [vitals, setVitals] = useState<LoadoutData['vitals'] | null>(null)
  const [clearance, setClearance] = useState<number | null>(null)
  const [clHover, setClHover] = useState(false)

  useEffect(() => {
    apiJson<LoadoutData>('/api/grid/loadout').then(d => { setVitals(d.vitals); setClearance(d.clearance) }).catch(console.error)
  }, [refreshToken])

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
        {clearance != null && (
          <span
            style={{ color: '#fbbf24', fontSize: '0.8em', position: 'relative', cursor: 'default' }}
            onMouseEnter={() => setClHover(true)}
            onMouseLeave={() => setClHover(false)}
          >
            CL{clearance}
            {clHover && (
              <div style={{
                position: 'absolute', top: '100%', left: 0, marginTop: '6px',
                background: '#1a1a1a', border: '1px solid #444', borderRadius: '4px',
                padding: '6px 10px', whiteSpace: 'nowrap', zIndex: 50,
                fontSize: '1em', color: '#d0d0d0',
                fontFamily: '\'Courier New\', monospace'
              }}>
                <span style={{ color: '#fbbf24' }}>CLEARANCE:</span> {clearance}
              </div>
            )}
          </span>
        )}
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

      {vitals && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <CompactVital label="HP" current={vitals.health.current} max={vitals.health.max} color={vitals.health.current <= 30 ? '#f87171' : '#34d399'} />
          <CompactVital label="EN" current={vitals.energy.current} max={vitals.energy.max} color="#fbbf24" />
          <CompactVital label="PS" current={vitals.psyche.current} max={vitals.psyche.max} color="#a78bfa" />
        </div>
      )}

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
