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
//     from the log; the viewer's own sends always jump to the bottom;
//   - "/" focuses the composer from anywhere outside a field.
// State lives on the shell root (data-members / data-drawer), so the
// roster being replaced by a broadcast never resets it.

const MOBILE_QUERY = '(max-width: 767px)'
const MEMBERS_OPEN_MIN_WIDTH = 1100
const MEMBERS_KEY = 'uplink:members'
const STAGE_KEY = 'uplink:stage'

type Drawer = '' | 'sidebar' | 'members'

export default class extends Controller<HTMLElement> {
  static targets = ['sidebar', 'members', 'main', 'jump', 'jumpCount', 'membersToggle', 'stage', 'stageFrame', 'stageToggle']

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

  private mobile: MediaQueryList | null = null

  connect (): void {
    this.applyMembersPreference()
    this.applyStagePreference()
    this.mobile = typeof window.matchMedia === 'function' ? window.matchMedia(MOBILE_QUERY) : null
    this.mobile?.addEventListener('change', this.closeDrawers)
    document.addEventListener('turbo:before-cache', this.closeDrawers)
    this.autofocusComposer()
  }

  disconnect (): void {
    this.mobile?.removeEventListener('change', this.closeDrawers)
    this.mobile = null
    document.removeEventListener('turbo:before-cache', this.closeDrawers)
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

  logState (event: CustomEvent<{ atBottom: boolean, unread: number }>): void {
    const { atBottom, unread } = event.detail
    const show = !atBottom && unread > 0
    this.jumpTarget.hidden = !show
    if (show) this.jumpCountTarget.textContent = `${unread} NEW PACKET${unread === 1 ? '' : 'S'}`
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
