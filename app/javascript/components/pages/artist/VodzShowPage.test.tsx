/**
 * Regression coverage for the VOD achievement over-credit issue: page
 * load alone must not fire the `watch` POST. Credit fires only when
 * YouTubePlayer reports the PLAYING state via its `onPlay` callback.
 */

import React from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, waitFor } from '@testing-library/react'
import { MemoryRouter, Routes, Route } from 'react-router-dom'
import VodzShowPage from './VodzShowPage'

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn()
  }))
})

const mockGridAuth: { hackr: { id: number; hackr_alias: string } | null } = {
  hackr: { id: 1, hackr_alias: 'TestOperative' }
}
vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => mockGridAuth
}))

vi.mock('~/components/layouts/DefaultLayout', () => ({
  DefaultLayout: ({ children }: { children?: React.ReactNode }) => <div data-testid="layout">{children}</div>
}))

// Capture the onPlay prop so the test can fire it manually — the real
// YT IFrame API is too heavy to drive in JSDOM.
let capturedOnPlay: (() => void) | null = null
vi.mock('~/components/YouTubePlayer', () => ({
  YouTubePlayer: ({ onPlay }: { onPlay?: () => void }) => {
    capturedOnPlay = onPlay || null
    return <div data-testid="yt-player" />
  }
}))

const apiCalls: Array<{ url: string; method: string }> = []
vi.mock('~/utils/apiClient', () => ({
  apiJson: vi.fn(() => {
    apiCalls.push({ url: '/api/artists/thecyberpulse/vods/42', method: 'GET' })
    return Promise.resolve({
      id: 42,
      title: 'Test VOD',
      vod_url: 'https://www.youtube.com/embed/abc12345678',
      live_url: null,
      started_at: '2026-01-01T00:00:00Z',
      ended_at: null,
      was_livestream: false,
      artist: { id: 1, name: 'TCP', slug: 'thecyberpulse' }
    })
  }),
  apiFetch: vi.fn((url: string, init?: RequestInit) => {
    apiCalls.push({ url, method: (init?.method as string) || 'GET' })
    return Promise.resolve({ ok: true } as Response)
  })
}))

const watchCalls = () => apiCalls.filter(c => c.method === 'POST' && c.url.includes('/watch'))

const renderPage = () =>
  render(
    <MemoryRouter initialEntries={['/thecyberpulse/vidz/42']}>
      <Routes>
        <Route path="/:artist/vidz/:id" element={<VodzShowPage />} />
      </Routes>
    </MemoryRouter>
  )

describe('VodzShowPage — watch credit requires actual playback', () => {
  beforeEach(() => {
    apiCalls.length = 0
    capturedOnPlay = null
    mockGridAuth.hackr = { id: 1, hackr_alias: 'TestOperative' }
  })

  it('does NOT credit on page load — user has to click play', async () => {
    renderPage()

    // Wait for the VOD fetch and YouTubePlayer to mount
    await waitFor(() => {
      expect(capturedOnPlay).not.toBeNull()
    })

    // Give effects a tick to flush
    await new Promise(r => setTimeout(r, 10))

    expect(watchCalls()).toHaveLength(0)
  })

  it('credits when YouTubePlayer reports PLAYING via onPlay', async () => {
    renderPage()

    await waitFor(() => {
      expect(capturedOnPlay).not.toBeNull()
    })

    // User clicks play → YT API fires PLAYING → onPlay invoked
    capturedOnPlay!()

    await waitFor(() => {
      expect(watchCalls()).toHaveLength(1)
    })
    expect(watchCalls()[0].url).toBe('/api/artists/thecyberpulse/vods/42/watch')
  })

  it('credits exactly once even if onPlay fires multiple times', async () => {
    renderPage()

    await waitFor(() => {
      expect(capturedOnPlay).not.toBeNull()
    })

    // Repeated onPlay (pause/resume cycles) must not re-credit
    capturedOnPlay!()
    capturedOnPlay!()
    capturedOnPlay!()

    await waitFor(() => {
      expect(watchCalls()).toHaveLength(1)
    })
  })

  it('does not credit anon users even when onPlay fires', async () => {
    mockGridAuth.hackr = null
    renderPage()

    await waitFor(() => {
      expect(capturedOnPlay).not.toBeNull()
    })

    capturedOnPlay!()
    await new Promise(r => setTimeout(r, 10))

    expect(watchCalls()).toHaveLength(0)
  })
})
