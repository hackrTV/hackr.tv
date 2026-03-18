import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

const colorScheme = {
  primary: '#8B00FF',
  secondary: '#6B00CC',
  glow: 'rgba(139, 0, 255, 0.6)',
  glowStrong: 'rgba(139, 0, 255, 0.8)',
  background: '#0a0a0a'
}

export const XeraenLandingPage: React.FC = () => {
  const { isMobile } = useMobileDetect()

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: isMobile ? '100%' : '1000px',
          margin: '0 auto',
          display: 'block',
          background: colorScheme.background,
          border: `2px solid ${colorScheme.primary}`,
          boxShadow: isMobile ? 'none' : `0 0 30px ${colorScheme.glow}`
        }}
      >
        <fieldset style={{ borderColor: colorScheme.primary }}>
          <legend
            className="center"
            style={{
              color: colorScheme.primary,
              textShadow: `0 0 15px ${colorScheme.glowStrong}`,
              letterSpacing: isMobile ? '1px' : '3px'
            }}
          >
            XERAEN
          </legend>

          <div style={{ padding: isMobile ? '15px' : '30px' }}>
            {/* Header */}
            <h2 style={{
              textAlign: 'center',
              marginBottom: '5px',
              color: colorScheme.primary,
              fontSize: isMobile ? '1.3em' : '1.8em',
              textShadow: `0 0 15px ${colorScheme.glowStrong}`,
              letterSpacing: '3px'
            }}>
              [:: XERAEN ::]
            </h2>
            <p style={{ textAlign: 'center', color: '#666', marginBottom: '30px', fontSize: '0.9em' }}>
              OMNIWAVE GENESIS VECTOR
            </p>

            {/* Lore narrative */}
            <div style={{
              marginBottom: '30px',
              padding: isMobile ? '15px' : '20px',
              background: 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
              border: `1px solid ${colorScheme.primary}`,
              lineHeight: '1.8'
            }}>
              <p style={{ color: '#ccc', marginBottom: '15px' }}>
                Systems architect turned fugitive. Founder of the Fracture Network. The voice behind
                The.CyberPul.se. <span style={{ color: colorScheme.primary, textShadow: `0 0 8px ${colorScheme.glow}` }}>Transmitting from {futureYear} — for as long as {futureYear} exists</span>.
              </p>
              <p style={{ color: '#aaa', marginBottom: '15px' }}>
                The music has evolved from hardcore fury into something he calls OMNIWAVE — electronic
                exploration where rhythmic guitars weave through synthesized frequencies and genre boundaries
                dissolve. The sound changed. What it carries hasn't.
              </p>
              <p style={{ color: '#888' }}>
                If you're hearing this, the signal is still reaching you. That's what matters.
              </p>
            </div>

            {/* Navigation cards */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: isMobile ? '1fr' : 'repeat(3, 1fr)',
              gap: isMobile ? '15px' : '20px',
              marginBottom: '30px'
            }}>
              {/* Bio */}
              <Link to="/xeraen/bio" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: `1px solid ${colorScheme.primary}`, cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: colorScheme.primary, height: '100%' }}>
                    <legend style={{ color: colorScheme.primary }}>BIO</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: colorScheme.primary, fontSize: '1.4em', marginBottom: '10px', textAlign: 'center', textShadow: `0 0 8px ${colorScheme.glow}` }}>
                        ◈ BIO
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        The story behind the signal. How a systems architect broke time open and what he lost doing it.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* Releases */}
              <Link to="/xeraen/releases" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: `1px solid ${colorScheme.secondary}`, cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: colorScheme.secondary, height: '100%' }}>
                    <legend style={{ color: colorScheme.secondary }}>RELEASES</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: colorScheme.secondary, fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ◆ RELEASES
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Every transmission committed to record. Hardcore fury to OMNIWAVE and everything between.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* Vidz */}
              <Link to="/xeraen/vidz" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #ef4444', cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: '#ef4444', height: '100%' }}>
                    <legend style={{ color: '#ef4444' }}>VIDZ</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: '#ef4444', fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ▶ VIDZ
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Visual transmissions. Live sessions, signal broadcasts, and archived operations.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>
            </div>

            {/* Footer tagline */}
            <div style={{ textAlign: 'center', padding: '15px', borderTop: `1px solid ${colorScheme.primary}` }}>
              <p style={{ color: colorScheme.primary, fontSize: '0.85em', fontStyle: 'italic', textShadow: `0 0 8px ${colorScheme.glow}` }}>
                transmitting from {futureYear} — for as long as {futureYear} exists
              </p>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}
