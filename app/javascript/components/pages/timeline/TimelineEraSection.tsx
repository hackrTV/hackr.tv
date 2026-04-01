import React, { forwardRef, useState, useEffect } from 'react'
import type { EraConfig, TimelineEvent as TimelineEventType } from './timelineData'
import { TimelineEvent } from './TimelineEvent'

interface TimelineEraSectionProps {
  era: EraConfig
  events: TimelineEventType[]
  isMobile: boolean
}

// Atmospheric text fragments for The Trade era
const TRADE_FRAGMENTS = [
  'Convenience won every argument against freedom.',
  'Surveillance capitalism became so embedded that resistance sounded quaint.',
  'Nobody remembers when it started mattering.',
  'The consolidation years.',
  'The forgetting.'
]

const TradeAtmosphere: React.FC = () => {
  const [visibleIndex, setVisibleIndex] = useState(0)
  const [opacity, setOpacity] = useState(0)

  useEffect(() => {
    let fadeTimeout: ReturnType<typeof setTimeout>

    const cycle = () => {
      setOpacity(1)
      fadeTimeout = setTimeout(() => {
        setOpacity(0)
        fadeTimeout = setTimeout(() => {
          setVisibleIndex(i => (i + 1) % TRADE_FRAGMENTS.length)
          cycle()
        }, 1500)
      }, 3500)
    }

    cycle()
    return () => clearTimeout(fadeTimeout)
  }, [])

  return (
    <div style={{
      position: 'relative',
      height: '120px',
      textAlign: 'center'
    }}>
      <p style={{
        position: 'absolute',
        top: '50%',
        left: '50%',
        transform: 'translate(-50%, -50%)',
        width: '100%',
        maxWidth: '500px',
        padding: '0 20px',
        margin: 0,
        color: '#6b7280',
        fontSize: '1em',
        fontStyle: 'italic',
        lineHeight: '1.6',
        opacity,
        transition: 'opacity 1.5s ease'
      }}>
        {TRADE_FRAGMENTS[visibleIndex]}
      </p>
    </div>
  )
}

export const TimelineEraSection = forwardRef<HTMLDivElement, TimelineEraSectionProps>(
  ({ era, events, isMobile }, ref) => {
    const isTrade = era.key === 'the_trade'
    const isEfficiency = era.key === 'the_efficiency'

    return (
      <div
        ref={ref}
        id={era.key}
        style={{
          paddingTop: '40px',
          paddingBottom: '20px',
          position: 'relative'
        }}
      >
        {/* Era header */}
        <div style={{
          padding: isMobile ? '20px 16px' : '28px 24px',
          marginBottom: '24px',
          background: `linear-gradient(135deg, ${era.colors.background} 0%, #0a0a0a 100%)`,
          borderLeft: `3px solid ${era.colors.border}`,
          borderRadius: '0 4px 4px 0'
        }}>
          <div style={{
            fontSize: isMobile ? '0.7em' : '0.75em',
            color: era.colors.primary,
            letterSpacing: '2px',
            marginBottom: '4px',
            fontFamily: 'monospace'
          }}>
            {era.yearRange}
          </div>
          <h2 style={{
            margin: '0 0 6px 0',
            fontSize: isMobile ? '1.3em' : '1.6em',
            color: era.colors.text,
            fontWeight: 'bold',
            letterSpacing: '1px'
          }}>
            {era.name}
          </h2>
          <div style={{
            fontSize: '0.85em',
            color: '#6b7280',
            fontStyle: 'italic'
          }}>
            {era.subtitle}
          </div>
        </div>

        {/* Trade era: atmospheric only */}
        {isTrade && <TradeAtmosphere />}

        {/* Efficiency era: sparse atmospheric note */}
        {isEfficiency && (
          <div style={{
            padding: '20px 24px 10px',
            color: '#4b5563',
            fontSize: '0.85em',
            fontStyle: 'italic',
            lineHeight: '1.6',
            maxWidth: '500px'
          }}>
            Little is known about how this era unfolded. The historical record is fragmented
            {' \u2014 '}decades compressed into silence. What survived are traces: corporate memos,
            policy language, and one name that keeps surfacing.
          </div>
        )}

        {/* Events with spine */}
        {!isTrade && events.length > 0 && (
          <div style={{
            marginLeft: isMobile ? '16px' : '24px',
            borderLeft: `2px solid ${era.colors.border}`,
            paddingLeft: '0'
          }}>
            {events.map((event, i) => (
              <TimelineEvent key={i} event={event} colors={era.colors} />
            ))}
          </div>
        )}
      </div>
    )
  }
)

TimelineEraSection.displayName = 'TimelineEraSection'
