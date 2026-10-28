import { Controller } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import { writeCookie } from '~/utils/cookie'
import { WIDE_MIN_WIDTH } from '~/utils/wireLayout'

// The WIRE's view switch (ledger ⇄ MUTT; .wire-page[data-view]) and
// MUTT mode's own chrome. v / the bar's [≡] writes the wire_view cookie
// and revisits in place — WireController renders the chosen shell from
// the first byte; MUTT is entered from WIDE_MIN_WIDTH up only. In MUTT:
// live arrivals (entries the feed did not hold at connect, not the
// viewer's own sends) are flagged N until the cursor reads them, and the
// status line follows the cursor, arrivals and deletes.
const COOKIE = 'wire_view'
const FILL = '-'.repeat(400)

export default class extends Controller<HTMLElement> {
  static targets = ['status']
  static values = { total: Number }

  declare readonly statusTarget: HTMLElement
  declare readonly hasStatusTarget: boolean
  declare readonly totalValue: number

  private observer: MutationObserver | null = null
  private seen = new Set<string>()
  private entriesAtConnect = 0

  connect (): void {
    if (!this.mutt()) return
    this.element.querySelectorAll<HTMLElement>('turbo-frame.wire-thread').forEach(frame => {
      frame.removeAttribute('src')
      frame.innerHTML = ''
    })
    const feed = this.element.querySelector('#wire-feed')
    if (feed) {
      this.seen = new Set(this.entries().map(entry => entry.id))
      this.entriesAtConnect = this.seen.size
      this.observer = new MutationObserver(records => this.arrived(records))
      this.observer.observe(feed, { childList: true })
    }
    this.renderStatus()
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = null
  }

  // [≡] MUTT / [≡] LEDGER, the v key (wire-keys:view).
  toggle (): void {
    const toMutt = !this.mutt()
    if (toMutt && window.innerWidth < WIDE_MIN_WIDTH) return
    writeCookie(COOKIE, toMutt ? 'mutt' : 'ledger')
    Turbo.visit(window.location.href, { action: 'replace' })
  }

  // wire:cursor — the cursor reads a row: its N clears.
  cursor (event: Event): void {
    const row = event.target
    if (row instanceof HTMLElement) row.classList.remove('wire-row--new')
    this.renderStatus()
  }

  private mutt (): boolean {
    return this.element.dataset.view === 'mutt'
  }

  // Direct children of #wire-feed come and go only through prepends
  // (own sends + broadcasts) and removes — lazy pages render in sibling
  // frames, day separators are not entries. An own send arrives twice
  // (the form's stream, then the broadcast re-adding the same id), so
  // ids are remembered and the viewer's own pulses are never N.
  private arrived (records: MutationRecord[]): void {
    const viewer = document.querySelector<HTMLMetaElement>('meta[name="current-hackr-id"]')?.content
    for (const record of records) {
      for (const node of Array.from(record.addedNodes)) {
        if (!(node instanceof HTMLElement) || !node.classList.contains('wire-entry') || this.seen.has(node.id)) continue
        this.seen.add(node.id)
        const row = node.querySelector<HTMLElement>('.wire-row')
        if (row && row.dataset.wireRowOwnerIdValue !== viewer) row.classList.add('wire-row--new')
      }
    }
    this.renderStatus()
  }

  private entries (): HTMLElement[] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('#wire-feed > .wire-entry'))
  }

  private renderStatus (): void {
    if (!this.hasStatusTarget) return
    const rows = Array.from(this.element.querySelectorAll('.wire-index .wire-row'))
    const at = rows.findIndex(row => row.classList.contains('wire-row--cursor'))
    const unread = this.element.querySelectorAll('.wire-index .wire-row--new').length
    const position = at < 0 ? '-' : String(at + 1)
    const pct = at < 0 || rows.length === 0 ? '-' : `${Math.round(((at + 1) / rows.length) * 100)}%`
    const fill = document.createElement('span')
    fill.className = 'wire-mutt-fill'
    fill.textContent = FILL
    const total = this.totalValue + this.entries().length - this.entriesAtConnect
    this.statusTarget.replaceChildren(
      `-*-WIRE: ALL TRAFFIC [Pulses:${total} New:${unread}]`,
      fill,
      `(${position}/${rows.length})---(${pct})---`
    )
  }
}
