import { Controller, type ActionEvent } from '@hotwired/stimulus'

// Frame-backed popover for the /uplink shell (operative record card).
// Clicking a packet author loads the URL in its data-popover-url-param
// (GET /uplink/profiles/:alias) into the uplink-popover turbo-frame and
// parks the frame under the click, clamped to the pane it lives in (its
// offset parent, .uplink-main), flipping above when there's no room
// below. The card takes focus once loaded. Escape and the card's [x]
// close it and hand focus back to the author link; an outside mousedown,
// a second click on the same author, and leaving the page
// (turbo:before-cache / disconnect) close it too. A modified click
// (ctrl/meta/shift/alt, middle) falls through to the link's href — the
// WIRE profile. Roster rows never open it: they carry no alias. The
// dock/popout render the same author links without this controller, so
// their action is inert and the link navigates.

const GAP_PX = 4
const MARGIN_PX = 8

export default class extends Controller<HTMLElement> {
  static targets = ['frame']

  declare readonly frameTarget: HTMLElement

  private anchor: HTMLElement | null = null

  connect (): void {
    document.addEventListener('turbo:before-cache', this.close)
  }

  disconnect (): void {
    document.removeEventListener('turbo:before-cache', this.close)
    this.close()
  }

  open (event: MouseEvent & ActionEvent): void {
    const url: unknown = event.params?.url
    if (typeof url !== 'string' || url === '') return
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    event.preventDefault()
    const anchor = event.currentTarget as HTMLElement
    if (anchor === this.anchor && !this.frameTarget.hidden) {
      this.close()
      return
    }
    this.anchor = anchor
    const frame = this.frameTarget
    frame.innerHTML = ''
    frame.removeAttribute('src') // same author again: a fresh src always loads
    frame.hidden = false
    frame.setAttribute('src', url)
    this.place()
  }

  // turbo:frame-load bubbles from every frame in the shell (the log's
  // reconnect reload too): only the popover's own load places + focuses.
  loaded (event: Event): void {
    if (event.target !== this.frameTarget || this.frameTarget.hidden) return
    this.place()
    this.frameTarget.querySelector<HTMLElement>('.uplink-popover')?.focus()
  }

  dismiss (): void {
    const anchor = this.anchor
    this.close()
    if (anchor?.isConnected) anchor.focus()
  }

  keydown (event: KeyboardEvent): void {
    if (event.key !== 'Escape' || event.defaultPrevented || this.frameTarget.hidden) return
    event.preventDefault()
    this.dismiss()
  }

  outside (event: Event): void {
    if (this.frameTarget.hidden || !(event.target instanceof Node)) return
    if (this.frameTarget.contains(event.target) || this.anchor?.contains(event.target)) return
    this.close()
  }

  close = (): void => {
    const frame = this.frameTarget
    this.anchor = null
    if (frame.hidden) return
    frame.hidden = true
    frame.removeAttribute('src')
    frame.innerHTML = ''
  }

  // Coordinates are relative to the frame's offset parent (the pane the
  // frame is absolutely positioned in); before the card loads the frame
  // has its CSS width and no height, so the vertical clamp settles on
  // turbo:frame-load.
  private place (): void {
    const anchor = this.anchor
    if (!anchor) return
    const frame = this.frameTarget
    const parent = frame.offsetParent instanceof HTMLElement ? frame.offsetParent : this.element
    const box = parent.getBoundingClientRect()
    const at = anchor.getBoundingClientRect()
    const width = frame.offsetWidth
    const height = frame.offsetHeight
    let left = at.left - box.left
    let top = at.bottom - box.top + GAP_PX
    if (left + width > parent.clientWidth - MARGIN_PX) left = parent.clientWidth - width - MARGIN_PX
    if (top + height > parent.clientHeight - MARGIN_PX) top = at.top - box.top - height - GAP_PX // flip above
    frame.style.left = `${Math.max(MARGIN_PX, Math.round(left))}px`
    frame.style.top = `${Math.max(MARGIN_PX, Math.round(top))}px`
  }
}
