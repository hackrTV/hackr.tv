import { Controller } from '@hotwired/stimulus'

// Minimal <dialog> wrapper: open/close actions + backdrop click closes.
export default class extends Controller {
  static targets = ['dialog']

  declare readonly dialogTarget: HTMLDialogElement

  connect (): void {
    this.dialogTarget.addEventListener('click', this.onBackdropClick)
  }

  disconnect (): void {
    this.dialogTarget.removeEventListener('click', this.onBackdropClick)
  }

  open (): void {
    this.dialogTarget.showModal()
  }

  close (): void {
    this.dialogTarget.close()
  }

  // A click on the backdrop targets the <dialog> element itself; clicks
  // inside the panel target its children.
  private readonly onBackdropClick = (event: MouseEvent): void => {
    if (event.target === this.dialogTarget) this.close()
  }
}
