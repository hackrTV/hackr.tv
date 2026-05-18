// Frontend error reporter. Captures unhandled JS errors, unhandled Promise
// rejections, and React ErrorBoundary catches. Reports to /api/error_report.
//
// Usage:
//   import { initErrorReporter, reportError } from '~/services/errorReporter'
//   initErrorReporter()                    // once, in application.tsx
//   reportError(error, errorInfo)          // from ErrorBoundary.componentDidCatch

const ENDPOINT = '/api/error_report'
const MAX_IDENTICAL_REPORTS = 5

interface ErrorReport {
  message: string
  source?: string
  lineno?: number
  colno?: number
  stack?: string
  type: 'global' | 'unhandled_rejection' | 'boundary'
  url: string
}

const recentFingerprints = new Map<string, number>()

function fingerprint (message: string, source?: string, lineno?: number): string {
  return `${message}:${source || ''}:${lineno || 0}`
}

function shouldReport (fp: string): boolean {
  const count = recentFingerprints.get(fp) || 0
  if (count >= MAX_IDENTICAL_REPORTS) return false
  recentFingerprints.set(fp, count + 1)

  // Cap map size to prevent unbounded growth in long sessions
  if (recentFingerprints.size > 100) {
    const firstKey = recentFingerprints.keys().next().value
    if (firstKey !== undefined) recentFingerprints.delete(firstKey)
  }

  return true
}

function send (report: ErrorReport): void {
  const fp = fingerprint(report.message, report.source, report.lineno)
  if (!shouldReport(fp)) return

  try {
    fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(report),
      keepalive: true
    }).catch(() => {
      // Silently ignore — error reporting must never cause errors
    })
  } catch {
    // fetch itself may throw in some environments
  }
}

export function initErrorReporter (): void {
  // Global JS errors
  window.onerror = (message, source, lineno, colno, error) => {
    send({
      message: String(message),
      source,
      lineno: lineno || undefined,
      colno: colno || undefined,
      stack: error?.stack,
      type: 'global',
      url: window.location.href
    })
    return false // let default handler run
  }

  // Unhandled Promise rejections
  window.addEventListener('unhandledrejection', (event) => {
    const reason = event.reason
    send({
      message: reason?.message || String(reason),
      stack: reason?.stack,
      type: 'unhandled_rejection',
      url: window.location.href
    })
  })
}

// Called from ErrorBoundary.componentDidCatch
export function reportError (error: Error, errorInfo?: { componentStack?: string | null }): void {
  send({
    message: error.message,
    stack: error.stack,
    type: 'boundary',
    url: window.location.href,
    source: errorInfo?.componentStack?.split('\n')[1]?.trim()
  })
}
