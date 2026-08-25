import React, { useEffect, type ReactNode } from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface ProtectedRouteProps {
  children: ReactNode
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isLoggedIn, loading } = useGridAuth()

  // The login page is server-rendered (Hotwire, Phase 2) and no longer in
  // this router — leaving the SPA requires a full page load.
  useEffect(() => {
    if (!loading && !isLoggedIn) {
      window.location.replace('/grid/login')
    }
  }, [loading, isLoggedIn])

  if (loading || !isLoggedIn) {
    return <LoadingSpinner message="Checking authentication..." />
  }

  return <>{children}</>
}
