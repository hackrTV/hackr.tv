import React, { useEffect, lazy, Suspense } from 'react'
import { Routes, Route, useLocation, Navigate } from 'react-router-dom'
import { HomePage } from '~/components/pages/HomePage'
import { LoadingPage } from '~/components/shared/LoadingSpinner'

// Lazy load pages for code splitting
const PulseVaultPage = lazy(() => import('~/components/pages/fm/PulseVaultPage').then(m => ({ default: m.PulseVaultPage })))
const RadioPage = lazy(() => import('~/components/pages/fm/RadioPage').then(m => ({ default: m.RadioPage })))
const BandsPage = lazy(() => import('~/components/pages/fm/BandsPage').then(m => ({ default: m.BandsPage })))
const PlaylistsPage = lazy(() => import('~/components/pages/playlists/PlaylistsPage').then(m => ({ default: m.PlaylistsPage })))
const PlaylistDetailPage = lazy(() => import('~/components/pages/playlists/PlaylistDetailPage').then(m => ({ default: m.PlaylistDetailPage })))
const SharedPlaylistPage = lazy(() => import('~/components/pages/playlists/SharedPlaylistPage').then(m => ({ default: m.SharedPlaylistPage })))
const TheCyberPulsePage = lazy(() => import('~/components/pages/artist/TheCyberPulsePage'))
const XeraenPage = lazy(() => import('~/components/pages/artist/XeraenPage'))
const XeraenLinkzPage = lazy(() => import('~/components/pages/artist/XeraenLinkzPage'))
const SectorXPage = lazy(() => import('~/components/pages/artist/SectorXPage'))
const BandProfilePage = lazy(() => import('~/components/pages/artist/BandProfilePage'))
const WavelengthZeroPage = lazy(() => import('~/components/pages/artist/WavelengthZeroPage'))
const TrackListPage = lazy(() => import('~/components/pages/tracks/TrackListPage'))
const TrackDetailPage = lazy(() => import('~/components/pages/tracks/TrackDetailPage'))
const GridGamePage = lazy(() => import('~/components/pages/grid/GridGamePage').then(m => ({ default: m.GridGamePage })))
const GridLoginPage = lazy(() => import('~/components/pages/grid/GridLoginPage').then(m => ({ default: m.GridLoginPage })))
const GridRegisterPage = lazy(() => import('~/components/pages/grid/GridRegisterPage').then(m => ({ default: m.GridRegisterPage })))
const LogsIndexPage = lazy(() => import('~/components/pages/logs/LogsIndexPage').then(m => ({ default: m.LogsIndexPage })))
const LogDetailPage = lazy(() => import('~/components/pages/logs/LogDetailPage').then(m => ({ default: m.LogDetailPage })))
const NotFoundPage = lazy(() => import('~/components/errors/NotFoundPage').then(m => ({ default: m.NotFoundPage })))

// Auth components
import { ProtectedRoute } from '~/components/auth/ProtectedRoute'

export const AppLayout: React.FC = () => {
  const location = useLocation()

  // Scroll to top on route change
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [location.pathname])

  return (
    <Suspense fallback={<LoadingPage message="Loading page..." />}>
      <Routes>
        <Route path="/" element={<HomePage />} />
        {/* Redirect /fm to /fm/radio */}
        <Route path="/fm" element={<Navigate to="/fm/radio" replace />} />
        <Route path="/fm/pulse_vault" element={<PulseVaultPage />} />
        <Route path="/fm/radio" element={<RadioPage />} />
        <Route path="/fm/bands" element={<BandsPage />} />
        {/* Playlist routes - protected */}
        <Route path="/fm/playlists" element={<ProtectedRoute><PlaylistsPage /></ProtectedRoute>} />
        <Route path="/fm/playlists/:id" element={<ProtectedRoute><PlaylistDetailPage /></ProtectedRoute>} />
        {/* Shared playlist - public */}
        <Route path="/shared/:token" element={<SharedPlaylistPage />} />
        <Route path="/thecyberpulse" element={<TheCyberPulsePage />} />
        <Route path="/thecyberpulse/trackz" element={<TrackListPage />} />
        <Route path="/thecyberpulse/trackz/:trackSlug" element={<TrackDetailPage />} />
        <Route path="/xeraen" element={<XeraenPage />} />
        <Route path="/xeraen/trackz" element={<TrackListPage />} />
        <Route path="/xeraen/trackz/:trackSlug" element={<TrackDetailPage />} />
        <Route path="/xeraen/linkz" element={<XeraenLinkzPage />} />
        <Route path="/sector/x" element={<SectorXPage />} />
        <Route path="/system_rot" element={<BandProfilePage />} />
        <Route path="/voiceprint" element={<BandProfilePage />} />
        <Route path="/temporal_blue_drift" element={<BandProfilePage />} />
        <Route path="/wavelength_zero" element={<WavelengthZeroPage />} />
        {/* THE PULSE GRID routes */}
        <Route path="/grid" element={<GridGamePage />} />
        <Route path="/grid/login" element={<GridLoginPage />} />
        <Route path="/grid/register" element={<GridRegisterPage />} />
        {/* Hackr Logs routes */}
        <Route path="/logs" element={<LogsIndexPage />} />
        <Route path="/logs/:slug" element={<LogDetailPage />} />
        {/* 404 catch-all - must be last */}
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </Suspense>
  )
}
