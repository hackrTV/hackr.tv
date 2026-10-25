import { Controller } from '@hotwired/stimulus'

// Chrome for the /uplink NODE shell (uplink/_shell). The uplink
// controller on the same root keeps doing presence + reconnect; this one
// owns the layout state and the small Discord-feel behaviours:
//   - members pane toggle (persisted per browser on desktop; a drawer
//     under 768px) and the channel-list drawer under 768px, with a
//     CSS backdrop (data-drawer), Escape, and the main pane inert while
//     a drawer is open;
//   - the live stage collapse (persisted); a collapsed stage has no
//     iframe src, so it never plays audio;
//   - the "[v] N NEW PACKETS" jump pill, fed by packet-log:state events
//     from the log (prefixed "@ MENTION" when an unread packet mentions
//     the viewer); the viewer's own sends always jump to the bottom;
//   - "/" focuses the composer from anywhere outside a field;
//   - unread badges: the sidebar renders each other channel's count
//     (packets above the viewer's read mark); a hidden block of bump
//     slots (one per counted channel, fed by the uplink_bump streams)
//     gets an <i> appended per packet, and a MutationObserver turns each
//     into +1 on that row's badge (capped "99+"). The viewer's own mark
//     for THIS channel moves by ack: when a foreign packet lands while
//     the log sits at the bottom (packet-log:state), the last packet's
//     id is POSTed to the ack url after a short debounce — and at once,
//     keepalive, on the way out — so switching channels never shows the
//     packets you just watched as unread;
//   - mention toasts (toast:connected on document, carrying the packet's
//     channel): recolor that sidebar row (--mention; the bump shows the
//     count) when the mention is in another channel; drop the toast when
//     it is this channel — the packet is already in the log, highlighted,
//     and the pill covers a reader who scrolled up.
// State lives on the shell root (data-members / data-drawer), so the
// roster being replaced by a broadcast never resets it.

const MOBILE_QUERY = '(max-width: 767px)'
const MEMBERS_OPEN_MIN_WIDTH = 1100
const MEMBERS_KEY = 'uplink:members'
const STAGE_KEY = 'uplink:stage'
const ACK_DELAY_MS = 1500
const BADGE_CAP = 99
const SLUG = /^[\w-]+$/ // validated, not escaped: jsdom has no CSS.escape

type Drawer = '' | 'sidebar' | 'members'

export default class extends Controller<HTMLElement> {
  static targets = ['sidebar', 'members', 'main', 'jump', 'jumpCount', 'membersToggle', 'stage', 'stageFrame', 'stageToggle', 'bumps']
  static values = { channel: String, ackUrl: String }

  declare readonly channelValue: string
  declare readonly ackUrlValue: string

  declare readonly sidebarTarget: HTMLElement
  declare readonly membersTarget: HTMLElement
  declare readonly mainTarget: HTMLElement
  declare readonly jumpTarget: HTMLButtonElement
  declare readonly jumpCountTarget: HTMLElement
  declare readonly membersToggleTarget: HTMLButtonElement
  // The stage (and its frame + toggle) renders only on a live livestream channel.
  declare readonly hasStageTarget: boolean
  declare readonly stageTarget: HTMLElement
  declare readonly stageFrameTarget: HTMLIFrameElement
  declare readonly stageToggleTarget: HTMLButtonElement
  // The bump block renders in the shell's sidebar only.
  declare readonly hasBumpsTarget: boolean
  declare readonly bumpsTarget: HTMLElement

  private mobile: MediaQueryList | null = null
  private bumpObserver: MutationObserver | null = null
  private ackTimer = 0
  private acked = 0

  connect (): void {
    this.applyMembersPreference()
    this.applyStagePreference()
    this.mobile = typeof window.matchMedia === 'function' ? window.matchMedia(MOBILE_QUERY) : null
    this.mobile?.addEventListener('change', this.closeDrawers)
    document.addEventListener('turbo:before-cache', this.closeDrawers)
    window.addEventListener('pagehide', this.flushAck)
    this.acked = this.lastPacket()?.id ?? 0 // the render marked everything on screen
    if (this.hasBumpsTarget) {
      this.bumpObserver = new MutationObserver(records => this.onBumps(records))
      this.bumpObserver.observe(this.bumpsTarget, { childList: true, subtree: true })
    }
    this.autofocusComposer()
  }

  disconnect (): void {
    this.mobile?.removeEventListener('change', this.closeDrawers)
    this.mobile = null
    document.removeEventListener('turbo:before-cache', this.closeDrawers)
    window.removeEventListener('pagehide', this.flushAck)
    this.bumpObserver?.disconnect()
    this.bumpObserver = null
    this.flushAck()
    this.setDrawer('')
    if (this.hasStageTarget) this.stageFrameTarget.removeAttribute('src')
  }

  // ── Drawers (under 768px) + members pane ───────────────────────────

  toggleSidebar (): void {
    this.toggleDrawer('sidebar')
  }

  toggleMembers (): void {
    if (this.isMobile) {
      this.toggleDrawer('members')
      return
    }
    const open = this.element.dataset.members !== 'open'
    this.setMembers(open)
    this.store(MEMBERS_KEY, open ? 'open' : 'closed')
  }

  closeDrawers = (): void => {
    this.setDrawer('')
  }

  // ── Stage ──────────────────────────────────────────────────────────

  toggleStage (): void {
    if (!this.hasStageTarget) return
    const collapsed = !this.stageTarget.classList.contains('uplink-stage--collapsed')
    this.setStage(collapsed)
    this.store(STAGE_KEY, collapsed ? 'closed' : 'open')
  }

  // ── Log ────────────────────────────────────────────────────────────

  logState (event: CustomEvent<{ atBottom: boolean, unread: number, mentions?: number }>): void {
    const { atBottom, unread } = event.detail
    const mentions = event.detail.mentions ?? 0
    if (atBottom) this.scheduleAck()
    const show = !atBottom && unread > 0
    this.jumpTarget.hidden = !show
    this.jumpTarget.classList.toggle('uplink-jump--mention', show && mentions > 0)
    if (!show) return
    const packets = `${unread} NEW PACKET${unread === 1 ? '' : 'S'}`
    this.jumpCountTarget.textContent = mentions > 0 ? `@ MENTION · ${packets}` : packets
  }

  jump (): void {
    const log = this.element.querySelector<HTMLElement>('#uplink-log')
    if (log) log.scrollTop = log.scrollHeight
  }

  // Only the composer's own send jumps; drop/restore forms inside the log
  // submit through here too and must leave a reader's scroll alone.
  sent (event: Event): void {
    if (!(event.target instanceof HTMLElement) || !event.target.closest('.packet-input-form')) return
    if ((event as CustomEvent).detail?.success) window.requestAnimationFrame(() => this.jump())
  }

  // ── Unread badges ──────────────────────────────────────────────────

  toast (event: CustomEvent<{ channel?: string | null }>): void {
    const slug = event.detail?.channel
    if (!slug || !SLUG.test(slug)) return
    if (slug === this.channelValue) {
      if (event.target instanceof HTMLElement) event.target.remove()
      return
    }
    this.row(slug)?.classList.add('uplink-channel--mention') // the packet's bump shows the count
  }

  // Each <i> appended into a bump slot (data-channel) is one packet in
  // that channel: +1 on the row's badge, then the slot is emptied again.
  private onBumps (records: MutationRecord[]): void {
    records.forEach(record => {
      const slot = record.target
      if (!(slot instanceof HTMLElement) || !slot.dataset.channel) return
      record.addedNodes.forEach(node => {
        if (!(node instanceof Element)) return
        node.remove()
        this.bump(slot.dataset.channel ?? '')
      })
    })
  }

  private bump (slug: string): void {
    const row = this.row(slug)
    const badge = row?.querySelector<HTMLElement>('.uplink-channel-badge')
    if (!row || !badge) return
    const count = Number(badge.dataset.count ?? 0) + 1
    badge.dataset.count = String(count)
    badge.textContent = count > BADGE_CAP ? `${BADGE_CAP}+` : String(count)
    badge.hidden = false
    row.classList.add('uplink-channel--unread')
  }

  private row (slug: string): HTMLElement | null {
    if (!SLUG.test(slug)) return null
    return this.element.querySelector<HTMLElement>(`.uplink-channel[data-channel="${slug}"]`)
  }

  // ── Read acks (this channel) ───────────────────────────────────────

  private scheduleAck (): void {
    if (!this.ackUrlValue || !this.pendingAck()) return
    window.clearTimeout(this.ackTimer)
    this.ackTimer = window.setTimeout(() => this.ack(false), ACK_DELAY_MS)
  }

  private flushAck = (): void => {
    window.clearTimeout(this.ackTimer)
    this.ackTimer = 0
    if (this.ackUrlValue && this.pendingAck()) this.ack(true)
  }

  // The newest packet, when it is above the last acked id and not the
  // viewer's own (an own send is marked read by its POST already).
  private pendingAck (): number | null {
    const last = this.lastPacket()
    if (!last || last.id <= this.acked) return null
    if (last.own) {
      this.acked = last.id
      return null
    }
    return last.id
  }

  private ack (keepalive: boolean): void {
    this.ackTimer = 0
    const id = this.pendingAck()
    if (id === null) return
    this.acked = id
    const body = new URLSearchParams({ channel: this.channelValue, last_read_message_id: String(id) })
    void fetch(this.ackUrlValue, { method: 'POST', body, credentials: 'same-origin', keepalive }).catch(() => {
      // Lost ack: the next packet at the bottom (or the next render) marks it.
    })
  }

  private lastPacket (): { id: number, own: boolean } | null {
    const packets = this.element.querySelectorAll<HTMLElement>('#uplink-log .packet')
    const last = packets[packets.length - 1]
    const id = Number(last?.id.match(/(\d+)$/)?.[1])
    if (!last || !Number.isFinite(id)) return null
    const viewer = document.querySelector<HTMLMetaElement>('meta[name="current-hackr-id"]')?.content
    return { id, own: !!viewer && last.dataset.packetOwnerIdValue === viewer }
  }

  // ── Keys ───────────────────────────────────────────────────────────

  hotkey (event: KeyboardEvent): void {
    if (event.defaultPrevented) return
    if (event.key === 'Escape') {
      if (!this.drawer) return
      event.preventDefault()
      this.closeDrawers()
      return
    }
    if (event.key !== '/' || event.ctrlKey || event.metaKey || event.altKey) return
    if (this.inEditable(event.target)) return
    const field = this.composer()
    if (!field || field.disabled) return
    event.preventDefault()
    field.focus()
  }

  // ── Internals ──────────────────────────────────────────────────────

  private get drawer (): Drawer {
    return (this.element.dataset.drawer ?? '') as Drawer
  }

  private get isMobile (): boolean {
    return this.mobile?.matches ?? false
  }

  private toggleDrawer (name: Drawer): void {
    this.setDrawer(this.drawer === name ? '' : name)
  }

  private setDrawer (name: Drawer): void {
    this.element.dataset.drawer = name
    this.mainTarget.toggleAttribute('inert', name !== '')
    if (name === '') return
    const pane = name === 'sidebar' ? this.sidebarTarget : this.membersTarget
    pane.querySelector<HTMLElement>('a, button')?.focus()
  }

  private setMembers (open: boolean): void {
    this.element.dataset.members = open ? 'open' : 'closed'
    this.membersToggleTarget.setAttribute('aria-pressed', String(open))
  }

  private applyMembersPreference (): void {
    const stored = this.read(MEMBERS_KEY)
    const open = stored ? stored === 'open' : window.innerWidth >= MEMBERS_OPEN_MIN_WIDTH
    this.setMembers(open)
  }

  private applyStagePreference (): void {
    if (!this.hasStageTarget) return
    this.setStage(this.read(STAGE_KEY) === 'closed')
  }

  private setStage (collapsed: boolean): void {
    this.stageTarget.classList.toggle('uplink-stage--collapsed', collapsed)
    const frame = this.stageFrameTarget
    if (collapsed) {
      frame.removeAttribute('src')
    } else if (!frame.getAttribute('src') && frame.dataset.src) {
      frame.src = frame.dataset.src
    }
    this.stageToggleTarget.textContent = collapsed ? '[+] SHOW VIDEO' : '[-] HIDE VIDEO'
    this.stageToggleTarget.setAttribute('aria-expanded', String(!collapsed))
  }

  private autofocusComposer (): void {
    if (typeof window.matchMedia !== 'function' || !window.matchMedia('(pointer: fine)').matches) return
    if (this.inEditable(document.activeElement)) return
    const field = this.composer()
    if (field && !field.disabled) field.focus()
  }

  private composer (): HTMLTextAreaElement | HTMLInputElement | null {
    return this.element.querySelector<HTMLTextAreaElement | HTMLInputElement>('.packet-input-text')
  }

  private inEditable (target: EventTarget | null): boolean {
    if (!(target instanceof HTMLElement)) return false
    return target.matches('input, textarea, select, [contenteditable="true"]')
  }

  private read (key: string): string | null {
    try { return window.localStorage.getItem(key) } catch { return null }
  }

  private store (key: string, value: string): void {
    try { window.localStorage.setItem(key, value) } catch { /* private mode / blocked storage */ }
  }
}
