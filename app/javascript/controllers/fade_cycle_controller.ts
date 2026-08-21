import { Controller } from '@hotwired/stimulus'

// Fading text-fragment cycler (TradeAtmosphere / TimelineGap port).
// Fragments come from a JSON array value; show/fade durations per instance.
export default class extends Controller {
  static targets = ['text']
  static values = {
    fragments: Array,
    showMs: { type: Number, default: 3500 },
    fadeMs: { type: Number, default: 1500 }
  }

  declare readonly textTarget: HTMLElement
  declare readonly fragmentsValue: string[]
  declare readonly showMsValue: number
  declare readonly fadeMsValue: number

  private index = 0
  private timer: number | null = null

  connect (): void {
    this.textTarget.style.transition = `opacity ${this.fadeMsValue / 1000}s ease`
    this.cycle()
  }

  disconnect (): void {
    if (this.timer !== null) window.clearTimeout(this.timer)
  }

  private cycle (): void {
    this.textTarget.textContent = this.fragmentsValue[this.index] || ''
    this.textTarget.style.opacity = '1'
    this.timer = window.setTimeout(() => {
      this.textTarget.style.opacity = '0'
      this.timer = window.setTimeout(() => {
        this.index = (this.index + 1) % this.fragmentsValue.length
        this.cycle()
      }, this.fadeMsValue)
    }, this.showMsValue)
  }
}
