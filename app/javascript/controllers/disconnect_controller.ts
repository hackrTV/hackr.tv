import { Controller } from '@hotwired/stimulus'

// Mirrors the SPA disconnect flow: confirm, DELETE the session via the
// existing JSON endpoint, hard-load the login page. Replaced by an HTML
// session route in Phase 2.
export default class extends Controller {
  async logout (event: Event): Promise<void> {
    event.preventDefault()
    if (!confirm('Disconnect from THE PULSE GRID?')) return
    try {
      await fetch('/api/grid/disconnect', { method: 'DELETE' })
    } finally {
      window.location.href = '/grid/login'
    }
  }
}
