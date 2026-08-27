import { Controller } from '@hotwired/stimulus'

// Connection dot for the /grid page. Watches the per-room
// turbo-cable-stream-source INSIDE this element — the source gets
// swapped on movement, so the whole subtree is observed rather than one
// node (wire-status observes a fixed source and would go stale here).
export default class extends Controller<HTMLElement> {
  static targets = ['dot']

  declare readonly dotTarget: HTMLElement
  declare readonly hasDotTarget: boolean

  private observer: MutationObserver | null = null

  connect (): void {
    this.observer = new MutationObserver(() => this.render())
    this.observer.observe(this.element, {
      subtree: true,
      childList: true,
      attributes: true,
      attributeFilter: ['connected']
    })
    this.render()
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = null
  }

  private render (): void {
    if (!this.hasDotTarget) return
    const source = this.element.querySelector('turbo-cable-stream-source')
    const connected = source?.hasAttribute('connected') ?? false
    this.dotTarget.classList.toggle('grid-status-dot--connected', connected)
    this.dotTarget.title = connected ? 'Connected' : 'Disconnected'
  }
}
