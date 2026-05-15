import React, { useState } from 'react'
import { NpcMobStub } from '~/types/zoneMap'

interface NpcHandleProps {
  npc: NpcMobStub
  onClick: () => void
  offsetX: number
}

export const NpcHandle: React.FC<NpcHandleProps> = ({ npc, onClick, offsetX }) => {
  const [hover, setHover] = useState(false)

  return (
    <button
      title={npc.name}
      onClick={(e) => { e.stopPropagation(); onClick() }}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        position: 'absolute',
        bottom: 0,
        left: `calc(50% + ${offsetX}px)`,
        transform: 'translateX(-50%)',
        zIndex: 25,
        background: hover ? '#1a1a1a' : '#111',
        border: '1px solid #c084fc',
        borderBottom: 'none',
        borderRadius: '6px 6px 0 0',
        padding: '4px 12px',
        cursor: 'pointer',
        fontFamily: '\'Courier New\', monospace',
        fontSize: '0.65em',
        fontWeight: 'bold',
        letterSpacing: '1px',
        color: '#c084fc',
        transition: 'background 0.2s, box-shadow 0.2s',
        boxShadow: hover ? '0 0 10px rgba(192, 132, 252, 0.3)' : 'none',
        whiteSpace: 'nowrap'
      }}
    >
      {npc.name}
    </button>
  )
}
