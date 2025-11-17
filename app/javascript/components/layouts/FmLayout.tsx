import React, { ReactNode } from 'react'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'

interface FmLayoutProps {
  children: ReactNode
}

export const FmLayout: React.FC<FmLayoutProps> = ({ children }) => {
  return (
    <div className="black-168">
      {/* Header Navigation Menu (no ASCII art) */}
      <HeaderMenu />

      <br />

      {/* Footer Navigation Menu */}
      <FooterMenu />

      {/* Main Content */}
      <div className="ml-10 mb-20 pb-50 mt-30">
        {children}
      </div>
    </div>
  )
}
