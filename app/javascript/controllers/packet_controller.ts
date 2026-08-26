import { Controller } from '@hotwired/stimulus'

// Per-viewer state for uplink packets (pulse-card pattern).
// Broadcast-inserted packets render viewer-neutral, so on connect this
// controller:
//   1. reveals the drop control for the packet's author and for
//      operators/admins, and the restore control for operators/admins —
//      read from the layout's current-hackr metas (cosmetic only; the
//      server re-checks on every action);
//   2. rewrites descendant form CSRF tokens from the page meta;
//   3. localizes the HH:MM timestamp (Packet.tsx rendered client-local);
//   4. highlights the viewer's own @mentions.
export default class extends Controller<HTMLElement> {
  static targets = ['time', 'dropControl', 'restoreControl']
  static values = { ownerId: Number }

  declare readonly timeTargets: HTMLTimeElement[]
  declare readonly dropControlTargets: HTMLElement[]
  declare readonly restoreControlTargets: HTMLElement[]
  declare readonly ownerIdValue: number

  connect (): void {
    this.localizeTimes()
    this.revealControls()
    this.highlightSelfMentions()
    this.fixCsrfTokens()
  }

  private localizeTimes (): void {
    this.timeTargets.forEach(el => {
      const stamp = el.getAttribute('datetime')
      if (!stamp) return
      const date = new Date(stamp)
      if (Number.isNaN(date.getTime())) return
      el.textContent = date.toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
      })
    })
  }

  private revealControls (): void {
    const viewerId = this.metaNumber('current-hackr-id')
    if (viewerId === null) return
    const role = this.meta('current-hackr-role')
    const moderator = role === 'operator' || role === 'admin'
    if (moderator || viewerId === this.ownerIdValue) {
      this.dropControlTargets.forEach(el => { el.hidden = false })
    }
    if (moderator) {
      this.restoreControlTargets.forEach(el => { el.hidden = false })
    }
  }

  private highlightSelfMentions (): void {
    const alias = this.meta('current-hackr-alias')
    if (!alias) return
    this.element.querySelectorAll<HTMLElement>('.uplink-mention').forEach(el => {
      if (el.dataset.alias?.toLowerCase() === alias.toLowerCase()) {
        el.classList.add('uplink-mention--self')
      }
    })
  }

  private fixCsrfTokens (): void {
    const token = this.meta('csrf-token')
    if (!token) return
    this.element.querySelectorAll<HTMLInputElement>('input[name="authenticity_token"]').forEach(input => {
      input.value = token
    })
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }

  private metaNumber (name: string): number | null {
    const value = this.meta(name)
    return value ? Number(value) : null
  }
}
