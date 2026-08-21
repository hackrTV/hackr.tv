import { Controller } from '@hotwired/stimulus'

// Mobile nav overlay (replaces MobileMenuContext). Toggle button opens;
// the [X], a tap on the dimmed backdrop, or choosing a link closes.
export default class extends Controller {
  static targets = ['overlay']

  declare readonly overlayTarget: HTMLElement

  open (): void {
    this.overlayTarget.classList.add('open')
  }

  close (): void {
    this.overlayTarget.classList.remove('open')
  }

  backdropClose (event: MouseEvent): void {
    if (event.target === this.overlayTarget) this.close()
  }

  maybeClose (event: MouseEvent): void {
    if ((event.target as HTMLElement).closest('a')) this.close()
  }
}
