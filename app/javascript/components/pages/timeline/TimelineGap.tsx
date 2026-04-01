import React, { useState, useEffect } from 'react'

const GAP_FRAGMENTS = [
  'The Trade...',
  'The Efficiency...',
  'The Forgetting...',
  '82 years of managed silence.',
  'No one was listening.'
]

interface TimelineGapProps {
  isMobile: boolean
}

export const TimelineGap: React.FC<TimelineGapProps> = ({ isMobile }) => {
  const [visibleIndex, setVisibleIndex] = useState(0)
  const [opacity, setOpacity] = useState(0)

  useEffect(() => {
    let fadeTimeout: ReturnType<typeof setTimeout>

    const cycle = () => {
      setOpacity(1)
      fadeTimeout = setTimeout(() => {
        setOpacity(0)
        fadeTimeout = setTimeout(() => {
          setVisibleIndex(i => (i + 1) % GAP_FRAGMENTS.length)
          cycle()
        }, 1200)
      }, 2800)
    }

    cycle()
    return () => clearTimeout(fadeTimeout)
  }, [])

  return (
    <div style={{
      position: 'relative',
      height: isMobile ? '250px' : '380px',
      background: 'radial-gradient(ellipse at center, #111118 0%, #08080c 60%, #050507 100%)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      overflow: 'hidden',
      margin: '0 0 0 0'
    }}>
      {/* Fading dashed spine */}
      <div style={{
        position: 'absolute',
        left: isMobile ? '17px' : '25px',
        top: 0,
        bottom: 0,
        width: '2px',
        background: 'repeating-linear-gradient(to bottom, #374151 0px, #374151 4px, transparent 4px, transparent 12px)',
        opacity: 0.3
      }} />

      {/* Animated text fragments */}
      <div style={{
        position: 'relative',
        zIndex: 1,
        textAlign: 'center',
        padding: '0 20px'
      }}>
        <p style={{
          color: '#4b5563',
          fontSize: isMobile ? '0.9em' : '1.05em',
          fontStyle: 'italic',
          letterSpacing: '1px',
          opacity,
          transition: 'opacity 1.2s ease',
          margin: '0 0 40px 0'
        }}>
          {GAP_FRAGMENTS[visibleIndex]}
        </p>
      </div>

      {/* Chen's PRISM — the sole anchor */}
      <div style={{
        position: 'relative',
        zIndex: 1,
        textAlign: 'center',
        padding: '16px 24px',
        borderTop: '1px solid #1f2937',
        borderBottom: '1px solid #1f2937'
      }}>
        {/* Dot */}
        <div style={{
          width: '8px',
          height: '8px',
          borderRadius: '50%',
          backgroundColor: '#9ca3af',
          margin: '0 auto 10px auto',
          boxShadow: '0 0 8px rgba(156, 163, 175, 0.3)'
        }} />
        <div style={{
          fontSize: '0.75em',
          color: '#6b7280',
          fontFamily: 'monospace',
          letterSpacing: '1px',
          marginBottom: '4px'
        }}>
          2048
        </div>
        <div style={{
          fontSize: '0.85em',
          color: '#9ca3af',
          fontWeight: 'bold'
        }}>
          PRISM Discovered
        </div>
        <div style={{
          fontSize: '0.75em',
          color: '#4b5563',
          marginTop: '2px'
        }}>
          Dr. Marcus Chen discovers that perception operates on manipulable quantum states.
        </div>
      </div>
    </div>
  )
}
