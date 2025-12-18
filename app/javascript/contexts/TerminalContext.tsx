import React, { createContext, useContext, ReactNode } from 'react'
import { useTerminalAccess } from '~/hooks/useTerminalAccess'
import { TerminalModal } from '~/components/terminal/TerminalModal'

interface TerminalContextType {
  isTerminalOpen: boolean
  openTerminal: () => void
  closeTerminal: () => void
  toggleTerminal: () => void
}

const TerminalContext = createContext<TerminalContextType | null>(null)

// Default no-op functions for when used outside provider (e.g., tests)
const defaultValue: TerminalContextType = {
  isTerminalOpen: false,
  openTerminal: () => {},
  closeTerminal: () => {},
  toggleTerminal: () => {}
}

export const useTerminal = () => {
  const context = useContext(TerminalContext)
  // Return default no-op values if not in provider (useful for tests)
  return context ?? defaultValue
}

interface TerminalProviderProps {
  children: ReactNode
  idleTimeout?: number
  enableIdleTakeover?: boolean
}

export const TerminalProvider: React.FC<TerminalProviderProps> = ({
  children,
  idleTimeout = 120000,
  enableIdleTakeover = true
}) => {
  const {
    isTerminalOpen,
    openTerminal,
    closeTerminal,
    toggleTerminal
  } = useTerminalAccess({ idleTimeout, enableIdleTakeover })

  const value: TerminalContextType = {
    isTerminalOpen,
    openTerminal,
    closeTerminal,
    toggleTerminal
  }

  return (
    <TerminalContext.Provider value={value}>
      {children}
      <TerminalModal isOpen={isTerminalOpen} onClose={closeTerminal} />
    </TerminalContext.Provider>
  )
}
