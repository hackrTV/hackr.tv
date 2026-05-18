// Performance metrics collector. Captures Core Web Vitals via web-vitals
// library and custom component render timing. Batches and sends to
// /api/perf/metrics every 30s or on page unload via sendBeacon.

import { onLCP, onINP, onCLS, onFCP, onTTFB } from 'web-vitals'

interface PerfMetric {
  metric_name: string
  metric_type: 'web_vital' | 'component' | 'navigation'
  value: number
  unit: 'ms' | 'score'
  page_path: string
  session_id: string
  connection_type?: string
  device_class?: string
}

const ENDPOINT = '/api/perf/metrics'
const FLUSH_INTERVAL_MS = 30_000
const MAX_BUFFER = 100

let buffer: PerfMetric[] = []
let initialized = false
const sessionId = generateSessionId()

function generateSessionId (): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36)
}

function getConnectionType (): string | undefined {
  const nav = navigator as Navigator & { connection?: { effectiveType?: string } }
  return nav.connection?.effectiveType
}

function getDeviceClass (): 'mobile' | 'desktop' {
  return /Mobi|Android/i.test(navigator.userAgent) ? 'mobile' : 'desktop'
}

function enqueue (metric: Omit<PerfMetric, 'session_id' | 'page_path' | 'connection_type' | 'device_class'>): void {
  if (buffer.length >= MAX_BUFFER) return
  buffer.push({
    ...metric,
    page_path: window.location.pathname,
    session_id: sessionId,
    connection_type: getConnectionType(),
    device_class: getDeviceClass()
  })
}

function flush (useBeacon = false): void {
  if (buffer.length === 0) return
  const payload = JSON.stringify({ metrics: buffer.splice(0) })

  if (useBeacon && navigator.sendBeacon) {
    navigator.sendBeacon(ENDPOINT, new Blob([payload], { type: 'application/json' }))
  } else {
    fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: payload,
      keepalive: true
    }).catch(() => { /* perf data is non-critical */ })
  }
}

export function initPerfCollector (): void {
  if (initialized) return
  initialized = true

  // Core Web Vitals
  onLCP(({ value }) => enqueue({ metric_name: 'LCP', metric_type: 'web_vital', value: Math.round(value), unit: 'ms' }))
  onINP(({ value }) => enqueue({ metric_name: 'INP', metric_type: 'web_vital', value: Math.round(value), unit: 'ms' }))
  onCLS(({ value }) => enqueue({ metric_name: 'CLS', metric_type: 'web_vital', value: parseFloat(value.toFixed(4)), unit: 'score' }))
  onFCP(({ value }) => enqueue({ metric_name: 'FCP', metric_type: 'web_vital', value: Math.round(value), unit: 'ms' }))
  onTTFB(({ value }) => enqueue({ metric_name: 'TTFB', metric_type: 'web_vital', value: Math.round(value), unit: 'ms' }))

  // Periodic flush
  setInterval(() => flush(), FLUSH_INTERVAL_MS)

  // Flush on page unload/background
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flush(true)
  })
  window.addEventListener('pagehide', () => flush(true), { once: true })
}

// Measure component render/transition timing. Place performance.mark calls
// around the operation, then call this to record it.
//
//   performance.mark('zone_map_render_start')
//   // ... render ...
//   performance.mark('zone_map_render_end')
//   measureComponent('zone_map_render', 'zone_map_render_start', 'zone_map_render_end')
//
export function measureComponent (name: string, startMark: string, endMark: string): void {
  try {
    const measure = performance.measure(name, startMark, endMark)
    enqueue({
      metric_name: name,
      metric_type: 'component',
      value: Math.round(measure.duration),
      unit: 'ms'
    })
    // Clean up marks
    performance.clearMarks(startMark)
    performance.clearMarks(endMark)
    performance.clearMeasures(name)
  } catch {
    // marks may not exist in test environments
  }
}
