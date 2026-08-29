import { Controller } from '@hotwired/stimulus'

// ScheduledStreamBanner.tsx countdown: ticks to the deadline; once
// reached, swaps to the STARTING SOON! state with the sweep animation.
export default class extends Controller<HTMLElement> {
  static targets = ['label', 'sweep']
  static values = { deadline: String }

  declare readonly labelTarget: HTMLElement
  declare readonly sweepTarget: HTMLElement
  declare readonly deadlineValue: string

  private timer: number | null = null

  connect (): void {
    this.tick()
    this.timer = window.setInterval(() => this.tick(), 1000)
  }

  disconnect (): void {
    if (this.timer !== null) window.clearInterval(this.timer)
  }

  private tick (): void {
    const remaining = new Date(this.deadlineValue).getTime() - Date.now()
    if (remaining <= 0) {
      this.labelTarget.textContent = 'STARTING SOON!'
      this.labelTarget.classList.add('scheduled-banner-soon')
      this.sweepTarget.hidden = false
      if (this.timer !== null) window.clearInterval(this.timer)
      return
    }

    const days = Math.floor(remaining / 86400000)
    const hours = Math.floor((remaining % 86400000) / 3600000)
    const minutes = Math.floor((remaining % 3600000) / 60000)
    const seconds = Math.floor((remaining % 60000) / 1000)
    const parts = days > 0 ? [`${days}d`, `${hours}h`, `${minutes}m`] : [`${hours}h`, `${minutes}m`, `${seconds}s`]
    this.labelTarget.textContent = `T-MINUS ${parts.join(' ')}`
  }
}
