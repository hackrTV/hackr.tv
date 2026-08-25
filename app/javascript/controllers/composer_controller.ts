import { Controller } from '@hotwired/stimulus'

// PulseComposer.tsx port: "{remaining} / {limit}" counter with warning
// (<20 left) and over-limit states, submit disabled when empty/over,
// Cmd/Ctrl+Enter submits, form resets after a successful turbo submit.
export default class extends Controller<HTMLFormElement> {
  static targets = ['input', 'count', 'submit']
  static values = { limit: Number }

  declare readonly inputTarget: HTMLTextAreaElement
  declare readonly countTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly limitValue: number

  connect (): void {
    this.update()
  }

  update (): void {
    const length = this.inputTarget.value.length
    const remaining = this.limitValue - length
    this.countTarget.textContent = `${remaining} / ${this.limitValue}`
    this.countTarget.classList.toggle('over-limit', remaining < 0)
    this.countTarget.classList.toggle('warning', remaining >= 0 && remaining < 20)
    this.submitTarget.disabled = remaining < 0 || this.inputTarget.value.trim() === ''
  }

  keydown (event: KeyboardEvent): void {
    if (event.key === 'Enter' && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  submitted (event: Event): void {
    const detail = (event as CustomEvent).detail
    if (detail?.success) {
      this.inputTarget.value = ''
      this.update()
    }
  }
}
