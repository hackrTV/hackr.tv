import { Controller } from '@hotwired/stimulus'

// Rides the mission-complete toast partial: dispatches the SPA's
// grid:mission_completed CustomEvent once on insert (mission-refresh
// listens on the missions page), then removes itself.
export default class extends Controller<HTMLElement> {
  connect (): void {
    window.dispatchEvent(new CustomEvent('grid:mission_completed'))
    this.element.remove()
  }
}
