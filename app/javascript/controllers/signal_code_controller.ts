import { Controller } from '@hotwired/stimulus'

// Easter egg ported from FmLandingPage.tsx: three clicks on the
// "SIGNAL INCOMING" title within rolling 600ms windows opens a code
// prompt; a valid transmission code reveals the locked coming-soon cards
// (the server renders cards beyond the first four with `hidden` and the
// .fm-soon-card-link--locked marker class).
const VALID_CODES = ['9915', '09092115', '992115', '9092115', '090915']

export default class extends Controller {
  static targets = ['modal', 'input', 'error']

  declare readonly modalTarget: HTMLElement
  declare readonly inputTarget: HTMLInputElement
  declare readonly errorTarget: HTMLElement

  private clickCount = 0
  private clickTimer: ReturnType<typeof setTimeout> | null = null
  private errorTimer: ReturnType<typeof setTimeout> | null = null

  disconnect (): void {
    if (this.clickTimer) clearTimeout(this.clickTimer)
    if (this.errorTimer) clearTimeout(this.errorTimer)
  }

  signalClicked (): void {
    this.clickCount++
    if (this.clickTimer) clearTimeout(this.clickTimer)
    if (this.clickCount >= 3) {
      this.clickCount = 0
      this.open()
    } else {
      this.clickTimer = setTimeout(() => { this.clickCount = 0 }, 600)
    }
  }

  // A click on the backdrop targets the overlay element itself; clicks
  // inside the code box target its children (same as dialog_controller).
  backdropClicked (event: MouseEvent): void {
    if (event.target === this.modalTarget) this.close()
  }

  submit (): void {
    if (VALID_CODES.includes(this.inputTarget.value.trim())) {
      this.close()
      this.unlock()
    } else {
      this.errorTarget.hidden = false
      if (this.errorTimer) clearTimeout(this.errorTimer)
      this.errorTimer = setTimeout(() => { this.errorTarget.hidden = true }, 2000)
    }
  }

  close (): void {
    this.modalTarget.hidden = true
  }

  private open (): void {
    this.inputTarget.value = ''
    this.errorTarget.hidden = true
    this.modalTarget.hidden = false
    this.inputTarget.focus()
  }

  private unlock (): void {
    const locked = this.element.querySelectorAll<HTMLElement>('.fm-soon-card-link--locked')
    for (const link of Array.from(locked)) {
      link.hidden = false
    }
  }
}
