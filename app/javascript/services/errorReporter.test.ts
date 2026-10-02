import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// errorReporter keeps module-level fingerprint state — import fresh per
// test via resetModules + dynamic import.

describe('errorReporter', () => {
  let fetchMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    vi.resetModules()
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('fetch', fetchMock)
  })

  afterEach(() => {
    window.onerror = null
    vi.unstubAllGlobals()
  })

  async function freshReporter (): Promise<typeof import('./errorReporter')> {
    return await import('./errorReporter')
  }

  it('reports global window errors with location fields', async () => {
    const { initErrorReporter } = await freshReporter()
    initErrorReporter()

    window.onerror!('boom', 'app.js', 10, 5, new Error('boom'))

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string)
    expect(body).toMatchObject({ message: 'boom', source: 'app.js', lineno: 10, colno: 5, type: 'global' })
    expect(body.stack).toContain('Error: boom')
  })

  it('reports unhandled promise rejections', async () => {
    const { initErrorReporter } = await freshReporter()
    initErrorReporter()

    // jsdom can't construct PromiseRejectionEvent; dispatch a stand-in
    // carrying the .reason the handler reads.
    const event = new Event('unhandledrejection') as Event & { reason: Error }
    event.reason = new Error('rejected!')
    window.dispatchEvent(event)

    // Listener registrations on window accumulate across module resets
    // (earlier tests' initErrorReporter calls) — assert on the latest
    // report rather than the call count.
    expect(fetchMock).toHaveBeenCalled()
    const lastCall = fetchMock.mock.calls[fetchMock.mock.calls.length - 1]!
    const body = JSON.parse((lastCall[1] as RequestInit).body as string)
    expect(body).toMatchObject({ message: 'rejected!', type: 'unhandled_rejection' })
  })

  it('reportError sends boundary reports', async () => {
    const { reportError } = await freshReporter()

    reportError(new Error('render died'), { componentStack: '\n  at Panel\n  at App' })

    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string)
    expect(body).toMatchObject({ message: 'render died', type: 'boundary', source: 'at Panel' })
  })

  it('caps identical reports at 5', async () => {
    const { reportError } = await freshReporter()

    for (let i = 0; i < 8; i++) reportError(new Error('same thing'))

    expect(fetchMock).toHaveBeenCalledTimes(5)
  })

  it('keeps distinct errors flowing after one fingerprint is capped', async () => {
    const { reportError } = await freshReporter()

    for (let i = 0; i < 6; i++) reportError(new Error('noisy'))
    reportError(new Error('different'))

    expect(fetchMock).toHaveBeenCalledTimes(6)
  })
})
