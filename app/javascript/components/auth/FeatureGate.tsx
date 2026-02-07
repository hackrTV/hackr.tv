import React, { type ReactNode } from 'react'
import { useGridAuth } from '~/hooks/useGridAuth'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { GridComingSoonPage } from '~/components/pages/grid/GridComingSoonPage'

interface FeatureGateProps {
  feature: string
  children: ReactNode
}

export const FeatureGate: React.FC<FeatureGateProps> = ({ feature, children }) => {
  const { isLoggedIn, loading, hasFeature } = useGridAuth()

  if (loading) {
    return <LoadingSpinner message="Checking access..." />
  }

  if (isLoggedIn && !hasFeature(feature)) {
    return <GridComingSoonPage />
  }

  return <>{children}</>
}
