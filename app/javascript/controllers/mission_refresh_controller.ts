import { Controller } from '@hotwired/stimulus'

interface FrameElementLike extends HTMLElement {
  src: string | null
  reload: () => void
}

// MissionsPage refetch-on-completion port: the mission toast dispatches
// grid:mission_completed (mission-signal controller); this reloads the
// missions frame so progress/status re-render live.
export default class extends Controller<HTMLElement> {
  private handler = (): void => {
    const frame = this.element as unknown as FrameElementLike
    if (!frame.src) frame.src = window.location.pathname
    else frame.reload()
  }

  connect (): void {
    window.addEventListener('grid:mission_completed', this.handler)
  }

  disconnect (): void {
    window.removeEventListener('grid:mission_completed', this.handler)
  }
}
