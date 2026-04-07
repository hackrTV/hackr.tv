import React, { useRef, useEffect } from 'react'
import { useMobileDetect } from '~/hooks/useMobileDetect'

interface GameOutputProps {
  output: string[]
  onOutputClick?: () => void
}

export const GameOutput: React.FC<GameOutputProps> = ({ output, onOutputClick }) => {
  const outputRef = useRef<HTMLDivElement>(null)
  const { isMobile } = useMobileDetect()

  // Auto-scroll to bottom when new output is added
  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight
    }
  }, [output])

  return (
    <>
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
      id="game-output"
      onClick={onOutputClick}
      style={{
        cursor: onOutputClick ? 'text' : 'default',
        fontFamily: 'monospace',
        fontSize: isMobile ? '0.7em' : '0.75em',
        lineHeight: '1.2',
        whiteSpace: 'pre-wrap',
        wordBreak: 'break-word',
        overflowWrap: 'break-word',
        height: isMobile ? 'calc(100vh - 200px)' : '700px',
        minHeight: isMobile ? '300px' : '700px',
        maxHeight: isMobile ? '500px' : '700px',
        overflowY: 'auto',
        overflowX: 'hidden',
        padding: isMobile ? '8px' : '10px',
        background: '#0d0d0d',
        color: '#d0d0d0',
        border: '1px solid #4b5563',
        borderRadius: '3px',
        marginBottom: '8px'
      }}
    >
      {output.map((line, index) => (
        <div key={index} dangerouslySetInnerHTML={{ __html: line || '&nbsp;' }} />
      ))}
    </div>
    </>
  )
}
