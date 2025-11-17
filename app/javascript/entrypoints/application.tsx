import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import { AudioProvider } from '~/contexts/AudioContext'
import { AppLayout } from '~/components/layouts/AppLayout'
import { ErrorBoundary } from '~/components/errors/ErrorBoundary'

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
          <AudioProvider>
            <AppLayout />
          </AudioProvider>
        </BrowserRouter>
      </ErrorBoundary>
    </React.StrictMode>
  )
})
