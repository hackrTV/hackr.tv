import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'

interface ColorScheme {
  primary: string
  border?: string
  legend?: string
  legend_style?: string
  background?: string
  background_gradient?: string
  button?: string
  button_gradient?: string
  button_text?: string
  back_button?: string
  back_border?: string
}

interface BandProfileLayoutProps {
  artistName: string
  artistSlug?: string
  colorScheme: ColorScheme
  filterName: string
  intro?: React.ReactNode
  releaseSection?: React.ReactNode
  philosophySection?: React.ReactNode
}

const BandProfileLayout: React.FC<BandProfileLayoutProps> = ({
  artistName,
  artistSlug,
  colorScheme,
  filterName,
  intro,
  releaseSection,
  philosophySection
}) => {
  const { isMobile } = useMobileDetect()
  const borderColor = colorScheme.border || colorScheme.primary
  const legendColor = colorScheme.legend || colorScheme.primary

  const backgroundStyle = colorScheme.background_gradient
    ? { background: colorScheme.background_gradient }
    : { background: colorScheme.background || '#0a0a0a' }

  const buttonStyle = colorScheme.button_gradient
    ? {
      background: colorScheme.button_gradient,
      color: 'white',
      fontWeight: 'bold' as const,
      border: 'none'
    }
    : {
      background: colorScheme.button || colorScheme.primary,
      color: colorScheme.button_text || 'white',
      fontWeight: 'bold' as const
    }

  const backButtonStyle = {
    background: colorScheme.back_button || '#222',
    color: '#888',
    border: `1px solid ${colorScheme.back_border || '#444'}`
  }

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text band-profile-container"
        style={{
          maxWidth: isMobile ? '100%' : '1200px',
          margin: '0 auto',
          display: 'block',
          ...backgroundStyle,
          border: `2px solid ${borderColor}`
        }}
      >
        <fieldset style={{ borderColor: borderColor }}>
          <legend
            className="center"
            style={{
              color: legendColor,
              ...(colorScheme.legend_style ? { fontStyle: colorScheme.legend_style } : {})
            }}
          >
            {artistName.toUpperCase()}
          </legend>

          <div className="band-profile-content">
            {intro}
            {releaseSection}
            {philosophySection}

            <div style={{
              display: 'flex',
              flexDirection: isMobile ? 'column' : 'row',
              gap: isMobile ? '10px' : '15px',
              marginTop: '30px'
            }}>
              <Link to="/fm/bands" className="tui-button" style={{ ...backButtonStyle, textAlign: 'center' }}>
                ← BACK TO BANDS
              </Link>
              {artistSlug && (
                <Link
                  to={`/${artistSlug}/releases`}
                  className="tui-button"
                  style={{ ...buttonStyle, textAlign: 'center' }}
                >
                  RELEASES
                </Link>
              )}
              <Link
                to={`/fm/pulse-vault?filter=${encodeURIComponent(filterName)}`}
                className="tui-button"
                style={{ ...buttonStyle, textAlign: 'center' }}
              >
                {isMobile ? 'PULSE VAULT →' : 'LISTEN IN THE PULSE VAULT →'}
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default BandProfileLayout
