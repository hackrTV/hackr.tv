import { Controller } from '@hotwired/stimulus'

// PacketInput.tsx port: "{length}/{limit}" counter with warning (>90%)
// and over-limit states, submit disabled when empty/over, input cleared
// and refocused after a successful turbo submit, and a slow-mode
// cooldown that counts down on the TX button. Server errors replace the
// error slot (a target of this controller); errorTargetConnected reads
// the slot's wait_seconds to start server-directed cooldowns.
export default class extends Controller<HTMLElement> {
  static targets = ['input', 'count', 'submit', 'error']
  static values = { slowMode: Number, limit: Number }

  declare readonly inputTarget: HTMLInputElement
  declare readonly countTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly slowModeValue: number
  declare readonly limitValue: number

  private cooldownTimer: number | null = null
  private cooldownRemaining = 0
  private baseDisabled = false

  connect (): void {
    this.baseDisabled = this.inputTarget.disabled
    this.update()
  }

  disconnect (): void {
    this.stopCooldown()
  }

  update (): void {
    const length = this.inputTarget.value.length
    const over = length > this.limitValue
    const near = !over && length > this.limitValue * 0.9
    this.countTarget.textContent = `${length}/${this.limitValue}`
    this.countTarget.classList.toggle('over-limit', over)
    this.countTarget.classList.toggle('warning', near)
    this.inputTarget.closest('.packet-input-field')?.classList.toggle('packet-input-field--over', over)
    this.refreshDisabled()
  }

  submitted (event: Event): void {
    const detail = (event as CustomEvent).detail
    if (detail?.success) {
      this.inputTarget.value = ''
      if (this.slowModeValue > 0) this.startCooldown(this.slowModeValue)
      this.update()
      this.inputTarget.focus()
    }
  }

  errorTargetConnected (el: HTMLElement): void {
    const wait = Number(el.dataset.waitSeconds ?? 0)
    if (wait > 0) this.startCooldown(wait)
  }

  private startCooldown (seconds: number): void {
    this.stopCooldown()
    this.cooldownRemaining = seconds
    this.render()
    this.cooldownTimer = window.setInterval(() => {
      this.cooldownRemaining -= 1
      if (this.cooldownRemaining <= 0) this.stopCooldown()
      this.render()
    }, 1000)
  }

  private stopCooldown (): void {
    if (this.cooldownTimer !== null) {
      window.clearInterval(this.cooldownTimer)
      this.cooldownTimer = null
    }
    this.cooldownRemaining = 0
  }

  private render (): void {
    const cooling = this.cooldownRemaining > 0
    this.submitTarget.textContent = cooling ? `${this.cooldownRemaining}s` : 'TX'
    this.submitTarget.classList.toggle('packet-input-send--cooldown', cooling)
    this.refreshDisabled()
  }

  private refreshDisabled (): void {
    const cooling = this.cooldownRemaining > 0
    const length = this.inputTarget.value.length
    const over = length > this.limitValue
    this.inputTarget.disabled = this.baseDisabled || cooling
    this.submitTarget.disabled = this.baseDisabled || cooling || over || this.inputTarget.value.trim() === ''
  }
}
