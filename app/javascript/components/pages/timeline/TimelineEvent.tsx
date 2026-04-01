import React, { useState } from 'react'
import { Link } from 'react-router-dom'
import type { TimelineEvent as TimelineEventType, EraColors } from './timelineData'

interface TimelineEventProps {
  event: TimelineEventType
  colors: EraColors
}

export const TimelineEvent: React.FC<TimelineEventProps> = ({ event, colors }) => {
  const [hovered, setHovered] = useState(false)
  const isIntercepted = event.isIntercepted

  return (
    <div
      style={{
        position: 'relative',
        paddingLeft: '32px',
        paddingBottom: '28px',
        marginLeft: '1px'
      }}
    >
      {/* Dot on the spine */}
      <div
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        style={{
          position: 'absolute',
          left: '-6px',
          top: '4px',
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          backgroundColor: isIntercepted ? '#ef4444' : colors.primary,
          border: `2px solid ${isIntercepted ? '#991b1b' : colors.border}`,
          boxShadow: hovered ? `0 0 12px ${isIntercepted ? '#ef4444' : colors.primary}` : 'none',
          transition: 'box-shadow 0.2s ease, transform 0.2s ease',
          transform: hovered ? 'scale(1.3)' : 'scale(1)',
          zIndex: 2
        }}
      />

      {/* Event card */}
      <div
        style={{
          position: 'relative',
          padding: '12px 16px',
          backgroundColor: isIntercepted ? '#1a1212' : 'transparent',
          borderLeft: isIntercepted ? '2px solid #991b1b' : 'none',
          overflow: 'hidden'
        }}
      >
        {/* CLASSIFIED watermark for intercepted files */}
        {isIntercepted && (
          <div style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%) rotate(-25deg)',
            fontSize: '42px',
            fontWeight: 'bold',
            color: '#ef4444',
            opacity: 0.04,
            letterSpacing: '8px',
            whiteSpace: 'nowrap',
            pointerEvents: 'none',
            userSelect: 'none'
          }}>
            CLASSIFIED
          </div>
        )}

        {/* Intercepted badge */}
        {isIntercepted && (
          <span style={{
            display: 'inline-block',
            fontSize: '0.65em',
            fontWeight: 'bold',
            color: '#ef4444',
            backgroundColor: '#2a1515',
            padding: '2px 6px',
            marginBottom: '4px',
            letterSpacing: '1px',
            border: '1px solid #991b1b'
          }}>
            INTERCEPTED
          </span>
        )}

        {/* Date */}
        <div style={{
          fontSize: '0.8em',
          color: isIntercepted ? '#ef4444' : colors.primary,
          marginBottom: '2px',
          fontFamily: 'monospace',
          letterSpacing: '0.5px'
        }}>
          {event.date}
        </div>

        {/* Title */}
        <div style={{
          fontSize: '1.05em',
          fontWeight: 'bold',
          color: '#e5e7eb',
          marginBottom: event.description ? '4px' : '0'
        }}>
          {event.title}
        </div>

        {/* Description */}
        {event.description && (
          <div style={{
            fontSize: '0.85em',
            color: '#9ca3af',
            lineHeight: '1.45'
          }}>
            {event.description}
          </div>
        )}

        {/* Links */}
        {(event.logSlug || event.codexSlug) && (
          <div style={{ marginTop: '6px', display: 'flex', gap: '12px' }}>
            {event.logSlug && (
              <Link
                to={`/logs/${event.logSlug}`}
                style={{
                  fontSize: '0.78em',
                  color: colors.primary,
                  textDecoration: 'none',
                  opacity: 0.8
                }}
                onMouseEnter={e => { e.currentTarget.style.opacity = '1' }}
                onMouseLeave={e => { e.currentTarget.style.opacity = '0.8' }}
              >
                Read Log &rarr;
              </Link>
            )}
            {event.codexSlug && (
              <Link
                to={`/codex/${event.codexSlug}`}
                style={{
                  fontSize: '0.78em',
                  color: '#f59e0b',
                  textDecoration: 'none',
                  opacity: 0.8
                }}
                onMouseEnter={e => { e.currentTarget.style.opacity = '1' }}
                onMouseLeave={e => { e.currentTarget.style.opacity = '0.8' }}
              >
                View in Codex &rarr;
              </Link>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
