import React, { createContext, useContext, useState, ReactNode } from 'react'

interface MobileMenuContextType {
  mobileMenuOpen: boolean
  setMobileMenuOpen: (open: boolean) => void
}

const MobileMenuContext = createContext<MobileMenuContextType | null>(null)

export const useMobileMenu = () => {
  const context = useContext(MobileMenuContext)
  if (!context) {
    // Return a default implementation if context is not available
    // This prevents errors but the menu won't function
    return {
      mobileMenuOpen: false,
      setMobileMenuOpen: () => {}
    }
  }
  return context
}

interface MobileMenuProviderProps {
  children: ReactNode
}

export const MobileMenuProvider: React.FC<MobileMenuProviderProps> = ({ children }) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  return (
    <MobileMenuContext.Provider value={{ mobileMenuOpen, setMobileMenuOpen }}>
      {children}
    </MobileMenuContext.Provider>
  )
}
