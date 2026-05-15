import React, { useState } from 'react'

interface TransitHandleProps {
  onClick: () => void
}

export const TransitHandle: React.FC<TransitHandleProps> = ({ onClick }) => {
  const [hover, setHover] = useState(false)

  return (
    <button
      onClick={(e) => { e.stopPropagation(); onClick() }}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        position: 'absolute',
        top: 0,
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 25,
        background: hover ? '#1a1a1a' : '#111',
        border: '1px solid #22d3ee',
        borderTop: 'none',
        borderRadius: '0 0 6px 6px',
        padding: '4px 16px',
        cursor: 'pointer',
        fontFamily: '\'Courier New\', monospace',
        fontSize: '0.7em',
        fontWeight: 'bold',
        letterSpacing: '2px',
        color: '#22d3ee',
        transition: 'background 0.2s, box-shadow 0.2s',
        boxShadow: hover ? '0 0 10px rgba(34, 211, 238, 0.3)' : 'none'
      }}
    >
      TRANSIT
    </button>
  )
}
