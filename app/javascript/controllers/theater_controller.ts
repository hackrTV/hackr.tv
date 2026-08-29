import { Controller } from '@hotwired/stimulus'

// LiveStreamEmbed.tsx theater mode: full-screen overlay class toggle;
// Escape exits.
export default class extends Controller<HTMLElement> {
  static targets = ['button']

  declare readonly buttonTarget: HTMLElement

  private escHandler = (event: KeyboardEvent): void => {
    if (event.key === 'Escape' && this.element.classList.contains('theater-mode')) this.toggle()
  }

  connect (): void {
    document.addEventListener('keydown', this.escHandler)
  }

  disconnect (): void {
    document.removeEventListener('keydown', this.escHandler)
    document.body.classList.remove('theater-open')
  }

  toggle (): void {
    const on = this.element.classList.toggle('theater-mode')
    document.body.classList.toggle('theater-open', on)
    this.buttonTarget.textContent = on ? '[x] EXIT' : '[=] THEATER'
  }
}
