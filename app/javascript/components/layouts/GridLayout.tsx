import React from 'react'
import { HeaderMenu } from '~/components/navigation/HeaderMenu'
import { FooterMenu } from '~/components/navigation/FooterMenu'

interface GridLayoutProps {
  children: React.ReactNode
}

export const GridLayout: React.FC<GridLayoutProps> = ({ children }) => {
  return (
    <>
      <HeaderMenu />
      <br />
      <FooterMenu />
      <div className="ml-10 mb-20 pb-50">
        {children}
      </div>
    </>
  )
}
