import React from 'react'
import type { ScheduledStreamInfo } from '~/types/uplink'

interface StartingSoonHeroProps {
  stream: ScheduledStreamInfo
}

export const StartingSoonHero: React.FC<StartingSoonHeroProps> = ({ stream }) => {
  return (
    <div style={{
      width: '100%',
      maxWidth: '1400px',
      margin: '0 auto',
      padding: '4px 20px 20px'
    }}>
      <div style={{
        background: 'linear-gradient(90deg, #0a1a2e 0%, #0d2847 50%, #0a1a2e 100%)',
        border: '2px solid #06b6d4',
        padding: '60px 20px',
        textAlign: 'center',
        position: 'relative',
        overflow: 'hidden',
        contain: 'paint'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: '-100%',
          width: '100%',
          height: '100%',
          background: 'linear-gradient(90deg, transparent, rgba(6, 182, 212, 0.1), transparent)',
          animation: 'starting-soon-pulse 3s linear infinite'
        }} />
        <div style={{ position: 'relative', zIndex: 1 }}>
          <p style={{
            color: '#06b6d4',
            fontSize: '2em',
            fontWeight: 'bold',
            letterSpacing: '0.15em',
            margin: '0 0 16px 0',
            textShadow: '0 0 20px rgba(6, 182, 212, 0.5)'
          }}>
            STREAM STARTING SOON
          </p>
          <p style={{ color: '#e0f2fe', fontSize: '1.3em', margin: '0 0 8px 0' }}>
            {stream.title}
          </p>
          {stream.artist && (
            <p style={{ color: '#888', fontSize: '1em', margin: 0 }}>
              {stream.artist}
            </p>
          )}
        </div>
      </div>
      <style>{`
        @keyframes starting-soon-pulse {
          0% { left: -100%; }
          100% { left: 100%; }
        }
      `}</style>
    </div>
  )
}
