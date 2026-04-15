/**
 * Regression coverage for the auth-timing race described in the
 * achievement-system review: /api/grid/current_hackr resolves AFTER
 * the artist fetch. Before the fix, the credit POST was gated inside
 * the fetch .then() and silently dropped. The split-effect fix fires
 * the credit when BOTH hackr and artist data are present — this test
 * asserts that flow.
 */

import React from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, waitFor, act } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import BandProfilePage from './BandProfilePage'

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    addEventListener: vi.fn(),
    removeEventListener: vi.fn()
  }))
})

// Controllable auth mock — mutate `mockGridAuth.hackr` between stages
const mockGridAuth: { hackr: { id: number; hackr_alias: string } | null } = { hackr: null }
vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => mockGridAuth
}))

// Stub layout + config so we don't need the whole tree
vi.mock('~/components/layouts/BandProfileLayout', () => ({
  default: ({ children }: { children?: React.ReactNode }) => <div data-testid="layout">{children}</div>
}))

vi.mock('./bandProfileConfig', () => ({
  bandProfiles: {
    'system-rot': {
      name: 'System Rot',
      colorScheme: { primary: '#000' },
      filterName: 'System Rot',
      renderIntro: () => <div>intro</div>,
      renderReleaseSection: () => <div>releases</div>,
      renderPhilosophy: () => <div>philosophy</div>
    }
  }
}))

// Capture every apiFetch / apiJson call
const apiCalls: Array<{ url: string; method: string }> = []

vi.mock('~/utils/apiClient', () => ({
  apiJson: vi.fn((url: string) => {
    apiCalls.push({ url, method: 'GET' })
    return Promise.resolve({ id: 1, name: 'System Rot', slug: 'system-rot', tracks: [] })
  }),
  apiFetch: vi.fn((url: string, init?: RequestInit) => {
    apiCalls.push({ url, method: (init?.method as string) || 'GET' })
    return Promise.resolve({ ok: true } as Response)
  })
}))

const bioViewedCalls = () => apiCalls.filter(c => c.method === 'POST' && c.url.includes('/bio_viewed'))

describe('BandProfilePage — achievement credit auth-timing race', () => {
  beforeEach(() => {
    apiCalls.length = 0
    mockGridAuth.hackr = null
  })

  it('does not credit the bio view when unauthenticated', async () => {
    render(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    // Wait for the artist fetch to resolve
    await waitFor(() => {
      expect(apiCalls.some(c => c.url === '/api/artists/system-rot')).toBe(true)
    })

    // Give React a tick to flush effects
    await new Promise(r => setTimeout(r, 10))

    expect(bioViewedCalls()).toHaveLength(0)
  })

  it('credits the bio view when auth resolves AFTER the artist fetch', async () => {
    // Start unauthenticated — auth context still loading
    const { rerender } = render(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    // Artist fetch lands first; no credit yet because hackr is null
    await waitFor(() => {
      expect(apiCalls.some(c => c.url === '/api/artists/system-rot')).toBe(true)
    })
    await new Promise(r => setTimeout(r, 10))
    expect(bioViewedCalls()).toHaveLength(0)

    // Auth resolves — re-render triggers the paired effect to fire now
    mockGridAuth.hackr = { id: 42, hackr_alias: 'TestOperative' }
    rerender(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(bioViewedCalls()).toHaveLength(1)
    })
    expect(bioViewedCalls()[0].url).toBe('/api/artists/system-rot/bio_viewed')
  })

  it('fires the credit exactly once even with repeated re-renders', async () => {
    mockGridAuth.hackr = { id: 42, hackr_alias: 'TestOperative' }

    const { rerender } = render(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(bioViewedCalls()).toHaveLength(1)
    })

    // Force additional re-renders — the Set-backed dedup ref must
    // prevent any further POSTs for the same slug.
    rerender(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )
    rerender(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    await new Promise(r => setTimeout(r, 20))
    expect(bioViewedCalls()).toHaveLength(1)
  })

  it('credits a second hackr after a logout/login swap in the same session', async () => {
    // Hackr A mounts, gets credited for system-rot.
    mockGridAuth.hackr = { id: 42, hackr_alias: 'HackrA' }

    const { rerender } = render(
      <MemoryRouter initialEntries={['/system-rot']}>
        <BandProfilePage />
      </MemoryRouter>
    )

    await waitFor(() => {
      expect(bioViewedCalls()).toHaveLength(1)
    })

    // Hackr swap — A signs out, B signs in, no full reload.
    // The dedup ref is keyed to hackr.id via useHackrScopedDedupSet,
    // so B's credit must fire even though A already posted for the
    // same slug in the same SPA session.
    await act(async () => {
      mockGridAuth.hackr = null
      rerender(
        <MemoryRouter initialEntries={['/system-rot']}>
          <BandProfilePage />
        </MemoryRouter>
      )
    })

    await act(async () => {
      mockGridAuth.hackr = { id: 99, hackr_alias: 'HackrB' }
      rerender(
        <MemoryRouter initialEntries={['/system-rot']}>
          <BandProfilePage />
        </MemoryRouter>
      )
    })

    await waitFor(() => {
      expect(bioViewedCalls()).toHaveLength(2)
    })
  })
})
