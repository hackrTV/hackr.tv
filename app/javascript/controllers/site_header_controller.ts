import { Controller } from '@hotwired/stimulus'

// Publishes the site header's rendered height (nav + .top-notices) as the
// --site-header-h custom property on <html>, so viewport-fixed surfaces
// (.tactical-root) can start below it instead of underneath it. The nav
// wraps to a variable number of rows with login state and viewport width
// and the notices slot grows and shrinks, so no constant works. Without
// ResizeObserver the value is published once on connect.
export default class extends Controller<HTMLElement> {
  private observer?: ResizeObserver

  connect (): void {
    this.publish()
    if (typeof ResizeObserver === 'undefined') return
    this.observer = new ResizeObserver(() => this.publish())
    this.observer.observe(this.element)
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = undefined
  }

  private publish (): void {
    const height = Math.round(this.element.getBoundingClientRect().height)
    document.documentElement.style.setProperty('--site-header-h', `${height}px`)
  }
}
