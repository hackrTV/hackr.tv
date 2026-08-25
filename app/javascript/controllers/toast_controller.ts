import { Controller } from '@hotwired/stimulus'

// AchievementToastContainer.tsx port: toasts auto-dismiss after 6s, the
// stack is capped at 5 (oldest dropped), click dismisses immediately.
const AUTO_DISMISS_MS = 6000
const MAX_STACK = 5

export default class extends Controller<HTMLElement> {
  private timer: number | null = null

  connect (): void {
    const region = this.element.parentElement
    if (region) {
      const toasts = region.querySelectorAll('.toast')
      for (let i = 0; i < toasts.length - MAX_STACK; i++) toasts[i].remove()
    }
    this.timer = window.setTimeout(() => this.dismiss(), AUTO_DISMISS_MS)
  }

  disconnect (): void {
    if (this.timer !== null) window.clearTimeout(this.timer)
  }

  dismiss (): void {
    this.element.remove()
  }
}
