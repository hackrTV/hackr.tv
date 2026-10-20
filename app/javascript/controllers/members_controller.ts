import { Controller } from '@hotwired/stimulus'

// Operatives roster (uplink/_members). Rows are anonymized callsigns —
// the roster is broadcast viewer-neutral — so on every connect (initial
// render and each Turbo Stream replace) this reveals the viewer's own
// row from the page metas: uplink-callsign (their token, set by
// uplink/show) and current-hackr-alias. Nothing else is identifiable.
export default class extends Controller<HTMLElement> {
  connect (): void {
    const token = this.meta('uplink-callsign')
    const alias = this.meta('current-hackr-alias')
    if (!token || !alias || !/^[0-9A-F]+$/i.test(token)) return
    const row = this.element.querySelector<HTMLElement>(`[data-callsign="${token}"]`)
    if (!row) return
    row.classList.add('uplink-member--self')
    row.title = 'You'
    const name = row.querySelector<HTMLElement>('.uplink-member-name')
    if (name) name.textContent = `@${alias}`
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }
}
