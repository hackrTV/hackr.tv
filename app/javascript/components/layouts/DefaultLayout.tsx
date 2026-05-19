import React, { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'
import { LiveNowBanner } from '~/components/stream/LiveNowBanner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'
import { useStreamStatus } from '~/hooks/useStreamStatus'

interface DefaultLayoutProps {
  children: ReactNode
  showAsciiArt?: boolean
  topBanner?: ReactNode
  hideLiveBanner?: boolean
}

export const DefaultLayout: React.FC<DefaultLayoutProps> = ({ children, showAsciiArt = true, topBanner, hideLiveBanner }) => {
  const { isMobile } = useMobileDetect()
  const { setMobileMenuOpen } = useMobileMenu()
  const { isLive, streamInfo } = useStreamStatus()

  return (
    <div className="black-168">
      <HeaderMenu />
      {isLive && streamInfo && !hideLiveBanner && (
        <LiveNowBanner stream={streamInfo} />
      )}

      {!isMobile && <br />}

      {topBanner}

      {/* ASCII Art Header - hidden on mobile */}
      {showAsciiArt && !isMobile && (
        <>
          <div style={{ maxWidth: '1200px', margin: '0 auto', display: 'flex', justifyContent: 'center' }} className="white-168-text">
            <Link to="/" style={{ display: 'inline-block' }}>
              <pre id="greetings" style={{ fontSize: '11px' }}>
                {` __  __                   __            ______  __  __
/\\ \\/\\ \\                 /\\ \\          /\\__  _\\/\\ \\/\\ \\
\\ \\ \\_\\ \\     __      ___\\ \\ \\/'\\   _ _\\/_/\\ \\/\\ \\ \\ \\ \\
 \\ \\  _  \\  /'__\`\\   /'___\\ \\ , <  /\\\`'__\\\\ \\ \\ \\ \\ \\ \\ \\
  \\ \\ \\ \\ \\/\\ \\L\\._/\\ \\__/\\ \\ \\\\\`\\\\ \\ \\/ _\\ \\ \\ \\ \\ \\_/ \\
   \\ \\_\\ \\_\\ \\__/.\\_\\ \\____\\\\ \\_\\ \\_\\ \\_\\/\\_\\ \\_\\ \\ \`\\___/
    \\/_/\\/_/\\/__/\\/_/\\/____/ \\/_/\\/_/\\/_/\\/_/\\/_/  \`\\/__/`}
              </pre>
            </Link>
          </div>

          <br />
        </>
      )}

      {/* Mobile Header - simple text logo */}
      {showAsciiArt && isMobile && (
        <div style={{ textAlign: 'center', padding: '10px 0' }} className="white-168-text">
          <Link to="/" style={{ fontSize: '24px', fontWeight: 'bold', letterSpacing: '2px' }}>
            HACKR.TV
          </Link>
        </div>
      )}

      {/* Footer Navigation Menu */}
      <FooterMenu />

      {/* Main Content */}
      <div className={isMobile ? 'mb-20 pb-50' : 'ml-10 mb-20 pb-50'} style={isMobile ? { padding: '0 10px' } : undefined}>
        {children}
      </div>

      {/* Bottom menu button - mobile only */}
      {isMobile && (
        <div style={{ padding: '0 20px 40px 20px', marginTop: '-25px', textAlign: 'center', position: 'relative', zIndex: 1000 }}>
          <button
            onClick={() => setMobileMenuOpen(true)}
            style={{
              background: '#0a0a0a',
              border: '2px solid #7c3aed',
              color: '#7c3aed',
              padding: '8px 16px',
              fontFamily: 'inherit',
              fontSize: '16px',
              cursor: 'pointer',
              margin: 0,
              fontWeight: 'bold',
              position: 'relative',
              zIndex: 1001
            }}
          >
            [≡] MENU
          </button>
          <br />
          <br />
        </div>
      )}
    </div>
  )
}
