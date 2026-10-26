import { Controller } from '@hotwired/stimulus'
import { jumpToPacket } from '~/utils/packetJump'

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
//     direct children, and a removal/replace regroups the follower. A
//     reply (data-reply-to) always starts a group: its quote line sits
//     above its own author line.
//   the "// NEW PACKETS //" separator (data-packet-log-target="unseen",
//     uplink/_log_frame): opened scrolled to when it sits above the fold;
//     grouping never continues across it (not a .packet sibling).
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
//   A located log (/uplink?around=<id>, Phase 2 item 9): focus=<id>
//     opens on that packet — centered + flashed — instead of the bottom,
//     and a `bottom` target (the .uplink-log-bottom sentinel _log_frame
//     renders when newer packets exist) pages forward the same way:
//     data-src&after=<last packet id>, spliced in before the sentinel,
//     the end marker flipping data-more off. Until then the log is
//     behind the present: a live append would land below the loaded
//     end, out of order, so it is parked and released — minus what the
//     final page already carried — once the present is reached; the
//     state event says atPresent so the host's pill can offer the way
//     there. The reconnect reload (uplink controller) replaces the frame
//     with the newest page, so a cable drop ends a located view.

const GROUP_WINDOW_MS = 5 * 60 * 1000
const BOTTOM_SLACK_PX = 50
const SCROLLBACK_MARGIN = '160px 0px 0px 0px'
const SCROLLFORWARD_MARGIN = '0px 0px 160px 0px'
const UNSEEN_MARGIN_PX = 8
const FOCUS_FLASH_MS = 2400

function isPacket (node: Node | null | undefined): node is HTMLElement {
  return node instanceof HTMLElement && node.classList.contains('packet')
}

export default class extends Controller<HTMLElement> {
  static values = { cap: Number, group: Boolean, focus: Number }
  static targets = ['top', 'unseen', 'bottom']

  declare readonly capValue: number
  declare readonly groupValue: boolean
  declare readonly focusValue: number
  declare readonly hasTopTarget: boolean
  declare readonly hasUnseenTarget: boolean
  declare readonly hasBottomTarget: boolean
  declare readonly unseenTarget: HTMLElement
  declare readonly topTarget: HTMLElement
  declare readonly bottomTarget: HTMLElement

  private observer: MutationObserver | null = null
  private resizeObserver: ResizeObserver | null = null
  private topObserver: IntersectionObserver | null = null
  private bottomObserver: IntersectionObserver | null = null
  private loading = false
  private loadingNewer = false
  private history = new Set<string>()
  private parked: HTMLElement[] = []
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
    if (!this.focus()) this.scrollToBottom()
    this.revealUnseen()
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
    if (this.hasBottomTarget && typeof IntersectionObserver !== 'undefined') {
      this.bottomObserver = new IntersectionObserver(entries => {
        if (entries.some(entry => entry.isIntersecting)) void this.loadNewer()
      }, { root: this.element, rootMargin: SCROLLFORWARD_MARGIN })
      this.bottomObserver.observe(this.bottomTarget)
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
    this.bottomObserver?.disconnect()
    this.bottomObserver = null
    this.parked = []
  }

  // A located log opens on its focus packet, centered + flashed; the
  // viewer is then wherever that lands, not pinned to the bottom.
  private focus (): boolean {
    if (!this.focusValue || !jumpToPacket(this.focusValue, FOCUS_FLASH_MS)) return false
    this.atBottom = this.checkAtBottom()
    return true
  }

  // The present is below the loaded end while the bottom sentinel still
  // has pages to fetch.
  private get atPresent (): boolean {
    return !this.hasBottomTarget || this.bottomTarget.dataset.more !== 'true'
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

  // Fetch the page after the last packet and splice it in before the
  // bottom sentinel. Same discipline as loadOlder: one in flight, a
  // failed page retried on the next intersection.
  async loadNewer (): Promise<void> {
    if (!this.hasBottomTarget || this.loadingNewer || this.atPresent) return
    const src = this.bottomTarget.dataset.src
    const last = this.lastPacketId()
    if (!src || !last) return

    const sentinel = this.bottomTarget // gone once the present is reached
    this.loadingNewer = true
    sentinel.dataset.loading = 'true'
    try {
      const url = new URL(src, window.location.origin)
      url.searchParams.set('after', last)
      const response = await fetch(url.toString(), { headers: { Accept: 'text/html' }, credentials: 'same-origin' })
      if (!response.ok) return
      this.spliceNewer(await response.text())
    } catch {
      // Network failure: retry on the next intersection.
    } finally {
      this.loadingNewer = false
      delete sentinel.dataset.loading
      if (this.bottomObserver && !this.atPresent) {
        this.bottomObserver.unobserve(sentinel)
        this.bottomObserver.observe(sentinel)
      }
    }
  }

  // Newer packets go below the viewport, so nothing to anchor; the first
  // one regroups behind the old last packet. The end marker means the
  // present: the sentinel retires outright — a later live append must
  // find a packet as its previous sibling to group behind — and the
  // parked appends come out.
  private spliceNewer (html: string): void {
    const fragment = document.createRange().createContextualFragment(html)
    const end = fragment.querySelector('template[data-log-end]')
    end?.remove()
    const packets = Array.from(fragment.querySelectorAll<HTMLElement>('.packet'))
    packets.forEach(packet => this.history.add(packet.id))
    this.bottomTarget.before(fragment)
    packets.forEach(packet => this.regroup(packet))
    if (end) {
      this.bottomTarget.remove()
      this.release()
    }
    this.atBottom = this.checkAtBottom()
    this.publishState()
  }

  // Live packets parked while the log was behind the present: append the
  // ones the final page did not already carry — as the arrivals they are
  // (counted, grouped, pinned to like any other append).
  private release (): void {
    this.parked.splice(0).forEach(packet => {
      if (!document.getElementById(packet.id)) this.element.append(packet)
    })
  }

  private firstPacketId (): string | null {
    const first = this.element.querySelector<HTMLElement>('.packet')
    return first?.id.match(/(\d+)$/)?.[1] ?? null
  }

  private lastPacketId (): string | null {
    const packets = this.element.querySelectorAll<HTMLElement>('.packet')
    return packets[packets.length - 1]?.id.match(/(\d+)$/)?.[1] ?? null
  }

  private onMutations (records: MutationRecord[]): void {
    this.trim()
    let arrived = 0
    let mentioned = 0
    let landed = false // anything but a spliced page: an append, a replace, a removal
    records.forEach(record => {
      // A Turbo replace (drop/restore) removes and adds the same id in one
      // record: regroup it, but it is not a new packet.
      const replaced = new Set(Array.from(record.removedNodes, node => (node as Element).id).filter(Boolean))
      record.addedNodes.forEach(node => {
        if (!isPacket(node)) return
        const spliced = this.history.delete(node.id)
        if (!spliced && !replaced.has(node.id) && !this.atPresent) {
          // Behind the present: a live append would sit below the loaded
          // end, out of order. Park it until the forward pages get there.
          node.remove()
          this.parked.push(node)
          return
        }
        if (!spliced) landed = true
        if (!spliced && !replaced.has(node.id) && this.fromOthers(node)) {
          arrived += 1
          if (this.mentionsViewer(node)) mentioned += 1
        }
        this.regroup(node)
        this.regroup(node.nextElementSibling)
      })
      if (record.removedNodes.length > 0) {
        if (Array.from(record.removedNodes).some(isPacket)) landed = true
        this.regroup(record.nextSibling)
      }
    })
    if (this.atBottom) {
      // A spliced page alone never re-pins: the viewer is reading there.
      if (landed) this.scrollToBottom()
      if (arrived > 0) this.publishState() // seen at the bottom: the shell acks it as read
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
    const continues = node.dataset.replyTo === undefined && isPacket(prev) && !!key && prev.dataset.authorKey === key &&
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
    this.dispatch('state', { detail: { atBottom: this.atBottom, unread: this.unread, mentions: this.mentions, atPresent: this.atPresent } })
  }

  private trim (): void {
    if (this.capValue <= 0) return
    while (this.element.children.length > this.capValue) {
      this.element.firstElementChild?.remove()
    }
  }

  // The "// NEW PACKETS //" separator (uplink/_log_frame) is where the
  // packets the viewer hasn't seen start: when pinning to the bottom
  // leaves it above the fold, open scrolled to it instead (Discord's
  // unread marker). The viewer is then "scrolled up": arrivals go to
  // the jump pill and the read ack waits for the bottom.
  private revealUnseen (): void {
    if (!this.hasUnseenTarget) return
    const delta = this.unseenTarget.getBoundingClientRect().top - this.element.getBoundingClientRect().top
    if (delta >= 0) return
    this.element.scrollTop += delta - UNSEEN_MARGIN_PX
    this.atBottom = this.checkAtBottom()
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
