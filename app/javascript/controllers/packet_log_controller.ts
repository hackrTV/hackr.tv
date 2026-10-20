import { Controller } from '@hotwired/stimulus'

// PacketList.tsx pin-to-bottom port, shared with the /grid terminal and
// breach log: stay pinned while the user is within 50px of the bottom;
// once they scroll up to read history, appended entries stop yanking the
// viewport. Turbo Stream appends surface as childList mutations. An
// optional cap value trims the oldest children on append (the grid
// terminal's 500-line cap; 0 = uncapped). A frame reload replaces this
// element wholesale, so the fresh instance re-pins on connect.
//
// Uplink shell additions (opt-in / inert elsewhere):
//   group=true — Discord-style consecutive-author grouping: a .packet
//     whose previous sibling is a .packet with the same data-author-key
//     inside a 5-minute window gets .packet--cont (CSS collapses its
//     author line). Decided client-side because broadcast packets render
//     viewer-neutral and don't know their predecessor; packets stay
//     direct children, and a removal/replace regroups the follower.
//   packet-log:state {atBottom, unread} — dispatched on scroll + mutation
//     so a host (uplink-shell) can float a "new packets" jump pill;
//     unread counts foreign packets that arrive while scrolled up.
//   Re-pins through late layout shifts (emote image loads, the composer
//     growing and shrinking the log).

const GROUP_WINDOW_MS = 5 * 60 * 1000
const BOTTOM_SLACK_PX = 50

function isPacket (node: Node | null | undefined): node is HTMLElement {
  return node instanceof HTMLElement && node.classList.contains('packet')
}

export default class extends Controller<HTMLElement> {
  static values = { cap: Number, group: Boolean }

  declare readonly capValue: number
  declare readonly groupValue: boolean

  private observer: MutationObserver | null = null
  private resizeObserver: ResizeObserver | null = null
  private atBottom = true
  private unread = 0

  private scrollHandler = (): void => {
    const wasAtBottom = this.atBottom
    this.atBottom = this.checkAtBottom()
    if (this.atBottom) this.unread = 0
    if (wasAtBottom !== this.atBottom) this.publishState()
  }

  private loadHandler = (): void => {
    if (this.atBottom) this.scrollToBottom()
  }

  connect (): void {
    this.regroupAll()
    this.scrollToBottom()
    this.element.addEventListener('scroll', this.scrollHandler)
    this.element.addEventListener('load', this.loadHandler, true)
    this.observer = new MutationObserver(records => this.onMutations(records))
    this.observer.observe(this.element, { childList: true })
    if (typeof ResizeObserver !== 'undefined') {
      this.resizeObserver = new ResizeObserver(() => { if (this.atBottom) this.scrollToBottom() })
      this.resizeObserver.observe(this.element)
    }
    this.publishState()
  }

  disconnect (): void {
    this.element.removeEventListener('scroll', this.scrollHandler)
    this.element.removeEventListener('load', this.loadHandler, true)
    this.observer?.disconnect()
    this.observer = null
    this.resizeObserver?.disconnect()
    this.resizeObserver = null
  }

  private onMutations (records: MutationRecord[]): void {
    this.trim()
    let arrived = 0
    records.forEach(record => {
      // A Turbo replace (drop/restore) removes and adds the same id in one
      // record: regroup it, but it is not a new packet.
      const replaced = new Set(Array.from(record.removedNodes, node => (node as Element).id).filter(Boolean))
      record.addedNodes.forEach(node => {
        if (!isPacket(node)) return
        if (!replaced.has(node.id) && this.fromOthers(node)) arrived += 1
        this.regroup(node)
        this.regroup(node.nextElementSibling)
      })
      if (record.removedNodes.length > 0) this.regroup(record.nextSibling)
    })
    if (this.atBottom) {
      this.scrollToBottom()
    } else if (arrived > 0) {
      this.unread += arrived
      this.publishState()
    }
  }

  private regroupAll (): void {
    Array.from(this.element.children).forEach(child => this.regroup(child))
  }

  private regroup (node: Node | null | undefined): void {
    if (!this.groupValue || !isPacket(node)) return
    const prev = node.previousElementSibling
    const key = node.dataset.authorKey
    const continues = isPacket(prev) && !!key && prev.dataset.authorKey === key &&
      Math.abs(Number(node.dataset.at) - Number(prev.dataset.at)) < GROUP_WINDOW_MS
    node.classList.toggle('packet--cont', continues)
  }

  private fromOthers (packet: HTMLElement): boolean {
    const viewer = document.querySelector<HTMLMetaElement>('meta[name="current-hackr-id"]')?.content
    return !viewer || packet.dataset.packetOwnerIdValue !== viewer
  }

  private publishState (): void {
    this.dispatch('state', { detail: { atBottom: this.atBottom, unread: this.unread } })
  }

  private trim (): void {
    if (this.capValue <= 0) return
    while (this.element.children.length > this.capValue) {
      this.element.firstElementChild?.remove()
    }
  }

  private checkAtBottom (): boolean {
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < BOTTOM_SLACK_PX
  }

  private scrollToBottom (): void {
    this.element.scrollTop = this.element.scrollHeight
    this.atBottom = true
    this.unread = 0
  }
}
