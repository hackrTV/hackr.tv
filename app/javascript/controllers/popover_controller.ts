import { Controller, type ActionEvent } from '@hotwired/stimulus'
import { jumpToPacket } from '~/utils/packetJump'

// Frame-backed popovers for the /uplink shell: the operative record card
// (uplink-popover, in the channel pane), the operator menu
// (uplink-modmenu, a grid child so it stacks over the mobile drawers) and
// the pinned packets panel (uplink-pins, in the channel pane under the
// header's [◆]).
// A trigger's click loads the URL in its data-popover-url-param into the
// frame named by its data-popover-frame-param (the first frame target
// when absent) and parks the frame under the trigger — left edges
// aligned, or right edges when data-popover-align-param is "end" (the
// […] menus hang leftwards from their button) — clamped to the frame's
// offset parent, flipping above when there's no room below. One
// popover is open at a time; opening another closes the first. The
// loaded content's [tabindex="-1"] root takes focus. Escape and the
// content's [x] close it and hand focus back to the trigger; an outside
// mousedown, a second click on the same trigger, a finished form submit
// inside the frame (the menu's actions reply with a stream — unless the
// form carries data-popover-stay: the pins panel's UNPIN replies by
// re-rendering the panel's list, so it stays) and leaving the page
// (turbo:before-cache / disconnect) close it too. A pins-panel row
// (jump, id param) scrolls to that packet and closes when the log has
// it, swallowing the row's own visit; otherwise the link goes through
// to /uplink?around=<id>, which opens the log on it. A modified
// click (ctrl/meta/shift/alt, middle) falls through to the trigger's
// href — the author link's WIRE profile. Roster rows carry no alias and
// open the card never, the menu only for operators (members controller).
// The dock/popout render the same triggers without this controller, so
// their action is inert: links navigate, buttons stay CSS-hidden.

const GAP_PX = 4
const MARGIN_PX = 8

export default class extends Controller<HTMLElement> {
  static targets = ['frame']

  declare readonly frameTargets: HTMLElement[]

  private anchor: HTMLElement | null = null
  private frame: HTMLElement | null = null
  private align: 'start' | 'end' = 'start'

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
    const frame = this.frameNamed(event.params?.frame)
    if (!frame) return
    event.preventDefault()
    const anchor = event.currentTarget as HTMLElement
    if (anchor === this.anchor && frame === this.frame && !frame.hidden) {
      this.close()
      return
    }
    this.close()
    this.anchor = anchor
    this.frame = frame
    this.align = event.params?.align === 'end' ? 'end' : 'start'
    frame.innerHTML = ''
    frame.removeAttribute('src') // same trigger again: a fresh src always loads
    frame.hidden = false
    frame.setAttribute('src', url)
    this.place()
  }

  // turbo:frame-load bubbles from every frame in the shell (the log's
  // reconnect reload too): only the open popover's own load places + focuses.
  loaded (event: Event): void {
    const frame = this.frame
    if (!frame || event.target !== frame || frame.hidden) return
    this.place()
    frame.querySelector<HTMLElement>('[tabindex="-1"]')?.focus()
  }

  // A form inside the open frame finished submitting: its reply is a
  // stream (toast, packet replace), so the popover's job is done — unless
  // the form asked to stay (the reply re-renders the frame's content).
  submitted (event: Event): void {
    if (!this.frame || !(event.target instanceof Element) || !this.frame.contains(event.target)) return
    if (event.target.closest('[data-popover-stay]')) return
    this.dismiss()
  }

  // A pins-panel row: scroll to + flash the packet when it is in the log
  // and close the panel, swallowing the link's visit. A pin beyond the
  // loaded history (or a modified click) lets the link go.
  jump (event: MouseEvent & ActionEvent): void {
    const id: unknown = event.params?.id
    if (typeof id !== 'string' && typeof id !== 'number') return
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    if (!jumpToPacket(id)) return
    event.preventDefault()
    this.close()
  }

  dismiss (): void {
    const anchor = this.anchor
    this.close()
    if (anchor?.isConnected) anchor.focus()
  }

  keydown (event: KeyboardEvent): void {
    if (event.key !== 'Escape' || event.defaultPrevented || !this.isOpen) return
    event.preventDefault()
    this.dismiss()
  }

  outside (event: Event): void {
    if (!this.isOpen || !(event.target instanceof Node)) return
    if (this.frame?.contains(event.target) || this.anchor?.contains(event.target)) return
    this.close()
  }

  close = (): void => {
    const frame = this.frame
    this.anchor = null
    this.frame = null
    if (!frame || frame.hidden) return
    frame.hidden = true
    frame.removeAttribute('src')
    frame.innerHTML = ''
  }

  private get isOpen (): boolean {
    return this.frame !== null && !this.frame.hidden
  }

  private frameNamed (name: unknown): HTMLElement | null {
    if (typeof name === 'string' && name !== '') return this.frameTargets.find(frame => frame.id === name) ?? null
    return this.frameTargets[0] ?? null
  }

  // Coordinates are relative to the frame's offset parent (the pane the
  // frame is absolutely positioned in); before the content loads the
  // frame has its CSS width and no height, so the vertical clamp settles
  // on turbo:frame-load.
  private place (): void {
    const anchor = this.anchor
    const frame = this.frame
    if (!anchor || !frame) return
    const parent = frame.offsetParent instanceof HTMLElement ? frame.offsetParent : this.element
    const box = parent.getBoundingClientRect()
    const at = anchor.getBoundingClientRect()
    const width = frame.offsetWidth
    const height = frame.offsetHeight
    let left = (this.align === 'end' ? at.right - width : at.left) - box.left
    let top = at.bottom - box.top + GAP_PX
    if (left + width > parent.clientWidth - MARGIN_PX) left = parent.clientWidth - width - MARGIN_PX
    if (top + height > parent.clientHeight - MARGIN_PX) top = at.top - box.top - height - GAP_PX // flip above
    frame.style.left = `${Math.max(MARGIN_PX, Math.round(left))}px`
    frame.style.top = `${Math.max(MARGIN_PX, Math.round(top))}px`
  }
}
