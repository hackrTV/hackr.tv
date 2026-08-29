import { Controller } from '@hotwired/stimulus'

// Terminal typing effect for world-feed lines (WorldFeedPage.tsx port):
// 16ms per character, then a random 150–450ms pause before the next line.
// A module-level promise chain keeps lines strictly sequential — initial
// render and turbo-stream appends share the same queue. Each connect also
// trims the container to the SPA's 50-line cap and refreshes the footer
// "events loaded" counter.
const TYPING_SPEED_MS = 16
const MAX_LINES = 50

let queue: Promise<void> = Promise.resolve()

export default class extends Controller<HTMLElement> {
  static targets = ['text']
  static values = { text: String }

  declare readonly textTarget: HTMLElement
  declare readonly textValue: string

  private disconnected = false

  connect (): void {
    this.trim()
    document.getElementById('feed-empty')?.remove()
    queue = queue.then(() => this.type()).then(() => this.pause())
  }

  disconnect (): void {
    this.disconnected = true
  }

  private type (): Promise<void> {
    return new Promise(resolve => {
      const text = this.textValue
      let i = 0
      const cursor = document.createElement('span')
      cursor.className = 'feed-cursor'
      cursor.textContent = '_'
      this.element.appendChild(cursor)

      const tick = (): void => {
        if (this.disconnected) {
          cursor.remove()
          resolve()
          return
        }
        i += 1
        this.textTarget.textContent = text.substring(0, i)
        if (i >= text.length) {
          cursor.remove()
          this.updateCount()
          resolve()
        } else {
          window.setTimeout(tick, TYPING_SPEED_MS)
        }
      }
      tick()
    })
  }

  private pause (): Promise<void> {
    return new Promise(resolve => {
      window.setTimeout(resolve, 150 + Math.random() * 300)
    })
  }

  private trim (): void {
    const container = this.element.parentElement
    if (!container) return
    while (container.children.length > MAX_LINES) {
      container.firstElementChild?.remove()
    }
  }

  private updateCount (): void {
    const container = this.element.parentElement
    const label = document.querySelector('[data-feed-count-target="label"]')
    if (container && label) {
      label.textContent = `${container.children.length} events loaded`
    }
    this.element.scrollIntoView({ block: 'nearest' })
  }
}
