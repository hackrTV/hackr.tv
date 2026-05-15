import React from 'react'
import { BreachEncounter } from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'
import { TIER_COLORS } from './breachConstants'

interface BreachConfirmModalProps {
  encounter: BreachEncounter
  onConfirm: () => void
  onCancel: () => void
}

export const BreachConfirmModal: React.FC<BreachConfirmModalProps> = ({
  encounter, onConfirm, onCancel
}) => {
  const { executing } = useTactical()
  const tierColor = TIER_COLORS[encounter.tier_label.toLowerCase()] || '#9ca3af'

  return (
    <div
      style={{
        position: 'fixed', inset: 0, zIndex: 200,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: 'rgba(0,0,0,0.7)'
      }}
      onClick={onCancel}
    >
      <div
        style={{
          background: '#1a1a1a',
          border: '1px solid #22d3ee',
          borderRadius: '6px',
          padding: '24px 28px',
          maxWidth: '420px',
          fontFamily: '\'Courier New\', monospace'
        }}
        onClick={e => e.stopPropagation()}
      >
        <div style={{
          color: '#22d3ee',
          fontWeight: 'bold',
          fontSize: '1.1em',
          letterSpacing: '1px',
          marginBottom: '16px'
        }}>
          INITIATE BREACH
        </div>

        <div style={{ marginBottom: '8px' }}>
          <span style={{ color: '#d0d0d0', fontSize: '1.05em' }}>{encounter.name}</span>
          <span style={{ color: tierColor, marginLeft: '10px', fontSize: '0.9em' }}>
            {encounter.tier_label}
          </span>
        </div>

        {encounter.min_clearance > 0 && (
          <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '12px' }}>
            Clearance: {encounter.min_clearance}
          </div>
        )}

        <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '20px' }}>
          This will engage your DECK. Are you ready?
        </div>

        <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
          <button
            onClick={onCancel}
            style={{
              background: 'transparent',
              color: '#888',
              border: '1px solid #444',
              padding: '8px 20px',
              fontSize: '0.9em',
              cursor: 'pointer',
              borderRadius: '3px',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            CANCEL
          </button>
          <button
            onClick={onConfirm}
            disabled={executing}
            style={{
              background: executing ? '#333' : '#22d3ee',
              color: executing ? '#666' : '#0a0a0a',
              border: 'none',
              padding: '8px 20px',
              fontSize: '0.9em',
              cursor: executing ? 'not-allowed' : 'pointer',
              borderRadius: '3px',
              fontWeight: 'bold',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            BREACH
          </button>
        </div>
      </div>
    </div>
  )
}
