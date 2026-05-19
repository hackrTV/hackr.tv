import React from 'react'
import { Link } from 'react-router-dom'
import type { ScheduledStreamInfo } from '~/types/uplink'
import { useCountdown } from '~/hooks/useCountdown'
import { formatFutureDate } from '~/utils/dateUtils'

interface ScheduledStreamBannerProps {
  stream: ScheduledStreamInfo
}

export const ScheduledStreamBanner: React.FC<ScheduledStreamBannerProps> = ({
  stream
}) => {
  const countdown = useCountdown(stream.scheduled_at)

  // Expired — countdown returned empty
  if (!countdown) return null

  const isStartingSoon = countdown === 'STARTING SOON!'

  const formattedDate = formatFutureDate(stream.scheduled_at, true)

  return (
    <>
      <div style={{
        background: isStartingSoon
          ? 'linear-gradient(90deg, #0a1a2e 0%, #0d2847 50%, #0a1a2e 100%)'
          : 'linear-gradient(90deg, #0a1a2e 0%, #0d2340 50%, #0a1a2e 100%)',
        borderTop: '1px solid #06b6d4',
        borderBottom: '1px solid #06b6d4',
        padding: '20px 16px',
        textAlign: 'center',
        fontFamily: 'Terminus, \'Courier New\', monospace',
        fontSize: '18px',
        position: 'relative',
        overflow: 'hidden',
        contain: 'paint'
      }}>
        {isStartingSoon && (
          <div style={{
            position: 'absolute',
            top: 0,
            left: '-100%',
            width: '100%',
            height: '100%',
            background: 'linear-gradient(90deg, transparent, rgba(6, 182, 212, 0.15), transparent)',
            animation: 'scheduled-pulse 2s linear infinite'
          }} />
        )}
        <span style={{ position: 'relative', zIndex: 1 }}>
          {isStartingSoon ? (
            <>
              <span style={{ color: '#f59e0b', fontWeight: 'bold' }}>[ STARTING SOON ]</span>
              <span style={{ color: '#e0f2fe' }}>
                {' '}{stream.title}{stream.artist ? ` — ${stream.artist}` : ''}
              </span>
            </>
          ) : (
            <>
              <span style={{ color: '#06b6d4', fontWeight: 'bold' }}>NEXT STREAM:</span>
              <span style={{ color: '#e0f2fe' }}>
                {' '}{stream.title}
                {stream.artist ? ` — ${stream.artist} will be LIVE at ${formattedDate}` : ''}
              </span>
              <span style={{ color: '#67e8f9', marginLeft: '8px' }}>
                ({countdown})
              </span>
            </>
          )}
          <Link to="/schedule" style={{
            color: '#0891b2',
            marginLeft: '16px',
            fontSize: '13px',
            textDecoration: 'none'
          }}>
            [ SCHEDULE ]
          </Link>
        </span>
      </div>

      <style>{`
        @keyframes scheduled-pulse {
          0% { left: -100%; }
          100% { left: 100%; }
        }
      `}</style>
    </>
  )
}
