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
//   packet-log:state {atBottom, unread, mentions} — dispatched on scroll +
//     mutation so a host (uplink-shell) can float a "new packets" jump
//     pill; unread counts foreign packets that arrive while scrolled up,
//     mentions how many of those @mention the viewer (matched here
//     against the current-hackr-alias meta, independent of the packet
//     controller's highlight timing).
//   Re-pins through late layout shifts (emote image loads, the composer
//     growing and shrinking the log).
//   Scrollback — a `top` target (the .uplink-log-top sentinel _log_frame
//     renders in shell mode, carrying data-src = the channel's log URL
//     and data-more) is watched with an IntersectionObserver; while it
//     is in view and more history exists, one page at a time is fetched
//     from data-src&before=<first packet id> (uplink/_packets: packets
//     only, chronological, plus a <template data-log-end> marker on the
//     last page) and spliced in right after the sentinel. The viewport is
//     anchored by hand (scrollTop += the height added) — the shell sets
//     overflow-anchor: none so the browser's own anchoring can't double
//     it — and the spliced packets never count as unread. Grouping
//     continues across the page boundary because the old first packet
//     regroups behind its new predecessor like any other insertion.

const GROUP_WINDOW_MS = 5 * 60 * 1000
const BOTTOM_SLACK_PX = 50
const SCROLLBACK_MARGIN = '160px 0px 0px 0px'

function isPacket (node: Node | null | undefined): node is HTMLElement {
  return node instanceof HTMLElement && node.classList.contains('packet')
}

export default class extends Controller<HTMLElement> {
  static values = { cap: Number, group: Boolean }
  static targets = ['top']

  declare readonly capValue: number
  declare readonly groupValue: boolean
  declare readonly hasTopTarget: boolean
  declare readonly topTarget: HTMLElement

  private observer: MutationObserver | null = null
  private resizeObserver: ResizeObserver | null = null
  private topObserver: IntersectionObserver | null = null
  private loading = false
  private history = new Set<string>()
  private atBottom = true
  private unread = 0
  private mentions = 0

  private scrollHandler = (): void => {
    const wasAtBottom = this.atBottom
    this.atBottom = this.checkAtBottom()
    if (this.atBottom) this.clearUnread()
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
    if (this.hasTopTarget && typeof IntersectionObserver !== 'undefined') {
      this.topObserver = new IntersectionObserver(entries => {
        if (entries.some(entry => entry.isIntersecting)) void this.loadOlder()
      }, { root: this.element, rootMargin: SCROLLBACK_MARGIN })
      this.topObserver.observe(this.topTarget)
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
    this.topObserver?.disconnect()
    this.topObserver = null
  }

  // Fetch the page before the first packet and splice it in after the
  // sentinel. One in flight at a time; a failed page leaves data-more
  // alone so the next time the sentinel scrolls into view retries.
  async loadOlder (): Promise<void> {
    if (!this.hasTopTarget || this.loading || this.topTarget.dataset.more !== 'true') return
    const src = this.topTarget.dataset.src
    const first = this.firstPacketId()
    if (!src || !first) return

    this.loading = true
    this.topTarget.dataset.loading = 'true'
    try {
      const url = new URL(src, window.location.origin)
      url.searchParams.set('before', first)
      const response = await fetch(url.toString(), { headers: { Accept: 'text/html' }, credentials: 'same-origin' })
      if (!response.ok) return
      this.splice(await response.text())
    } catch {
      // Network failure: retry on the next intersection.
    } finally {
      this.loading = false
      delete this.topTarget.dataset.loading
      // Re-observing delivers a fresh entry: a short page can leave the
      // sentinel in view with no transition to fire on.
      if (this.topObserver && this.topTarget.dataset.more === 'true') {
        this.topObserver.unobserve(this.topTarget)
        this.topObserver.observe(this.topTarget)
      }
    }
  }

  private splice (html: string): void {
    // A contextual fragment parses into this document (a <template>'s
    // inert document fails instanceof HTMLElement under jsdom).
    const fragment = document.createRange().createContextualFragment(html)
    const end = fragment.querySelector('template[data-log-end]')
    end?.remove()
    const packets = Array.from(fragment.querySelectorAll<HTMLElement>('.packet'))
    packets.forEach(packet => this.history.add(packet.id))

    const follower = this.topTarget.nextElementSibling
    const height = this.element.scrollHeight
    const top = this.element.scrollTop
    this.topTarget.after(fragment)
    // Group the seam before measuring: a continuation packet is shorter
    // than a group head (no author line, no gap), so the height added is
    // only known once the new packets and the old first one are regrouped
    // (the MutationObserver would do it a microtask too late).
    packets.forEach(packet => this.regroup(packet))
    this.regroup(follower)
    this.element.scrollTop = top + (this.element.scrollHeight - height)
    if (end) this.topTarget.dataset.more = 'false'
  }

  private firstPacketId (): string | null {
    const first = this.element.querySelector<HTMLElement>('.packet')
    const match = first?.id.match(/(\d+)$/)
    return match ? match[1] : null
  }

  private onMutations (records: MutationRecord[]): void {
    this.trim()
    let arrived = 0
    let mentioned = 0
    records.forEach(record => {
      // A Turbo replace (drop/restore) removes and adds the same id in one
      // record: regroup it, but it is not a new packet.
      const replaced = new Set(Array.from(record.removedNodes, node => (node as Element).id).filter(Boolean))
      record.addedNodes.forEach(node => {
        if (!isPacket(node)) return
        const spliced = this.history.delete(node.id)
        if (!spliced && !replaced.has(node.id) && this.fromOthers(node)) {
          arrived += 1
          if (this.mentionsViewer(node)) mentioned += 1
        }
        this.regroup(node)
        this.regroup(node.nextElementSibling)
      })
      if (record.removedNodes.length > 0) this.regroup(record.nextSibling)
    })
    if (this.atBottom) {
      this.scrollToBottom()
    } else if (arrived > 0) {
      this.unread += arrived
      this.mentions += mentioned
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

  private mentionsViewer (packet: HTMLElement): boolean {
    const alias = document.querySelector<HTMLMetaElement>('meta[name="current-hackr-alias"]')?.content?.toLowerCase()
    if (!alias) return false
    return Array.from(packet.querySelectorAll<HTMLElement>('.uplink-mention'))
      .some(el => el.dataset.alias?.toLowerCase() === alias)
  }

  private clearUnread (): void {
    this.unread = 0
    this.mentions = 0
  }

  private publishState (): void {
    this.dispatch('state', { detail: { atBottom: this.atBottom, unread: this.unread, mentions: this.mentions } })
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
    this.clearUnread()
  }
}
