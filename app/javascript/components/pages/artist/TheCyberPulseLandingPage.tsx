import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

const colorScheme = {
  primary: '#8B00FF',
  secondary: '#9B59B6',
  glow: 'rgba(139, 0, 255, 0.6)',
  glowStrong: 'rgba(139, 0, 255, 0.8)',
  background: '#0a0a0a'
}

export const TheCyberPulseLandingPage: React.FC = () => {
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
            THE.CYBERPUL.SE
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
              [:: THE.CYBERPUL.SE ::]
            </h2>
            <p style={{ textAlign: 'center', color: '#666', marginBottom: '30px', fontSize: '0.9em' }}>
              SIGNAL ORIGIN &amp; BROADCAST HUB
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
                XERAEN transmits. Ryker keeps the beat. Synthia holds the frequency steady.
                Together they are The.CyberPul.se — <span style={{ color: colorScheme.primary, textShadow: `0 0 8px ${colorScheme.glow}` }}>broadcasting from {futureYear} across a century
                that shouldn't be crossable</span>.
              </p>
              <p style={{ color: '#aaa', marginBottom: '15px' }}>
                What they carry reaches you right now, a hundred years before it was sent.
                You're not supposed to be hearing this. But here you are.
              </p>
              <p style={{ color: '#888' }}>
                You found the frequency. Everything else is below.
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
              <Link to="/thecyberpulse/bio" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: `1px solid ${colorScheme.primary}`, cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: colorScheme.primary, height: '100%' }}>
                    <legend style={{ color: colorScheme.primary }}>BIO</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: colorScheme.primary, fontSize: '1.4em', marginBottom: '10px', textAlign: 'center', textShadow: `0 0 8px ${colorScheme.glow}` }}>
                        ◈ BIO
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Who they are. How this started. What it costs them to keep transmitting.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* Releases */}
              <Link to="/thecyberpulse/releases" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: `1px solid ${colorScheme.secondary}`, cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: colorScheme.secondary, height: '100%' }}>
                    <legend style={{ color: colorScheme.secondary }}>RELEASES</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: colorScheme.secondary, fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ◆ RELEASES
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Albums, EPs, and singles from across the timeline. Every signal committed to record.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* Vidz */}
              <Link to="/thecyberpulse/vidz" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #ef4444', cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: '#ef4444', height: '100%' }}>
                    <legend style={{ color: '#ef4444' }}>VIDZ</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: '#ef4444', fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ▶ VIDZ
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Visual transmissions. Live operations, broadcasts, and archived footage from the signal.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>
            </div>

            {/* Footer tagline */}
            <div style={{ textAlign: 'center', padding: '15px', borderTop: `1px solid ${colorScheme.primary}` }}>
              <p style={{ color: colorScheme.primary, fontSize: '0.85em', textShadow: `0 0 8px ${colorScheme.glow}` }}>
                broadcasting from {futureYear} — the signal is always on
              </p>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}
