import React, { useRef, useEffect } from 'react'

interface GameOutputProps {
  output: string[]
}

export const GameOutput: React.FC<GameOutputProps> = ({ output }) => {
  const outputRef = useRef<HTMLDivElement>(null)

  // Auto-scroll to bottom when new output is added
  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight
    }
  }, [output])

  return (
    <div
      ref={outputRef}
      id="game-output"
      style={{
        fontFamily: 'monospace',
        fontSize: '0.75em',
        lineHeight: '1.2',
        whiteSpace: 'pre-wrap',
        height: '700px',
        overflowY: 'auto',
        padding: '10px',
        background: '#0d0d0d',
        color: '#d0d0d0',
        border: '1px solid #4b5563',
        borderRadius: '3px',
        marginBottom: '8px'
      }}
    >
      {output.map((line, index) => (
        <div key={index} dangerouslySetInnerHTML={{ __html: line }} />
      ))}
    </div>
  )
}
