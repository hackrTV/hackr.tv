import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'

// perfCollector keeps a module-level buffer + initialized flag — import
// fresh per test. web-vitals is mocked so tests can drive the callbacks.

type VitalCallback = (metric: { value: number }) => void
const vitalCallbacks: Record<string, VitalCallback> = {}

vi.mock('web-vitals', () => ({
  onLCP: (cb: VitalCallback) => { vitalCallbacks.LCP = cb },
  onINP: (cb: VitalCallback) => { vitalCallbacks.INP = cb },
  onCLS: (cb: VitalCallback) => { vitalCallbacks.CLS = cb },
  onFCP: (cb: VitalCallback) => { vitalCallbacks.FCP = cb },
  onTTFB: (cb: VitalCallback) => { vitalCallbacks.TTFB = cb }
}))

describe('perfCollector', () => {
  let fetchMock: ReturnType<typeof vi.fn>
  let beaconMock: ReturnType<typeof vi.fn>

  beforeEach(() => {
    vi.resetModules()
    vi.useFakeTimers()
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    beaconMock = vi.fn().mockReturnValue(true)
    vi.stubGlobal('fetch', fetchMock)
    Object.defineProperty(navigator, 'sendBeacon', { value: beaconMock, writable: true, configurable: true })
    for (const key of Object.keys(vitalCallbacks)) delete vitalCallbacks[key]
  })

  afterEach(() => {
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  async function fresh (): Promise<typeof import('./perfCollector')> {
    return await import('./perfCollector')
  }

  function sentMetrics (call = 0): Array<Record<string, unknown>> {
    const body = (fetchMock.mock.calls[call]![1] as RequestInit).body as string
    return JSON.parse(body).metrics
  }

  it('captures web vitals and flushes on the 30s interval', async () => {
    const { initPerfCollector } = await fresh()
    initPerfCollector()

    vitalCallbacks.LCP!({ value: 1234.6 })
    vitalCallbacks.CLS!({ value: 0.04567 })

    expect(fetchMock).not.toHaveBeenCalled()
    vi.advanceTimersByTime(30_000)

    expect(fetchMock).toHaveBeenCalledWith('/api/perf/metrics', expect.objectContaining({ method: 'POST' }))
    const metrics = sentMetrics()
    expect(metrics[0]).toMatchObject({ metric_name: 'LCP', metric_type: 'web_vital', value: 1235, unit: 'ms' })
    expect(metrics[1]).toMatchObject({ metric_name: 'CLS', value: 0.0457, unit: 'score' })
    expect(metrics[0]!.session_id).toBeTruthy()
    expect(metrics[0]!.page_path).toBe(window.location.pathname)

    // Buffer drained; empty flushes skip the POST
    vi.advanceTimersByTime(30_000)
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('flushes via sendBeacon when the page hides', async () => {
    const { initPerfCollector } = await fresh()
    initPerfCollector()
    vitalCallbacks.FCP!({ value: 800 })

    Object.defineProperty(document, 'visibilityState', { value: 'hidden', configurable: true })
    document.dispatchEvent(new Event('visibilitychange'))

    expect(beaconMock).toHaveBeenCalledTimes(1)
    expect(beaconMock.mock.calls[0]![0]).toBe('/api/perf/metrics')
    Object.defineProperty(document, 'visibilityState', { value: 'visible', configurable: true })
  })

  it('caps the buffer at 100 metrics', async () => {
    const { initPerfCollector } = await fresh()
    initPerfCollector()

    for (let i = 0; i < 150; i++) vitalCallbacks.INP!({ value: i })
    vi.advanceTimersByTime(30_000)

    expect(sentMetrics()).toHaveLength(100)
  })

  it('measureComponent records marked durations and tolerates missing marks', async () => {
    const { initPerfCollector, measureComponent } = await fresh()
    initPerfCollector()

    performance.mark('zone_start')
    performance.mark('zone_end')
    measureComponent('zone_render', 'zone_start', 'zone_end')

    measureComponent('ghost', 'missing_a', 'missing_b') // must not throw
    // (browsers throw on missing marks and the catch swallows it; jsdom
    // is lenient and records a zero-duration measure — either is fine)

    vi.advanceTimersByTime(30_000)
    const zone = sentMetrics().find((m) => m.metric_name === 'zone_render')
    expect(zone).toMatchObject({ metric_type: 'component', unit: 'ms' })
  })

  it('is idempotent across repeated init calls', async () => {
    const { initPerfCollector } = await fresh()
    initPerfCollector()
    const firstLCP = vitalCallbacks.LCP
    initPerfCollector()

    expect(vitalCallbacks.LCP).toBe(firstLCP)
  })
})
