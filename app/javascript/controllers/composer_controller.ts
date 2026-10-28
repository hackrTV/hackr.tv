import { Controller } from '@hotwired/stimulus'

// The WIRE prompt bar (wire/_composer): "{remaining} / {limit}" counter
// with warning (<20 left) and over-limit states, submit disabled when
// empty/over, the single-line textarea grows with its text (the CSS
// max-height caps it). Enter sends; coarse pointers (soft keyboards)
// keep Enter as newline and send with the button; an Enter the emote
// picker already consumed (defaultPrevented: it picked) never sends.
// A thread prompt that wire-row re-aimed at a reply (hidden parent +
// placeholder) goes back to its root after a successful send.
export default class extends Controller<HTMLFormElement> {
  static targets = ['input', 'count', 'submit', 'parent']
  static values = { limit: Number }

  declare readonly inputTarget: HTMLTextAreaElement
  declare readonly countTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly parentTarget: HTMLInputElement
  declare readonly hasParentTarget: boolean
  declare readonly limitValue: number

  private defaultParent = ''

  connect (): void {
    if (this.hasParentTarget) this.defaultParent = this.parentTarget.value
    this.update()
  }

  update (): void {
    const length = this.inputTarget.value.length
    const remaining = this.limitValue - length
    this.countTarget.textContent = `${remaining} / ${this.limitValue}`
    this.countTarget.classList.toggle('over-limit', remaining < 0)
    this.countTarget.classList.toggle('warning', remaining >= 0 && remaining < 20)
    this.submitTarget.disabled = remaining < 0 || this.inputTarget.value.trim() === ''
    this.grow()
  }

  keydown (event: KeyboardEvent): void {
    if (event.defaultPrevented || event.isComposing) return
    if (event.key === 'Escape') {
      this.inputTarget.blur()
      return
    }
    if (event.key !== 'Enter') return
    if (event.metaKey || event.ctrlKey) {
      event.preventDefault()
      this.send()
      return
    }
    if (event.shiftKey) return
    if (typeof window.matchMedia === 'function' && window.matchMedia('(pointer: coarse)').matches) return
    event.preventDefault()
    this.send()
  }

  submitted (event: Event): void {
    const detail = (event as CustomEvent).detail
    if (detail?.success) {
      this.inputTarget.value = ''
      this.inputTarget.style.height = ''
      this.inputTarget.placeholder = this.inputTarget.dataset.defaultPlaceholder ?? this.inputTarget.placeholder
      if (this.hasParentTarget) this.parentTarget.value = this.defaultParent
      this.update()
    }
  }

  private send (): void {
    if (this.submitTarget.disabled) return
    this.element.requestSubmit()
  }

  private grow (): void {
    const field = this.inputTarget
    field.style.height = 'auto'
    if (field.scrollHeight > 0) field.style.height = `${field.scrollHeight}px`
  }
}
