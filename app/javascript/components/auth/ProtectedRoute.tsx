import React, { type ReactNode } from 'react'
import { Navigate } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface ProtectedRouteProps {
  children: ReactNode
}

export const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isLoggedIn, loading } = useGridAuth()

  if (loading) {
    return <LoadingSpinner message="Checking authentication..." />
  }

  if (!isLoggedIn) {
    return <Navigate to="/grid/login" replace />
  }

  return <>{children}</>
}
