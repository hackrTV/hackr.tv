import React from 'react'
import { ERA_CONFIGS } from './timelineData'
import type { EraKey } from './timelineData'

interface TimelineNavProps {
  activeEra: EraKey
  onEraClick: (key: EraKey) => void
  isMobile: boolean
}

export const TimelineNav: React.FC<TimelineNavProps> = ({ activeEra, onEraClick, isMobile }) => {
  if (isMobile) {
    return (
      <div style={{
        position: 'sticky',
        top: 0,
        zIndex: 10,
        backgroundColor: '#0a0a0a',
        borderBottom: '1px solid #1f2937',
        display: 'flex',
        overflowX: 'auto',
        gap: '2px',
        padding: '4px',
        WebkitOverflowScrolling: 'touch',
        scrollbarWidth: 'none'
      }}>
        {ERA_CONFIGS.map(era => {
          const isActive = era.key === activeEra
          return (
            <button
              key={era.key}
              onClick={() => onEraClick(era.key)}
              style={{
                flex: '0 0 auto',
                padding: '8px 12px',
                backgroundColor: isActive ? era.colors.background : 'transparent',
                color: isActive ? era.colors.primary : '#4b5563',
                border: isActive ? `1px solid ${era.colors.border}` : '1px solid transparent',
                borderRadius: '3px',
                cursor: 'pointer',
                fontFamily: 'inherit',
                fontSize: '0.7em',
                fontWeight: isActive ? 'bold' : 'normal',
                whiteSpace: 'nowrap',
                letterSpacing: '0.5px',
                transition: 'color 0.2s ease, border-color 0.2s ease'
              }}
            >
              {era.name}
            </button>
          )
        })}
      </div>
    )
  }

  // Desktop: side tabs anchored to left edge of content
  return (
    <nav style={{
      position: 'fixed',
      top: '50%',
      transform: 'translateY(-50%)',
      zIndex: 10,
      display: 'flex',
      flexDirection: 'column',
      gap: '4px',
      right: `calc(50% + 400px + 10px)`
    }}>
      {ERA_CONFIGS.map(era => {
        const isActive = era.key === activeEra
        return (
          <button
            key={era.key}
            onClick={() => onEraClick(era.key)}
            style={{
              padding: '8px 14px',
              backgroundColor: isActive ? '#1a1a1a' : 'transparent',
              color: isActive ? era.colors.primary : '#4b5563',
              border: isActive ? `1px solid ${era.colors.border}` : '1px solid transparent',
              borderRadius: '3px',
              cursor: 'pointer',
              fontFamily: 'inherit',
              fontSize: '0.72em',
              fontWeight: isActive ? 'bold' : 'normal',
              textAlign: 'left',
              whiteSpace: 'nowrap',
              letterSpacing: '0.5px',
              transition: 'color 0.2s ease, background-color 0.2s ease, border-color 0.2s ease'
            }}
          >
            <span style={{ display: 'block', fontSize: '0.85em', color: isActive ? era.colors.text : '#374151' }}>
              {era.yearRange}
            </span>
            {era.name}
          </button>
        )
      })}
    </nav>
  )
}
