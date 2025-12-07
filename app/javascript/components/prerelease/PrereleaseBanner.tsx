import React from 'react'
import { useAppSettings } from '~/contexts/AppSettingsContext'

// Height of the fixed menu bar (from tuicss.css .tui-nav)
const MENU_HEIGHT = 26
// Height of the banner (padding + font + borders)
const BANNER_HEIGHT = 35

export const PrereleaseBanner: React.FC = () => {
  const { settings, isPrereleaseMode, isLoading } = useAppSettings()

  // Don't show anything while loading or if not in prerelease mode
  if (isLoading || !isPrereleaseMode) {
    return null
  }

  const modeLabel = settings.prerelease_mode?.toUpperCase() || 'PRERELEASE'

  return (
    <>
      {/* Fixed banner - stays visible when scrolling */}
      <div style={{
        background: 'linear-gradient(90deg, #1a1a2e 0%, #16213e 50%, #1a1a2e 100%)',
        border: '1px solid #f59e0b',
        borderLeft: 'none',
        borderRight: 'none',
        padding: '8px 16px',
        textAlign: 'center',
        fontFamily: 'Terminus, \'Courier New\', monospace',
        fontSize: '15px',
        position: 'fixed',
        top: MENU_HEIGHT,
        left: 0,
        right: 0,
        zIndex: 8
      }}>
        <span style={{ color: '#f59e0b', fontWeight: 'bold', marginRight: '8px' }}>
          [{modeLabel}]
        </span>
        <span style={{ color: '#fbbf24' }}>
          {settings.prerelease_banner_text || `This application is in ${settings.prerelease_mode} mode.`}
        </span>
      </div>

      {/* Spacer - pushes page content below the fixed banner */}
      <div style={{ height: BANNER_HEIGHT }} />
    </>
  )
}
