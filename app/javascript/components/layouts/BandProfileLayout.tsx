import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

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
  colorScheme: ColorScheme
  filterName: string
  intro?: React.ReactNode
  albumSection?: React.ReactNode
  philosophySection?: React.ReactNode
}

const BandProfileLayout: React.FC<BandProfileLayoutProps> = ({
  artistName,
  colorScheme,
  filterName,
  intro,
  albumSection,
  philosophySection
}) => {
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
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
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

          <div>
            {intro}
            {albumSection}
            {philosophySection}

            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link to="/fm/bands" className="tui-button" style={backButtonStyle}>
                ← BACK TO BANDS
              </Link>
              <Link
                to={`/fm/pulse_vault?filter=${encodeURIComponent(filterName)}`}
                className="tui-button"
                style={buttonStyle}
              >
                LISTEN IN THE PULSE VAULT →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default BandProfileLayout
