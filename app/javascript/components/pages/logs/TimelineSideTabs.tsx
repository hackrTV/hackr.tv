import React from 'react'
import { useNavigate } from 'react-router-dom'
import { TIMELINE_ORDER, TIMELINE_CONFIG, formatEra } from './timelineConfig'
import type { TimelineSummary } from './timelineConfig'

interface TimelineSideTabsProps {
  currentTimeline: string
  currentSort?: string
  timelines: TimelineSummary
}

export const TimelineSideTabs: React.FC<TimelineSideTabsProps> = ({ currentTimeline, currentSort = 'desc', timelines }) => {
  const navigate = useNavigate()
  const timelineKeys = TIMELINE_ORDER.filter(tl => tl in timelines)

  return (
    <div style={{
      position: 'absolute',
      right: '100%',
      top: '0',
      display: 'flex',
      flexDirection: 'column',
      gap: '4px',
      marginRight: '-1px'
    }}>
      {timelineKeys.map(tl => {
        const tlConfig = TIMELINE_CONFIG[tl]
        const info = timelines[tl]
        const isActive = tl === currentTimeline
        const era = formatEra(info)
        return (
          <button
            key={tl}
            onClick={() => navigate(`/logs?timeline=${tl}&page=1&sort=${currentSort}`)}
            style={isActive ? {
              padding: '10px 14px',
              backgroundColor: '#1a1a1a',
              color: '#22d3ee',
              fontWeight: 'bold',
              fontFamily: 'inherit',
              fontSize: 'inherit',
              border: '1px solid #333',
              borderRight: '1px solid #1a1a1a',
              cursor: 'pointer',
              textAlign: 'right',
              whiteSpace: 'nowrap'
            } : {
              padding: '10px 14px',
              backgroundColor: '#111',
              color: '#555',
              fontFamily: 'inherit',
              fontSize: 'inherit',
              border: '1px solid #2a2a2a',
              borderRight: '1px solid #333',
              cursor: 'pointer',
              textAlign: 'right',
              whiteSpace: 'nowrap'
            }}
          >
            {tlConfig ? (
              <>
                <span style={{ fontSize: '1em' }}>{era}</span>
                <br />
                <span style={{ fontSize: '0.75em' }}>{tlConfig.name} ({info.count})</span>
              </>
            ) : (
              <span style={{ fontSize: '0.85em' }}>{tl} ({info.count})</span>
            )}
          </button>
        )
      })}
    </div>
  )
}
