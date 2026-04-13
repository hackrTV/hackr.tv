import React, { useEffect, lazy, Suspense } from 'react'
import { Routes, Route, useLocation } from 'react-router-dom'
import { HomePage } from '~/components/pages/HomePage'
import { LoadingPage } from '~/components/shared/LoadingSpinner'

// Lazy load pages for code splitting
const PulseVaultPage = lazy(() => import('~/components/pages/fm/PulseVaultPage').then(m => ({ default: m.PulseVaultPage })))
const FmLandingPage = lazy(() => import('~/components/pages/fm/FmLandingPage').then(m => ({ default: m.FmLandingPage })))
const FmReleasesPage = lazy(() => import('~/components/pages/fm/FmReleasesPage').then(m => ({ default: m.FmReleasesPage })))
const RadioPage = lazy(() => import('~/components/pages/fm/RadioPage').then(m => ({ default: m.RadioPage })))
const BandsPage = lazy(() => import('~/components/pages/fm/BandsPage').then(m => ({ default: m.BandsPage })))
const PlaylistsPage = lazy(() => import('~/components/pages/playlists/PlaylistsPage').then(m => ({ default: m.PlaylistsPage })))
const PlaylistDetailPage = lazy(() => import('~/components/pages/playlists/PlaylistDetailPage').then(m => ({ default: m.PlaylistDetailPage })))
const SharedPlaylistPage = lazy(() => import('~/components/pages/playlists/SharedPlaylistPage').then(m => ({ default: m.SharedPlaylistPage })))
const TheCyberPulseLandingPage = lazy(() => import('~/components/pages/artist/TheCyberPulseLandingPage').then(m => ({ default: m.TheCyberPulseLandingPage })))
const TheCyberPulsePage = lazy(() => import('~/components/pages/artist/TheCyberPulsePage'))
const XeraenLandingPage = lazy(() => import('~/components/pages/artist/XeraenLandingPage').then(m => ({ default: m.XeraenLandingPage })))
const XeraenPage = lazy(() => import('~/components/pages/artist/XeraenPage'))
const VodzPage = lazy(() => import('~/components/pages/artist/VodzPage'))
const VodzShowPage = lazy(() => import('~/components/pages/artist/VodzShowPage'))
const SectorXPage = lazy(() => import('~/components/pages/artist/SectorXPage'))
const BandProfilePage = lazy(() => import('~/components/pages/artist/BandProfilePage'))
const WavelengthZeroPage = lazy(() => import('~/components/pages/artist/WavelengthZeroPage'))
const TrackDetailPage = lazy(() => import('~/components/pages/tracks/TrackDetailPage'))
const ReleaseListPage = lazy(() => import('~/components/pages/releases/ReleaseListPage'))
const ReleaseDetailPage = lazy(() => import('~/components/pages/releases/ReleaseDetailPage'))
const GridGamePage = lazy(() => import('~/components/pages/grid/GridGamePage').then(m => ({ default: m.GridGamePage })))
const GridLoginPage = lazy(() => import('~/components/pages/grid/GridLoginPage').then(m => ({ default: m.GridLoginPage })))
const GridRegisterPage = lazy(() => import('~/components/pages/grid/GridRegisterPage').then(m => ({ default: m.GridRegisterPage })))
const GridVerifyPage = lazy(() => import('~/components/pages/grid/GridVerifyPage').then(m => ({ default: m.GridVerifyPage })))
const ForgotPasswordPage = lazy(() => import('~/components/pages/grid/ForgotPasswordPage').then(m => ({ default: m.ForgotPasswordPage })))
const IdentityPage = lazy(() => import('~/components/pages/grid/IdentityPage').then(m => ({ default: m.IdentityPage })))
const ResetPasswordPage = lazy(() => import('~/components/pages/grid/ResetPasswordPage').then(m => ({ default: m.ResetPasswordPage })))
const GridConfirmEmailChangePage = lazy(() => import('~/components/pages/grid/GridConfirmEmailChangePage').then(m => ({ default: m.GridConfirmEmailChangePage })))
const LogsIndexPage = lazy(() => import('~/components/pages/logs/LogsIndexPage').then(m => ({ default: m.LogsIndexPage })))
const LogDetailPage = lazy(() => import('~/components/pages/logs/LogDetailPage').then(m => ({ default: m.LogDetailPage })))
const CodexIndexPage = lazy(() => import('~/components/pages/codex/CodexIndexPage').then(m => ({ default: m.CodexIndexPage })))
const CodexEntryPage = lazy(() => import('~/components/pages/codex/CodexEntryPage').then(m => ({ default: m.CodexEntryPage })))
const HandbookIndexPage = lazy(() => import('~/components/pages/handbook/HandbookIndexPage').then(m => ({ default: m.HandbookIndexPage })))
const HandbookArticlePage = lazy(() => import('~/components/pages/handbook/HandbookArticlePage').then(m => ({ default: m.HandbookArticlePage })))
const TimelinePage = lazy(() => import('~/components/pages/timeline/TimelinePage').then(m => ({ default: m.TimelinePage })))
const HotwirePage = lazy(() => import('~/components/pulsewire/HotwirePage').then(m => ({ default: m.HotwirePage })))
const UserPulsesPage = lazy(() => import('~/components/pulsewire/UserPulsesPage').then(m => ({ default: m.UserPulsesPage })))
const SinglePulsePage = lazy(() => import('~/components/pulsewire/SinglePulsePage').then(m => ({ default: m.SinglePulsePage })))
const UplinkPage = lazy(() => import('~/components/pages/uplink/UplinkPage').then(m => ({ default: m.UplinkPage })))
const UplinkPopoutPage = lazy(() => import('~/components/pages/uplink/UplinkPopoutPage').then(m => ({ default: m.UplinkPopoutPage })))
const CodeIndexPage = lazy(() => import('~/components/pages/code/CodeIndexPage').then(m => ({ default: m.CodeIndexPage })))
const CodeRepoPage = lazy(() => import('~/components/pages/code/CodeRepoPage'))
const NotFoundPage = lazy(() => import('~/components/errors/NotFoundPage').then(m => ({ default: m.NotFoundPage })))

// Auth components
import { ProtectedRoute } from '~/components/auth/ProtectedRoute'
import { FeatureGate } from '~/components/auth/FeatureGate'

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
        <Route path="/fm" element={<FmLandingPage />} />
        <Route path="/fm/releases" element={<FmReleasesPage />} />
        <Route path="/vault" element={<PulseVaultPage />} />
        <Route path="/fm/radio" element={<RadioPage />} />
        <Route path="/f/net" element={<BandsPage />} />
        {/* Playlist routes - protected */}
        <Route path="/fm/playlists" element={<ProtectedRoute><PlaylistsPage /></ProtectedRoute>} />
        <Route path="/fm/playlists/:id" element={<ProtectedRoute><PlaylistDetailPage /></ProtectedRoute>} />
        {/* Shared playlist - public */}
        <Route path="/shared/:token" element={<SharedPlaylistPage />} />
        <Route path="/thecyberpulse" element={<TheCyberPulseLandingPage />} />
        <Route path="/thecyberpulse/bio" element={<TheCyberPulsePage />} />
        <Route path="/thecyberpulse/releases" element={<ReleaseListPage />} />
        <Route path="/thecyberpulse/releases/:releaseSlug" element={<ReleaseDetailPage />} />
        <Route path="/thecyberpulse/trackz/:trackSlug" element={<TrackDetailPage />} />
        <Route path="/thecyberpulse/vidz" element={<VodzPage />} />
        <Route path="/thecyberpulse/vidz/:id" element={<VodzShowPage />} />
        <Route path="/xeraen" element={<XeraenLandingPage />} />
        <Route path="/xeraen/bio" element={<XeraenPage />} />
        <Route path="/xeraen/releases" element={<ReleaseListPage />} />
        <Route path="/xeraen/releases/:releaseSlug" element={<ReleaseDetailPage />} />
        <Route path="/xeraen/trackz/:trackSlug" element={<TrackDetailPage />} />
        <Route path="/xeraen/vidz" element={<VodzPage />} />
        <Route path="/xeraen/vidz/:id" element={<VodzShowPage />} />
        <Route path="/sector/x" element={<SectorXPage />} />
        {/* Wavelength Zero has a custom landing page */}
        <Route path="/wavelength-zero" element={<WavelengthZeroPage />} />
        {/* Dynamic artist routes — catches any artist slug */}
        <Route path="/:artistSlug" element={<BandProfilePage />} />
        <Route path="/:artistSlug/releases" element={<ReleaseListPage />} />
        <Route path="/:artistSlug/releases/:releaseSlug" element={<ReleaseDetailPage />} />
        <Route path="/:artistSlug/trackz/:trackSlug" element={<TrackDetailPage />} />
        {/* THE PULSE GRID routes */}
        <Route path="/grid" element={<FeatureGate feature="pulse_grid"><GridGamePage /></FeatureGate>} />
        <Route path="/grid/login" element={<GridLoginPage />} />
        <Route path="/grid/register" element={<GridRegisterPage />} />
        <Route path="/grid/forgot_password" element={<ForgotPasswordPage />} />
        <Route path="/grid/verify/:token" element={<GridVerifyPage />} />
        <Route path="/grid/identity" element={<ProtectedRoute><IdentityPage /></ProtectedRoute>} />
        <Route path="/grid/reset_password/:token" element={<ResetPasswordPage />} />
        <Route path="/grid/confirm_email_change/:token" element={<GridConfirmEmailChangePage />} />
        {/* Hackr Logs routes */}
        <Route path="/logs" element={<LogsIndexPage />} />
        <Route path="/logs/:slug" element={<LogDetailPage />} />
        {/* Codex routes */}
        <Route path="/codex" element={<CodexIndexPage />} />
        <Route path="/codex/:slug" element={<CodexEntryPage />} />
        {/* Handbook routes - login required */}
        <Route path="/handbook" element={<ProtectedRoute><HandbookIndexPage /></ProtectedRoute>} />
        <Route path="/handbook/:slug" element={<ProtectedRoute><HandbookArticlePage /></ProtectedRoute>} />
        {/* Timeline route */}
        <Route path="/timeline" element={<TimelinePage />} />
        {/* PulseWire routes */}
        <Route path="/wire" element={<HotwirePage />} />
        <Route path="/wire/:username" element={<UserPulsesPage />} />
        <Route path="/wire/pulse/:id" element={<SinglePulsePage />} />
        {/* Uplink routes - protected */}
        <Route path="/uplink" element={<ProtectedRoute><UplinkPage /></ProtectedRoute>} />
        {/* Uplink popout - public for livestream viewing */}
        <Route path="/uplink/popout" element={<UplinkPopoutPage />} />
        {/* Code browser routes - protected */}
        <Route path="/code" element={<ProtectedRoute><CodeIndexPage /></ProtectedRoute>} />
        <Route path="/code/:repo" element={<ProtectedRoute><CodeRepoPage /></ProtectedRoute>} />
        <Route path="/code/:repo/tree/*" element={<ProtectedRoute><CodeRepoPage /></ProtectedRoute>} />
        <Route path="/code/:repo/blob/*" element={<ProtectedRoute><CodeRepoPage /></ProtectedRoute>} />
        {/* 404 catch-all - must be last */}
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </Suspense>
  )
}
