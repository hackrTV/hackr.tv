import React, { useState } from 'react'
import { BreachEncounter, DeckStatus } from '~/types/zoneMap'
import { TIER_COLORS } from './breachConstants'

interface BreachTargetButtonsProps {
  encounters: BreachEncounter[]
  deckStatus: DeckStatus
  onSelect: (encounter: BreachEncounter) => void
}

const BreachTargetButton: React.FC<{
  encounter: BreachEncounter
  disabled: boolean
  onSelect: (enc: BreachEncounter) => void
}> = ({ encounter: enc, disabled, onSelect }) => {
  const [hover, setHover] = useState(false)
  const tierColor = TIER_COLORS[enc.tier_label.toLowerCase()] || '#9ca3af'

  return (
    <div style={{ position: 'relative' }}>
      <button
        disabled={disabled}
        onClick={(e) => { e.stopPropagation(); onSelect(enc) }}
        onMouseEnter={(e) => {
          setHover(true)
          if (!disabled) {
            e.currentTarget.style.borderColor = '#22d3ee'
            e.currentTarget.style.boxShadow = '0 0 8px rgba(34, 211, 238, 0.3)'
          }
        }}
        onMouseLeave={(e) => {
          setHover(false)
          e.currentTarget.style.borderColor = disabled ? '#333' : '#22d3ee'
          e.currentTarget.style.boxShadow = 'none'
        }}
        style={{
          background: disabled ? '#1a1a1a' : '#111',
          border: `1px solid ${disabled ? '#333' : '#22d3ee'}`,
          borderRadius: '4px',
          padding: '6px 12px',
          cursor: disabled ? 'not-allowed' : 'pointer',
          opacity: disabled ? 0.5 : 1,
          textAlign: 'left',
          fontFamily: '\'Courier New\', monospace',
          transition: 'border-color 0.2s, box-shadow 0.2s',
          width: '100%'
        }}
      >
        <div style={{ fontSize: '0.7em', color: '#22d3ee', fontWeight: 'bold', letterSpacing: '1px', marginBottom: '2px' }}>
          BREACH TARGET
        </div>
        <div style={{ fontSize: '0.75em', color: '#d0d0d0' }}>{enc.name}</div>
        <div style={{ fontSize: '0.65em', color: tierColor }}>{enc.tier_label}</div>
      </button>
      {hover && !disabled && (
        <div style={{
          position: 'absolute', top: '50%', right: '100%', transform: 'translateY(-50%)',
          marginRight: '8px', background: '#1a1a1a', border: '1px solid #444',
          borderRadius: '4px', padding: '6px 10px', whiteSpace: 'nowrap', zIndex: 50,
          fontSize: '0.8em', color: '#22d3ee', fontWeight: 'bold',
          fontFamily: '\'Courier New\', monospace'
        }}>
          Initiate BREACH
        </div>
      )}
    </div>
  )
}

export const BreachTargetButtons: React.FC<BreachTargetButtonsProps> = ({
  encounters, deckStatus, onSelect
}) => {
  if (encounters.length === 0) return null

  const disabled = !deckStatus.equipped || deckStatus.fried
  const disabledReason = !deckStatus.equipped
    ? 'NO DECK EQUIPPED'
    : deckStatus.fried ? 'DECK FRIED' : null

  return (
    <div style={{
      position: 'absolute',
      top: 40,
      right: 12,
      zIndex: 20,
      display: 'flex',
      flexDirection: 'column',
      gap: '6px',
      maxWidth: '220px'
    }}>
      {disabledReason && (
        <div style={{
          fontSize: '0.65em',
          color: '#f87171',
          textAlign: 'right',
          padding: '0 4px'
        }}>
          {disabledReason}
        </div>
      )}
      {encounters.map(enc => (
        <BreachTargetButton key={enc.id} encounter={enc} disabled={disabled} onSelect={onSelect} />
      ))}
    </div>
  )
}
