import React, { useEffect, lazy, Suspense } from 'react'
import { Routes, Route, useLocation } from 'react-router-dom'
import { trackEvent } from '~/utils/analyticsCollector'
import { LoadingPage } from '~/components/shared/LoadingSpinner'

// Lazy load pages for code splitting.
// The music cluster migrated to Hotwire in Phase 4 and Uplink in
// Phase 5 — only THE PULSE GRID remains.
const GridGamePage = lazy(() => import('~/components/pages/grid/GridGamePage').then(m => ({ default: m.GridGamePage })))
const GridTacticalPage = lazy(() => import('~/components/pages/grid/GridTacticalPage').then(m => ({ default: m.GridTacticalPage })))
const AchievementsPage = lazy(() => import('~/components/pages/grid/AchievementsPage'))
const MissionsPage = lazy(() => import('~/components/pages/grid/MissionsPage'))
const SchematicsPage = lazy(() => import('~/components/pages/grid/SchematicsPage'))
const LoadoutPage = lazy(() => import('~/components/pages/grid/LoadoutPage'))
const DeckPage = lazy(() => import('~/components/pages/grid/DeckPage'))
const TransitPage = lazy(() => import('~/components/pages/grid/TransitPage'))
const NotFoundPage = lazy(() => import('~/components/errors/NotFoundPage').then(m => ({ default: m.NotFoundPage })))

// Auth components
import { ProtectedRoute } from '~/components/auth/ProtectedRoute'
import { FeatureGate } from '~/components/auth/FeatureGate'
import { AchievementToastContainer } from '~/components/shared/AchievementToast'

export const AppLayout: React.FC = () => {
  const location = useLocation()

  // Scroll to top on route change + track page view (including initial load)
  useEffect(() => {
    window.scrollTo(0, 0)
    trackEvent('page_view', location.pathname)
  }, [location.pathname])

  return (
    <>
      <AchievementToastContainer />
      <Suspense fallback={<LoadingPage message="Loading page..." />}>
        <Routes>
          {/* THE PULSE GRID routes */}
          <Route path="/achievements" element={<ProtectedRoute><AchievementsPage /></ProtectedRoute>} />
          <Route path="/missions" element={<ProtectedRoute><MissionsPage /></ProtectedRoute>} />
          <Route path="/schematics" element={<ProtectedRoute><SchematicsPage /></ProtectedRoute>} />
          <Route path="/loadout" element={<ProtectedRoute><LoadoutPage /></ProtectedRoute>} />
          <Route path="/deck" element={<ProtectedRoute><DeckPage /></ProtectedRoute>} />
          <Route path="/transit" element={<ProtectedRoute><TransitPage /></ProtectedRoute>} />
          <Route path="/grid" element={<FeatureGate feature="pulse_grid"><GridGamePage /></FeatureGate>} />
          <Route path="/grid/1337" element={<FeatureGate feature="tactical_grid"><GridTacticalPage /></FeatureGate>} />
          {/* 404 catch-all - must be last */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </Suspense>
    </>
  )
}
