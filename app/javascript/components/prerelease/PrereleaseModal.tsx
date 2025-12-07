import React from 'react'
import { Link } from 'react-router-dom'
import { useAppSettings } from '~/contexts/AppSettingsContext'

export const PrereleaseModal: React.FC = () => {
  const { settings, isPrereleaseMode, isLoading } = useAppSettings()

  // Don't show anything while loading or if not in prerelease mode
  if (isLoading || !isPrereleaseMode) {
    return null
  }

  const modeLabel = settings.prerelease_mode?.toUpperCase() || 'PRERELEASE'

  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      backgroundColor: 'rgba(0, 0, 0, 0.85)',
      backdropFilter: 'blur(4px)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 9999,
      padding: '20px'
    }}>
      <div style={{
        background: '#0a0a0a',
        border: '2px solid #f59e0b',
        borderRadius: '4px',
        padding: '30px 40px',
        maxWidth: '500px',
        width: '100%',
        textAlign: 'center',
        fontFamily: 'Terminus, \'Courier New\', monospace',
        boxShadow: '0 0 30px rgba(245, 158, 11, 0.3)'
      }}>
        <div style={{
          fontSize: '24px',
          fontWeight: 'bold',
          color: '#f59e0b',
          marginBottom: '20px',
          letterSpacing: '0.1em'
        }}>
          [{modeLabel} MODE]
        </div>

        <div style={{
          color: '#fbbf24',
          fontSize: '16px',
          lineHeight: '1.6',
          marginBottom: '25px'
        }}>
          {settings.prerelease_banner_text || `Registration is temporarily disabled during the ${settings.prerelease_mode} phase.`}
        </div>

        <div style={{
          color: '#a3a3a3',
          fontSize: '14px',
          marginBottom: '25px',
          lineHeight: '1.5'
        }}>
          If you already have an account, you can still log in and access all features.
        </div>

        <div style={{ display: 'flex', gap: '15px', justifyContent: 'center', flexWrap: 'wrap' }}>
          <Link
            to="/grid/login"
            className="tui-button green-168"
            style={{ padding: '10px 25px', fontSize: '14px' }}
          >
            LOG IN
          </Link>
          <Link
            to="/"
            className="tui-button purple-168"
            style={{ padding: '10px 25px', fontSize: '14px' }}
          >
            GO HOME
          </Link>
        </div>
      </div>
    </div>
  )
}
