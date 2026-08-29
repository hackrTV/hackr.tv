import { Controller } from '@hotwired/stimulus'

// Live character counter for the identity bio textarea — same behavior as
// IdentityPage.tsx (count/max readout, red at the cap). The textarea's
// maxlength attribute does the actual truncation.
export default class extends Controller {
  static targets = ['input', 'count']

  declare readonly inputTarget: HTMLTextAreaElement
  declare readonly countTarget: HTMLElement

  connect (): void {
    this.update()
  }

  update (): void {
    const max = this.inputTarget.maxLength
    const length = this.inputTarget.value.length
    this.countTarget.textContent = `${length}/${max}`
    this.countTarget.classList.toggle('at-max', length >= max)
  }
}
