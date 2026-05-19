import React from 'react'
import { Link } from 'react-router-dom'
import type { StreamInfo } from '~/types/uplink'

const MENU_HEIGHT = 26 // matches .tui-nav height in tuicss
const BANNER_HEIGHT = 70

interface LiveNowBannerProps {
  stream: StreamInfo
  topOffset?: number
}

export const LiveNowBanner: React.FC<LiveNowBannerProps> = ({
  stream,
  topOffset = 0
}) => {
  return (
    <>
      <div style={{
        background: 'linear-gradient(90deg, #001a00 0%, #003300 50%, #001a00 100%)',
        borderTop: '1px solid #00ff00',
        borderBottom: '1px solid #00ff00',
        padding: '20px 16px',
        textAlign: 'center',
        fontFamily: 'Terminus, \'Courier New\', monospace',
        fontSize: '18px',
        position: 'fixed',
        top: MENU_HEIGHT + topOffset,
        left: 0,
        right: 0,
        zIndex: 8,
        overflow: 'hidden',
        contain: 'paint'
      }}>
        <div style={{
          position: 'absolute',
          top: 0,
          left: '-100%',
          width: '100%',
          height: '100%',
          background: 'linear-gradient(90deg, transparent, rgba(0, 255, 0, 0.15), transparent)',
          animation: 'live-pulse 3s linear infinite'
        }} />
        <span style={{ position: 'relative', zIndex: 1 }}>
          <span style={{ color: '#00ff00', fontWeight: 'bold', textShadow: '0 0 10px #00ff00' }}>
            [ LIVE NOW ]
          </span>
          <span style={{ color: '#e0ffe0' }}>
            {' '}{stream.title}{stream.artist ? ` — ${stream.artist}` : ''}
          </span>
          <Link to="/" style={{
            color: '#00cc00',
            marginLeft: '16px',
            fontSize: '14px',
            textDecoration: 'none',
            fontWeight: 'bold'
          }}>
            WATCH LIVE →
          </Link>
        </span>
      </div>

      {/* Spacer */}
      <div style={{ height: BANNER_HEIGHT }} />

      <style>{`
        @keyframes live-pulse {
          0% { left: -100%; }
          100% { left: 100%; }
        }
      `}</style>
    </>
  )
}
