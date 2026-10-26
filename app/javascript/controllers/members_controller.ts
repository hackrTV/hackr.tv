import { Controller } from '@hotwired/stimulus'
import { isModerator, outranks } from '~/utils/uplinkRoles'

// Operatives roster (uplink/_members). Rows are anonymized callsigns —
// the roster is broadcast viewer-neutral — so on every connect (initial
// render and each Turbo Stream replace) this reveals, from the page
// metas (uplink-callsign: the viewer's own token, set by the layouts;
// current-hackr-alias; current-hackr-role):
//   - the viewer's own row, as their real alias;
//   - for operators/admins, the hover […] operator-menu button on the
//     rows they outrank (data-role) — never their own. Cosmetic: the
//     server re-checks jurisdiction and resolves the callsign itself.
// Nothing else is identifiable.
export default class extends Controller<HTMLElement> {
  connect (): void {
    const token = this.meta('uplink-callsign')
    if (!token || !/^[0-9A-F]+$/i.test(token)) return
    this.revealSelf(token, this.meta('current-hackr-alias'))
    this.revealModeration(token, this.meta('current-hackr-role'))
  }

  private revealSelf (token: string, alias: string | null): void {
    if (!alias) return
    const row = this.element.querySelector<HTMLElement>(`[data-callsign="${token}"]`)
    if (!row) return
    row.classList.add('uplink-member--self')
    row.title = 'You'
    const name = row.querySelector<HTMLElement>('.uplink-member-name')
    if (name) name.textContent = `@${alias}`
  }

  private revealModeration (token: string, role: string | null): void {
    if (!isModerator(role)) return
    this.element.querySelectorAll<HTMLElement>('.uplink-member[data-callsign]').forEach(row => {
      if (row.dataset.callsign === token || !outranks(role, row.dataset.role)) return
      const button = row.querySelector<HTMLElement>('.uplink-member-mod')
      if (button) button.hidden = false
    })
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }
}
