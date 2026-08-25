import { Controller } from '@hotwired/stimulus'

// Display/edit swap for the playlist info card (PlaylistDetailPage's
// isEditing state). Cancel just re-shows the server-rendered display —
// the form's unsaved values are discarded on the next render anyway.
export default class extends Controller {
  static targets = ['display', 'form']

  declare readonly displayTarget: HTMLElement
  declare readonly formTarget: HTMLElement

  edit (): void {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
  }

  cancel (): void {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
