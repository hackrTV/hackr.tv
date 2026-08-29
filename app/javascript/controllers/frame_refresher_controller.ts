import { Controller } from '@hotwired/stimulus'

interface FrameElementLike extends HTMLElement {
  src: string | null
  reload: () => void
}

// One-shot refresh pulse: the tactical command response appends an
// element with this controller to #tactical-refresh-bus; on connect it
// reloads every VISIBLE, already-loaded frame marked
// data-tactical-refresh (active status tab, open panel) and removes
// itself — the SPA's dataRefreshToken refetch equivalent. Hidden loaded
// frames stay stale until re-shown, matching the SPA (it refetched only
// the active tab per token bump).
export default class extends Controller<HTMLElement> {
  connect (): void {
    document.querySelectorAll<FrameElementLike>('turbo-frame[data-tactical-refresh]').forEach(frame => {
      if (frame.offsetParent !== null && frame.src) frame.reload()
    })
    this.element.remove()
  }
}
