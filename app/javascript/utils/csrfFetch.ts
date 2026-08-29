// CSRF + XHR headers for raw fetch() calls made from Hotwire pages
// (Stimulus controllers hitting JSON endpoints). Same behavior as the
// inline patch in entrypoints/application.tsx — the SPA keeps its own
// copy until Phase 7 removes it. Turbo form submissions handle CSRF
// themselves; this covers everything else.
export function installCsrfFetch (): void {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  if (!csrfToken) return

  const originalFetch = window.fetch.bind(window)
  window.fetch = async (input, init = {}) => {
    const method = (init.method || 'GET').toUpperCase()
    if (method !== 'GET' && method !== 'HEAD') {
      const headers = new Headers(init.headers || {})
      if (!headers.has('X-CSRF-Token')) {
        headers.set('X-CSRF-Token', csrfToken)
      }
      if (!headers.has('X-Requested-With')) {
        headers.set('X-Requested-With', 'XMLHttpRequest')
      }
      init = { ...init, headers }
    }
    return originalFetch(input, init)
  }
}
