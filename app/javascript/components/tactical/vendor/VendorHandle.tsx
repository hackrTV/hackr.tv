import React, { useState } from 'react'

interface VendorHandleProps {
  onClick: () => void
}

export const VendorHandle: React.FC<VendorHandleProps> = ({ onClick }) => {
  const [hover, setHover] = useState(false)

  return (
    <button
      onClick={(e) => { e.stopPropagation(); onClick() }}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        position: 'absolute',
        right: 0,
        top: '50%',
        transform: 'translateY(-50%)',
        zIndex: 25,
        background: hover ? '#1a1a1a' : '#111',
        border: '1px solid #fbbf24',
        borderRight: 'none',
        borderRadius: '6px 0 0 6px',
        padding: '12px 6px',
        cursor: 'pointer',
        writingMode: 'vertical-rl',
        textOrientation: 'mixed',
        fontFamily: '\'Courier New\', monospace',
        fontSize: '0.7em',
        fontWeight: 'bold',
        letterSpacing: '2px',
        color: '#fbbf24',
        transition: 'background 0.2s, box-shadow 0.2s',
        boxShadow: hover ? '0 0 10px rgba(251, 191, 36, 0.3)' : 'none'
      }}
    >
      VENDOR
    </button>
  )
}
