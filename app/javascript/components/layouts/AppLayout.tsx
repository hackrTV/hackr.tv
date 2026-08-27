import React, { useEffect, lazy, Suspense } from 'react'
import { Routes, Route, useLocation } from 'react-router-dom'
import { trackEvent } from '~/utils/analyticsCollector'
import { LoadingPage } from '~/components/shared/LoadingSpinner'

// Every SPA page has migrated to Hotwire (Phases 1–6). What remains is
// the 404 catch-all shell + the achievement/mission toast listener for
// pages served through pages#spa_root — Phase 7 deletes all of this.
const NotFoundPage = lazy(() => import('~/components/errors/NotFoundPage').then(m => ({ default: m.NotFoundPage })))

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
          {/* 404 catch-all — the SPA's last remaining surface */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </Suspense>
    </>
  )
}
