import { Controller } from '@hotwired/stimulus'

// Re-renders the element's datetime attribute as client-local HH:MM
// (24h). Server-rendered timestamps are app-TZ fallbacks; broadcast
// partials can't know the viewer's timezone.
export default class extends Controller<HTMLElement> {
  connect (): void {
    const stamp = this.element.getAttribute('datetime')
    if (!stamp) return
    const date = new Date(stamp)
    if (Number.isNaN(date.getTime())) return
    this.element.textContent = date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false
    })
  }
}
