import { Controller, type ActionEvent } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import { jumpToPacket } from '~/utils/packetJump'

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
//     the viewer); the viewer's own sends always jump to the bottom. On
//     a located log (/uplink?around=, the log behind the present) it
//     reads "[v] JUMP TO PRESENT" and visits the present url instead —
//     an own send does too;
//   - the operatives pane's search face (data-pane="search" on the
//     root; the roster preference in data-members is untouched, so
//     closing the search returns to it): the header's [/] opens it with
//     the field focused — as the members drawer under 768px — and [x],
//     Escape in the field or [o] (back to the roster) close it. A hit's
//     link (locate, id param) scrolls to + flashes the packet when the
//     log has it, swallowing the visit; otherwise the link goes through
//     to /uplink?around=<id>, which opens the log on it;
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
//     and the pill covers a reader who scrolled up;
//   - the sidebar's categories collapse (the heading is a button; the
//     rows hide but the active and unread ones, and a bump reveals its
//     row; remembered in localStorage) and the list is one Tab stop:
//     the active row holds tabindex 0 and the arrows walk headings +
//     shown rows (Home/End; Left/Right fold a heading, Left on a row
//     climbs to its heading);
//   - the quick switcher (Ctrl/Cmd+K anywhere, or the sidebar's [>]):
//     a dialog whose options are the sidebar's rows, filtered as you
//     type (name first, then category), Up/Down + Enter visiting the
//     channel, Escape closing it back to where focus was;
//   - the tab title: "(N) …" while packets wait — the sidebar badges
//     plus this channel's unread — and "(@N)" when one mentions you.
// State lives on the shell root (data-members / data-drawer), so the
// roster being replaced by a broadcast never resets it.

const MOBILE_QUERY = '(max-width: 767px)'
const MEMBERS_OPEN_MIN_WIDTH = 1100
const MEMBERS_KEY = 'uplink:members'
const STAGE_KEY = 'uplink:stage'
const COLLAPSED_KEY = 'uplink:collapsed'
const ACK_DELAY_MS = 1500
const BADGE_CAP = 99
const SWITCHER_MAX = 8
const TITLE_PREFIX = /^\(@?\d+\+?\) /
const SLUG = /^[\w-]+$/ // validated, not escaped: jsdom has no CSS.escape

type Drawer = '' | 'sidebar' | 'members'
type Pane = 'members' | 'search'

export default class extends Controller<HTMLElement> {
  static targets = ['sidebar', 'members', 'main', 'jump', 'jumpCount', 'membersToggle', 'stage', 'stageFrame', 'stageToggle', 'bumps', 'searchToggle', 'searchField', 'switcher', 'switcherField', 'switcherList']
  static values = { channel: String, ackUrl: String, presentUrl: String }

  declare readonly channelValue: string
  declare readonly ackUrlValue: string
  declare readonly presentUrlValue: string

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
  // The search face (toggle + field) renders on viewable channels only.
  declare readonly hasSearchToggleTarget: boolean
  declare readonly searchToggleTarget: HTMLButtonElement
  declare readonly hasSearchFieldTarget: boolean
  declare readonly searchFieldTarget: HTMLInputElement
  // The quick switcher renders in the shell only (the test fixtures may leave it out).
  declare readonly hasSwitcherTarget: boolean
  declare readonly switcherTarget: HTMLElement
  declare readonly switcherFieldTarget: HTMLInputElement
  declare readonly switcherListTarget: HTMLElement

  private mobile: MediaQueryList | null = null
  private bumpObserver: MutationObserver | null = null
  private ackTimer = 0
  private acked = 0
  private present = true
  private hereUnread = 0
  private hereMentions = 0
  private baseTitle = ''
  private titled = ''
  private switcherReturn: HTMLElement | null = null
  private switcherIndex = 0

  connect (): void {
    this.baseTitle = document.title.replace(TITLE_PREFIX, '')
    this.applyMembersPreference()
    this.applyStagePreference()
    this.applyCollapsed()
    this.syncRoving()
    this.mobile = typeof window.matchMedia === 'function' ? window.matchMedia(MOBILE_QUERY) : null
    this.mobile?.addEventListener('change', this.closeDrawers)
    document.addEventListener('turbo:before-cache', this.closeDrawers)
    document.addEventListener('turbo:before-cache', this.closeSwitcher)
    window.addEventListener('pagehide', this.flushAck)
    this.acked = this.lastPacket()?.id ?? 0 // the render marked everything on screen
    if (this.hasBumpsTarget) {
      this.bumpObserver = new MutationObserver(records => this.onBumps(records))
      this.bumpObserver.observe(this.bumpsTarget, { childList: true, subtree: true })
    }
    this.updateTitle()
    this.autofocusComposer()
  }

  disconnect (): void {
    this.mobile?.removeEventListener('change', this.closeDrawers)
    this.mobile = null
    document.removeEventListener('turbo:before-cache', this.closeDrawers)
    document.removeEventListener('turbo:before-cache', this.closeSwitcher)
    window.removeEventListener('pagehide', this.flushAck)
    this.bumpObserver?.disconnect()
    this.bumpObserver = null
    this.flushAck()
    this.setDrawer('')
    this.closeSwitcher()
    if (document.title === this.titled) document.title = this.baseTitle // unless Turbo already put the next page's in
    if (this.hasStageTarget) this.stageFrameTarget.removeAttribute('src')
  }

  // ── Drawers (under 768px) + members pane ───────────────────────────

  toggleSidebar (): void {
    this.toggleDrawer('sidebar')
  }

  // [o]: from the search face, back to the roster (opened); else the toggle.
  toggleMembers (): void {
    const fromSearch = this.pane === 'search'
    this.setPane('members')
    if (this.isMobile) {
      this.toggleDrawer('members')
      return
    }
    const open = fromSearch || this.element.dataset.members !== 'open'
    this.setMembers(open)
    this.store(MEMBERS_KEY, open ? 'open' : 'closed')
  }

  closeDrawers = (): void => {
    this.setDrawer('')
  }

  // ── Sidebar: categories + the keyboard ring ────────────────────────

  toggleCategory (event: Event): void {
    const group = (event.currentTarget as HTMLElement).closest<HTMLElement>('.uplink-category-group')
    if (!group) return
    this.setCollapsed(group, !group.hasAttribute('data-collapsed'))
    this.storeCollapsed()
  }

  // Arrow keys over headings + shown rows (the list is one Tab stop).
  channelKey (event: KeyboardEvent): void {
    if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey) return
    const current = event.target
    if (!(current instanceof HTMLElement)) return
    const ring = this.ring()
    const index = ring.indexOf(current)
    if (index < 0) return
    let next: HTMLElement | undefined
    switch (event.key) {
    case 'ArrowDown': next = ring[(index + 1) % ring.length]; break
    case 'ArrowUp': next = ring[(index - 1 + ring.length) % ring.length]; break
    case 'Home': next = ring[0]; break
    case 'End': next = ring[ring.length - 1]; break
    case 'ArrowLeft':
    case 'ArrowRight': {
      const group = current.closest<HTMLElement>('.uplink-category-group')
      if (!group) return
      if (current.matches('.uplink-category')) { // fold / unfold the heading
        event.preventDefault()
        this.setCollapsed(group, event.key === 'ArrowLeft')
        this.storeCollapsed()
        return
      }
      if (event.key === 'ArrowRight') return
      next = group.querySelector<HTMLElement>('.uplink-category') ?? undefined // a row climbs to its heading
      break
    }
    default: return
    }
    if (!next) return
    event.preventDefault()
    this.setRoving(next)
    next.focus()
  }

  private applyCollapsed (): void {
    const names = this.readCollapsed()
    this.groups().forEach(group => {
      if (names.includes(group.dataset.category ?? '')) this.setCollapsed(group, true)
    })
  }

  private setCollapsed (group: HTMLElement, collapsed: boolean): void {
    group.toggleAttribute('data-collapsed', collapsed)
    const button = group.querySelector<HTMLButtonElement>('.uplink-category')
    button?.setAttribute('aria-expanded', String(!collapsed))
    const glyph = button?.querySelector('.uplink-category-glyph')
    if (glyph) glyph.textContent = collapsed ? '[+]' : '[-]'
    group.querySelectorAll<HTMLElement>('.uplink-channel').forEach(row => { row.hidden = collapsed && !this.keptRow(row) })
    this.syncRoving()
  }

  // The rows a collapsed category keeps showing: the one on screen and the unread ones.
  private keptRow (row: HTMLElement): boolean {
    return row.matches('.uplink-channel--active, .uplink-channel--unread, .uplink-channel--mention')
  }

  private readCollapsed (): string[] {
    try {
      const parsed: unknown = JSON.parse(this.read(COLLAPSED_KEY) ?? '[]')
      return Array.isArray(parsed) ? parsed.filter((name): name is string => typeof name === 'string') : []
    } catch {
      return []
    }
  }

  private storeCollapsed (): void {
    const names = this.groups().filter(group => group.hasAttribute('data-collapsed')).map(group => group.dataset.category ?? '')
    this.store(COLLAPSED_KEY, JSON.stringify(names))
  }

  private groups (): HTMLElement[] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('.uplink-category-group'))
  }

  // Headings + shown rows, in sidebar order.
  private ring (): HTMLElement[] {
    return Array.from(this.sidebarTarget.querySelectorAll<HTMLElement>('.uplink-category, a.uplink-channel')).filter(el => !el.hidden)
  }

  private setRoving (stop: HTMLElement): void {
    this.ring().forEach(item => { item.tabIndex = item === stop ? 0 : -1 })
  }

  // The stop: the active row when shown, else the current stop if still shown, else the first item.
  private syncRoving (): void {
    const ring = this.ring()
    if (ring.length === 0) return
    const current = ring.find(el => el.getAttribute('tabindex') === '0')
    this.setRoving(ring.find(el => el.classList.contains('uplink-channel--active')) ?? current ?? ring[0]!)
  }

  // ── Quick switcher (Ctrl/Cmd+K) ────────────────────────────────────

  openSwitcher (): void {
    if (!this.hasSwitcherTarget) return
    this.switcherReturn = document.activeElement instanceof HTMLElement ? document.activeElement : null
    this.switcherTarget.hidden = false
    this.switcherFieldTarget.value = ''
    this.renderSwitcher('')
    this.switcherFieldTarget.focus()
  }

  closeSwitcher = (): void => {
    if (!this.hasSwitcherTarget || this.switcherTarget.hidden) return
    this.switcherTarget.hidden = true
    const back = this.switcherReturn
    this.switcherReturn = null
    if (back?.isConnected) back.focus()
  }

  switcherInput (): void {
    this.renderSwitcher(this.switcherFieldTarget.value)
  }

  switcherKey (event: KeyboardEvent): void {
    if (event.defaultPrevented) return
    const options = this.switcherOptions()
    switch (event.key) {
    case 'ArrowDown': this.selectOption((this.switcherIndex + 1) % Math.max(options.length, 1)); break
    case 'ArrowUp': this.selectOption((this.switcherIndex - 1 + options.length) % Math.max(options.length, 1)); break
    case 'Enter': this.pickOption(options[this.switcherIndex]); break
    case 'Escape':
    case 'Tab': this.closeSwitcher(); break
    default: return
    }
    event.preventDefault()
  }

  switcherPick (event: Event): void {
    if (!(event.target instanceof Element)) return
    const option = event.target.closest<HTMLElement>('.uplink-switcher-option')
    if (option) this.pickOption(option)
  }

  // A press on the scrim closes; one inside the box must not take the field's focus.
  switcherOutside (event: MouseEvent): void {
    if (event.target === this.switcherTarget) {
      this.closeSwitcher()
    } else if (!(event.target instanceof HTMLInputElement)) {
      event.preventDefault()
    }
  }

  private renderSwitcher (raw: string): void {
    const query = raw.trim().replace(/^#/, '').toLowerCase()
    const list = this.switcherListTarget
    list.replaceChildren()
    const rows = Array.from(this.sidebarTarget.querySelectorAll<HTMLAnchorElement>('a.uplink-channel'))
    const ranked = rows.map(row => ({ row, rank: this.switcherRank(row, query) })).filter(item => item.rank > 0)
    ranked.sort((a, b) => b.rank - a.rank) // stable: sidebar order within a rank
    ranked.slice(0, SWITCHER_MAX).forEach(({ row }) => list.appendChild(this.switcherOption(row)))
    if (ranked.length === 0) {
      const empty = document.createElement('li')
      empty.className = 'uplink-switcher-empty'
      empty.textContent = 'NO CHANNEL MATCHES'
      list.appendChild(empty)
    }
    this.selectOption(0)
  }

  // 3: the name starts with the query, 2: contains it, 1: its category does (or no query), 0: out.
  private switcherRank (row: HTMLAnchorElement, query: string): number {
    if (!query) return 1
    const name = this.channelName(row).toLowerCase().replace(/^#/, '')
    if (name.startsWith(query)) return 3
    if (name.includes(query)) return 2
    return this.channelCategory(row).toLowerCase().includes(query) ? 1 : 0
  }

  private switcherOption (row: HTMLAnchorElement): HTMLLIElement {
    const option = document.createElement('li')
    option.className = 'uplink-switcher-option'
    option.setAttribute('role', 'option')
    option.id = `uplink-switcher-option-${row.dataset.channel ?? ''}`
    option.dataset.href = row.getAttribute('href') ?? ''
    option.dataset.channel = row.dataset.channel ?? ''
    const parts: Array<[string, string]> = [['uplink-switcher-cat', this.channelCategory(row)], ['uplink-switcher-name', this.channelName(row)]]
    if (row.classList.contains('uplink-channel--active')) parts.push(['uplink-switcher-here', 'HERE'])
    const badge = row.querySelector<HTMLElement>('.uplink-channel-badge')
    if (badge && !badge.hidden && badge.textContent) parts.push(['uplink-switcher-badge', badge.textContent])
    parts.forEach(([className, text]) => {
      const span = document.createElement('span')
      span.className = className
      span.textContent = text
      option.appendChild(span)
    })
    return option
  }

  private selectOption (index: number): void {
    const options = this.switcherOptions()
    this.switcherIndex = options.length > 0 ? Math.min(index, options.length - 1) : 0
    options.forEach((option, i) => option.setAttribute('aria-selected', String(i === this.switcherIndex)))
    const selected = options[this.switcherIndex]
    if (selected) {
      this.switcherFieldTarget.setAttribute('aria-activedescendant', selected.id)
    } else {
      this.switcherFieldTarget.removeAttribute('aria-activedescendant')
    }
  }

  private pickOption (option: HTMLElement | undefined): void {
    if (!option) return
    const href = option.dataset.href
    const here = option.dataset.channel === this.channelValue
    this.closeSwitcher()
    if (href && !here) Turbo.visit(href)
  }

  private switcherOptions (): HTMLElement[] {
    return Array.from(this.switcherListTarget.querySelectorAll<HTMLElement>('.uplink-switcher-option'))
  }

  private channelName (row: HTMLElement): string {
    return (row.querySelector('.uplink-channel-name') ?? row).textContent?.trim() ?? ''
  }

  private channelCategory (row: HTMLElement): string {
    return row.closest<HTMLElement>('.uplink-category-group')?.dataset.category ?? ''
  }

  // ── Search face ────────────────────────────────────────────────────

  toggleSearch (): void {
    const showing = this.pane === 'search' && (!this.isMobile || this.drawer === 'members')
    if (showing) {
      this.closeSearch()
    } else {
      this.openSearch()
    }
  }

  closeSearch (): void {
    const wasOpen = this.pane === 'search'
    this.setPane('members')
    if (this.isMobile && this.drawer === 'members') this.setDrawer('')
    if (wasOpen && this.hasSearchToggleTarget) this.searchToggleTarget.focus()
  }

  // Escape in the field closes the face (the popover's and the drawers'
  // Escape handlers on document see it handled).
  searchKey (event: KeyboardEvent): void {
    if (event.key !== 'Escape' || event.defaultPrevented) return
    event.preventDefault()
    this.closeSearch()
  }

  // A hit's link: in place when the log has the packet (the visit
  // swallowed), else the link's own visit opens the log around it.
  locate (event: MouseEvent & ActionEvent): void {
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    if (jumpToPacket(event.params?.id)) event.preventDefault()
  }

  private openSearch (): void {
    this.setPane('search')
    if (this.isMobile) this.setDrawer('members')
    if (this.hasSearchFieldTarget) this.searchFieldTarget.focus()
  }

  private get pane (): Pane {
    return this.element.dataset.pane === 'search' ? 'search' : 'members'
  }

  private setPane (pane: Pane): void {
    this.element.dataset.pane = pane
    if (this.hasSearchToggleTarget) this.searchToggleTarget.setAttribute('aria-pressed', String(pane === 'search'))
  }

  // ── Stage ──────────────────────────────────────────────────────────

  toggleStage (): void {
    if (!this.hasStageTarget) return
    const collapsed = !this.stageTarget.classList.contains('uplink-stage--collapsed')
    this.setStage(collapsed)
    this.store(STAGE_KEY, collapsed ? 'closed' : 'open')
  }

  // ── Log ────────────────────────────────────────────────────────────

  logState (event: CustomEvent<{ atBottom: boolean, unread: number, mentions?: number, atPresent?: boolean }>): void {
    const { atBottom, unread } = event.detail
    const mentions = event.detail.mentions ?? 0
    this.present = event.detail.atPresent ?? true
    this.hereUnread = unread
    this.hereMentions = mentions
    this.updateTitle()
    if (atBottom && this.present) this.scheduleAck()
    const show = !this.present || (!atBottom && unread > 0)
    this.jumpTarget.hidden = !show
    this.jumpTarget.classList.toggle('uplink-jump--present', !this.present)
    this.jumpTarget.classList.toggle('uplink-jump--mention', show && this.present && mentions > 0)
    if (!show) return
    if (!this.present) {
      this.jumpCountTarget.textContent = 'JUMP TO PRESENT'
      return
    }
    const packets = `${unread} NEW PACKET${unread === 1 ? '' : 'S'}`
    this.jumpCountTarget.textContent = mentions > 0 ? `@ MENTION · ${packets}` : packets
  }

  // The bottom of the log — or, on a located log, the present itself.
  jump (): void {
    if (!this.present && this.presentUrlValue) {
      Turbo.visit(this.presentUrlValue)
      return
    }
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
    const row = this.row(slug)
    if (!row) return
    row.classList.add('uplink-channel--mention') // the packet's bump shows the count
    row.hidden = false // out of a collapsed category
    this.updateTitle()
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
    row.hidden = false // out of a collapsed category
    this.updateTitle()
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

  // ── Tab title ──────────────────────────────────────────────────────

  // "(N) Uplink — hackr.tv" while packets wait: the sidebar badges plus
  // this channel's unread (the pill's count), "(@N)" when one @mentions
  // the viewer; the plain title when nothing does.
  private updateTitle (): void {
    let total = this.hereUnread
    let mention = this.hereMentions > 0
    this.element.querySelectorAll<HTMLElement>('.uplink-channel-badge').forEach(badge => {
      if (badge.hidden) return
      total += Number(badge.dataset.count ?? 0) || 0
      if (badge.closest('.uplink-channel--mention')) mention = true
    })
    const count = total > BADGE_CAP ? `${BADGE_CAP}+` : String(total)
    this.titled = total > 0 ? `(${mention ? '@' : ''}${count}) ${this.baseTitle}` : this.baseTitle
    document.title = this.titled
  }

  // ── Keys ───────────────────────────────────────────────────────────

  hotkey (event: KeyboardEvent): void {
    if (event.defaultPrevented) return
    if ((event.ctrlKey || event.metaKey) && !event.altKey && event.key.toLowerCase() === 'k') {
      if (!this.hasSwitcherTarget) return
      event.preventDefault()
      if (this.switcherTarget.hidden) {
        this.openSwitcher()
      } else {
        this.closeSwitcher()
      }
      return
    }
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
    const stop = name === 'sidebar' ? this.ring().find(el => el.getAttribute('tabindex') === '0') : undefined // the list's Tab stop (the active row)
    ;(stop ?? pane.querySelector<HTMLElement>('a, button'))?.focus()
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
