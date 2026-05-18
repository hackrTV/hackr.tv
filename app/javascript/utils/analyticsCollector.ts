// Frontend analytics event collector. Batches events in memory and
// sends them to /api/analytics/events every 45s or on page unload
// via sendBeacon.
//
// Usage:
//   import { trackEvent } from '~/utils/analyticsCollector'
//   trackEvent('panel_open', 'breach_panel')
//   trackEvent('command_entered', 'exec', { program: 'trace-killer' })

const FLUSH_INTERVAL_MS = 45_000
const BATCH_ENDPOINT = '/api/analytics/events'
const SESSION_KEY = 'hackr_analytics_session_id'

type EventType =
  | 'page_view' | 'feature_click' | 'button_click'
  | 'panel_open' | 'panel_close' | 'command_entered'
  | 'session_start' | 'session_end'

interface AnalyticsEvent {
  event_type: EventType
  event_name: string
  session_id: string
  properties?: Record<string, unknown>
}

const queue: AnalyticsEvent[] = []
let initialized = false

function getOrCreateSessionId (): string {
  let id = sessionStorage.getItem(SESSION_KEY)
  if (!id) {
    id = crypto.randomUUID?.() ?? Math.random().toString(36).slice(2) + Date.now().toString(36)
    sessionStorage.setItem(SESSION_KEY, id)
  }
  return id
}

export function trackEvent (
  eventType: EventType,
  eventName: string,
  properties?: Record<string, unknown>
): void {
  queue.push({
    event_type: eventType,
    event_name: eventName,
    session_id: getOrCreateSessionId(),
    properties
  })
}

function flushBeacon (): void {
  while (queue.length > 0) {
    const batch = queue.splice(0, 50)
    try {
      navigator.sendBeacon(
        BATCH_ENDPOINT,
        new Blob([JSON.stringify({ events: batch })], { type: 'application/json' })
      )
    } catch {
      // sendBeacon may fail in some environments
      break
    }
  }
}

function flushFetch (): void {
  if (queue.length === 0) return
  const batch = queue.splice(0, 50)
  fetch(BATCH_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ events: batch }),
    keepalive: true
  }).catch(() => { /* telemetry failures are non-critical */ })
}

export function startAnalyticsCollector (): void {
  if (initialized) return
  initialized = true

  trackEvent('session_start', 'app_loaded')
  setInterval(flushFetch, FLUSH_INTERVAL_MS)
  window.addEventListener('pagehide', flushBeacon, { once: true })
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'hidden') flushBeacon()
  })
}
