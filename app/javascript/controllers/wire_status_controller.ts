import { Controller } from '@hotwired/stimulus'

// LIVE/OFFLINE badge for the wire feed — mirrors the SPA's connection
// indicator by watching the page's <turbo-cable-stream-source> element,
// which toggles a "connected" attribute.
export default class extends Controller<HTMLElement> {
  static targets = ['badge']

  declare readonly badgeTarget: HTMLElement

  private observer: MutationObserver | null = null

  connect (): void {
    const source = document.querySelector('turbo-cable-stream-source')
    if (!source) {
      this.render(false)
      return
    }
    this.observer = new MutationObserver(() => this.render(source.hasAttribute('connected')))
    this.observer.observe(source, { attributes: true, attributeFilter: ['connected'] })
    this.render(source.hasAttribute('connected'))
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = null
  }

  private render (connected: boolean): void {
    this.badgeTarget.textContent = connected ? '● LIVE' : '○ OFFLINE'
    this.badgeTarget.className = connected ? 'status-connected' : 'status-disconnected'
  }
}
