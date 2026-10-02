import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// analyticsCollector keeps a module-level queue + initialized flag —
// import fresh per test via resetModules + dynamic import.

describe('analyticsCollector', () => {
  let fetchMock: ReturnType<typeof vi.fn>
  let beaconMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    vi.resetModules()
    vi.useFakeTimers()
    sessionStorage.clear()
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    beaconMock = vi.fn().mockReturnValue(true)
    vi.stubGlobal('fetch', fetchMock)
    Object.defineProperty(navigator, 'sendBeacon', { value: beaconMock, writable: true, configurable: true })
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  async function fresh (): Promise<typeof import('./analyticsCollector')> {
    return await import('./analyticsCollector')
  }

  it('assigns a stable per-session id persisted in sessionStorage', async () => {
    const { trackEvent, startAnalyticsCollector } = await fresh()
    startAnalyticsCollector()
    trackEvent('panel_open', 'breach_panel')

    vi.advanceTimersByTime(45_000)

    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string)
    const ids = body.events.map((e: { session_id: string }) => e.session_id)
    expect(new Set(ids).size).toBe(1)
    expect(sessionStorage.getItem('hackr_analytics_session_id')).toBe(ids[0])
  })

  it('tracks session_start on init and flushes batches on the interval', async () => {
    const { trackEvent, startAnalyticsCollector } = await fresh()
    startAnalyticsCollector()
    trackEvent('command_entered', 'exec', { program: 'trace-killer' })

    expect(fetchMock).not.toHaveBeenCalled()
    vi.advanceTimersByTime(45_000)

    expect(fetchMock).toHaveBeenCalledWith('/api/analytics/events', expect.objectContaining({ method: 'POST' }))
    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string)
    expect(body.events.map((e: { event_name: string }) => e.event_name)).toEqual(['app_loaded', 'exec'])
    expect(body.events[1]).toMatchObject({ event_type: 'command_entered', properties: { program: 'trace-killer' } })

    // Queue drained: next interval sends nothing
    vi.advanceTimersByTime(45_000)
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('flushes via sendBeacon when the page is hidden', async () => {
    const { trackEvent, startAnalyticsCollector } = await fresh()
    startAnalyticsCollector()
    trackEvent('button_click', 'tx')

    Object.defineProperty(document, 'visibilityState', { value: 'hidden', configurable: true })
    document.dispatchEvent(new Event('visibilitychange'))

    expect(beaconMock).toHaveBeenCalledTimes(1)
    expect(beaconMock.mock.calls[0]![0]).toBe('/api/analytics/events')
    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
  })

  it('is idempotent across repeated start calls', async () => {
    const { startAnalyticsCollector } = await fresh()
    startAnalyticsCollector()
    startAnalyticsCollector()

    vi.advanceTimersByTime(45_000)
    const body = JSON.parse((fetchMock.mock.calls[0]![1] as RequestInit).body as string)
    expect(body.events.filter((e: { event_type: string }) => e.event_type === 'session_start')).toHaveLength(1)
  })
})
