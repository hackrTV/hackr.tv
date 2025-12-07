import React, { ReactNode } from 'react'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'
import { PrereleaseBanner } from '~/components/prerelease/PrereleaseBanner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'

interface FmLayoutProps {
  children: ReactNode
}

export const FmLayout: React.FC<FmLayoutProps> = ({ children }) => {
  const { isMobile } = useMobileDetect()
  const { setMobileMenuOpen } = useMobileMenu()

  return (
    <div className="black-168">
      <HeaderMenu />
      <PrereleaseBanner />

      {!isMobile && <br />}

      {/* Footer Navigation Menu */}
      <FooterMenu />

      {/* Main Content */}
      <div className="ml-10 mb-20 pb-50 mt-30">
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
              fontFamily: '\'Courier New\', Courier, monospace',
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
