/**
 * Regression coverage for the radio false-positive credit path:
 * before the fix, the tune_in POST fired before audioRef.play()
 * resolved, so autoplay rejections / bad stream URLs still advanced
 * the achievement counter. Fix: credit lives inside play().then().
 */

import React from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, act } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { RadioPage } from './RadioPage'

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

vi.mock('~/components/layouts/FmLayout', () => ({
  FmLayout: ({ children }: { children?: React.ReactNode }) => <div data-testid="layout">{children}</div>
}))

vi.mock('~/hooks/useStreamStatus', () => ({
  useStreamStatus: () => ({ isLive: false, streamInfo: null })
}))

// Isolate the test from the 500ms audioPlayer-context polling loop
vi.mock('~/components/shared/CodexText', () => ({
  CodexText: ({ children }: { children?: React.ReactNode }) => <span>{children}</span>
}))

const apiCalls: Array<{ url: string; method: string }> = []
vi.mock('~/utils/apiClient', () => ({
  apiJson: vi.fn((url: string) => {
    apiCalls.push({ url, method: 'GET' })
    if (url === '/api/radio_stations') {
      return Promise.resolve([
        {
          id: 7,
          name: 'Test Stream Station',
          slug: 'test-stream',
          description: '',
          genre: 'Test',
          color: 'purple-168',
          stream_url: 'http://example.test/stream.mp3',
          playlists: []
        }
      ])
    }
    return Promise.resolve([])
  }),
  apiFetch: vi.fn((url: string, init?: RequestInit) => {
    apiCalls.push({ url, method: (init?.method as string) || 'GET' })
    return Promise.resolve({ ok: true } as Response)
  })
}))

const tuneInCalls = () => apiCalls.filter(c => c.method === 'POST' && c.url.includes('/tune_in'))

describe('RadioPage — raw-stream tune_in credit requires play() to resolve', () => {
  beforeEach(() => {
    apiCalls.length = 0
    mockGridAuth.hackr = { id: 1, hackr_alias: 'TestOperative' }
    vi.restoreAllMocks()
    // Silence the alert() shown on play failure
    vi.spyOn(window, 'alert').mockImplementation(() => {})
  })

  it('does NOT credit when play() rejects (autoplay blocked / bad URL)', async () => {
    vi.spyOn(window.HTMLMediaElement.prototype, 'play').mockRejectedValue(
      new Error('NotAllowedError: autoplay blocked')
    )

    render(
      <MemoryRouter>
        <RadioPage />
      </MemoryRouter>
    )

    // Wait for stations to load
    const playButton = await screen.findByText(/PLAY STATION|TUNE IN|PLAY/i, {}, { timeout: 2000 })

    await act(async () => {
      await userEvent.click(playButton)
    })

    // Give the rejected promise a tick to settle
    await new Promise(r => setTimeout(r, 20))

    expect(tuneInCalls()).toHaveLength(0)
  })

  it('credits exactly once when play() resolves successfully', async () => {
    vi.spyOn(window.HTMLMediaElement.prototype, 'play').mockResolvedValue(undefined)

    render(
      <MemoryRouter>
        <RadioPage />
      </MemoryRouter>
    )

    const playButton = await screen.findByText(/PLAY STATION|TUNE IN|PLAY/i, {}, { timeout: 2000 })

    await act(async () => {
      await userEvent.click(playButton)
    })

    await waitFor(() => {
      expect(tuneInCalls()).toHaveLength(1)
    })
    expect(tuneInCalls()[0].url).toBe('/api/radio_stations/7/tune_in')
  })
})
