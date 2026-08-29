import { Controller } from '@hotwired/stimulus'

// Click-open dropdown for a desktop nav <li>. Clicking anywhere inside the
// li toggles (so choosing a link also closes, matching HeaderMenu.tsx);
// mousedown outside closes.
export default class extends Controller {
  static targets = ['panel']

  declare readonly panelTarget: HTMLElement
  declare readonly hasPanelTarget: boolean

  private outsideHandler = (event: MouseEvent): void => {
    if (!this.element.contains(event.target as Node)) this.close()
  }

  connect (): void {
    document.addEventListener('mousedown', this.outsideHandler)
  }

  disconnect (): void {
    document.removeEventListener('mousedown', this.outsideHandler)
  }

  toggle (): void {
    if (this.hasPanelTarget) this.panelTarget.classList.toggle('open')
  }

  close (): void {
    if (this.hasPanelTarget) this.panelTarget.classList.remove('open')
  }
}
