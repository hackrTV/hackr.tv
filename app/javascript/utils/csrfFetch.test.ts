import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { installCsrfFetch } from './csrfFetch'

describe('installCsrfFetch', () => {
  let originalFetch: typeof window.fetch
  let fetchMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    originalFetch = window.fetch
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    window.fetch = fetchMock as unknown as typeof window.fetch
  })

  afterEach(() => {
    window.fetch = originalFetch
    document.head.querySelector('meta[name="csrf-token"]')?.remove()
  })

  function installToken (token = 'secret123'): void {
    const meta = document.createElement('meta')
    meta.name = 'csrf-token'
    meta.content = token
    document.head.appendChild(meta)
  }

  function headersOf (call: number = 0): Headers {
    const init = fetchMock.mock.calls[call]![1] as RequestInit
    return new Headers(init?.headers)
  }

  it('adds CSRF and XHR headers to mutating requests', async () => {
    installToken()
    installCsrfFetch()

    await window.fetch('/api/thing', { method: 'POST', body: '{}' })

    expect(headersOf().get('X-CSRF-Token')).toBe('secret123')
    expect(headersOf().get('X-Requested-With')).toBe('XMLHttpRequest')
  })

  it('leaves GET and HEAD requests untouched', async () => {
    installToken()
    installCsrfFetch()

    await window.fetch('/api/thing')
    await window.fetch('/api/thing', { method: 'HEAD' })

    expect(fetchMock.mock.calls[0]![1]).toEqual({})
    expect((fetchMock.mock.calls[1]![1] as RequestInit).headers).toBeUndefined()
  })

  it('does not overwrite caller-provided headers', async () => {
    installToken()
    installCsrfFetch()

    await window.fetch('/api/thing', {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': 'caller-wins', 'Content-Type': 'application/json' }
    })

    expect(headersOf().get('X-CSRF-Token')).toBe('caller-wins')
    expect(headersOf().get('Content-Type')).toBe('application/json')
  })

  it('is a no-op without a csrf-token meta tag', async () => {
    installCsrfFetch()

    expect(window.fetch).toBe(fetchMock) // not wrapped
  })
})
