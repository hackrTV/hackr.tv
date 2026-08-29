import { Controller } from '@hotwired/stimulus'

// GridTacticalPage keyboard shortcut: Tab focuses the command input
// from anywhere on the tactical surface.
export default class extends Controller<HTMLElement> {
  private keydown = (event: KeyboardEvent): void => {
    if (event.key !== 'Tab') return
    const input = this.element.querySelector<HTMLInputElement>('.grid-command-input')
    if (!input || document.activeElement === input) return
    event.preventDefault()
    input.focus()
  }

  connect (): void {
    document.addEventListener('keydown', this.keydown)
  }

  disconnect (): void {
    document.removeEventListener('keydown', this.keydown)
  }
}
