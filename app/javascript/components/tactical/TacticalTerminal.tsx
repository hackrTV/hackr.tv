import React, { useRef, useEffect, useCallback } from 'react'
import { CommandInput } from '~/components/grid/CommandInput'
import { useTactical } from './TacticalContext'
import { sanitizeHtml } from '~/utils/sanitizeHtml'

export const TacticalTerminal: React.FC = () => {
  const { output, executing, sendCommand, commandInputRef } = useTactical()
  const outputRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight
    }
  }, [output])

  const handleOutputClick = useCallback(() => {
    commandInputRef.current?.focus()
  }, [commandInputRef])

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', overflow: 'hidden' }}>
      <style>{`
        @keyframes rainbow-cycle {
          0%   { color: #ff6b6b; }
          17%  { color: #fbbf24; }
          33%  { color: #34d399; }
          50%  { color: #22d3ee; }
          67%  { color: #60a5fa; }
          83%  { color: #a78bfa; }
          100% { color: #ff6b6b; }
        }
        .rarity-unicorn {
          animation: rainbow-cycle 3s linear infinite;
          font-weight: bold;
        }
      `}</style>
      <div
        ref={outputRef}
        onClick={handleOutputClick}
        style={{
          cursor: 'text',
          fontFamily: 'monospace',
          fontSize: '0.75em',
          lineHeight: '1.2',
          whiteSpace: 'pre-wrap',
          wordBreak: 'break-word',
          overflowWrap: 'break-word',
          flex: 1,
          minHeight: 0,
          overflowY: 'auto',
          overflowX: 'hidden',
          padding: '8px',
          background: '#0d0d0d',
          color: '#d0d0d0',
          border: '1px solid #333',
          borderRadius: '3px'
        }}
      >
        {output.map((line, index) => (
          <div key={index} dangerouslySetInnerHTML={{ __html: sanitizeHtml(line || '&nbsp;') }} />
        ))}
      </div>
      <div style={{ padding: '6px 0 0 0', flexShrink: 0 }}>
        <CommandInput ref={commandInputRef} onSubmit={sendCommand} disabled={executing} />
      </div>
    </div>
  )
}
