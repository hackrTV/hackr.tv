import { Controller } from '@hotwired/stimulus'

// Bridges DefaultLayout's bottom [≡] MENU button (rendered outside the
// nav's mobile-menu controller scope) to the overlay via a window event.
export default class extends Controller {
  open (): void {
    window.dispatchEvent(new CustomEvent('mobile-menu:open'))
  }
}
