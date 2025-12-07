import React from 'react'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'
import { PrereleaseBanner } from '~/components/prerelease/PrereleaseBanner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { useMobileMenu } from '~/contexts/MobileMenuContext'

interface GridLayoutProps {
  children: React.ReactNode
}

export const GridLayout: React.FC<GridLayoutProps> = ({ children }) => {
  const { isMobile } = useMobileDetect()
  const { setMobileMenuOpen } = useMobileMenu()

  return (
    <>
      <HeaderMenu />
      <PrereleaseBanner />
      {!isMobile && <br />}
      <FooterMenu />
      <div className="ml-10 mb-20 pb-50">
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
    </>
  )
}
