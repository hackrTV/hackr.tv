import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { AudioProvider } from '~/contexts/AudioContext'
import { MobileMenuProvider } from '~/contexts/MobileMenuContext'
import { AppSettingsProvider } from '~/contexts/AppSettingsContext'
import { TerminalProvider } from '~/contexts/TerminalContext'
import { GridAuthProvider } from '~/contexts/GridAuthContext'
import { AppLayout } from '~/components/layouts/AppLayout'
import { ErrorBoundary } from '~/components/errors/ErrorBoundary'
import { LowercaseRedirect } from '~/components/routing/LowercaseRedirect'

// Mount React SPA when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Find or create root element
  let appRoot = document.getElementById('root')
  if (!appRoot) {
    appRoot = document.createElement('div')
    appRoot.id = 'root'
    document.body.appendChild(appRoot)
  }

  createRoot(appRoot).render(
    <React.StrictMode>
      <ErrorBoundary>
        <BrowserRouter>
          <LowercaseRedirect>
            <AppSettingsProvider>
              <GridAuthProvider>
                <MobileMenuProvider>
                  <TerminalProvider>
                    <AudioProvider>
                      <AppLayout />
                    </AudioProvider>
                  </TerminalProvider>
                </MobileMenuProvider>
              </GridAuthProvider>
            </AppSettingsProvider>
          </LowercaseRedirect>
        </BrowserRouter>
      </ErrorBoundary>
    </React.StrictMode>
  )
})
