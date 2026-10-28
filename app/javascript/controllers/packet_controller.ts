import { Controller } from '@hotwired/stimulus'
import { isModerator, outranks } from '~/utils/uplinkRoles'
import { jumpToPacket } from '~/utils/packetJump'

// Per-viewer state for uplink packets (wire-row pattern).
// Broadcast-inserted packets render viewer-neutral, so on connect this
// controller:
//   1. reveals the drop control for the packet's author and for
//      operators/admins, the restore and pin/unpin controls for
//      operators/admins (pinning is curation: any packet, their own
//      included) — the dock/popout's controls; the shell CSS-hides drop
//      and restore — and the […] packet-menu control for the author
//      (their own packet; once dropped, only if they can restore it)
//      and for operators/admins who outrank the author (bridged/bot
//      packets carry the "bridge" role, below everyone) — read from the
//      layout's current-hackr metas + the packet's author role value
//      (cosmetic only; the server re-checks on every action);
//   2. rewrites descendant form CSRF tokens from the page meta;
//   3. localizes the HH:MM timestamp (Packet.tsx rendered client-local);
//   4. highlights the viewer's own @mentions.
// Replies: the hover control dispatches packet:reply {id, sender} (bubbles
// to document, where the shell composer's packet-form listens — the
// composer is not an ancestor); the quote line's click scrolls the parent
// into view and flashes it when it is in the log (utils/packetJump).

export default class extends Controller<HTMLElement> {
  static targets = ['time', 'dropControl', 'restoreControl', 'pinControl', 'modControl']
  static values = { ownerId: Number, authorRole: String }

  declare readonly timeTargets: HTMLTimeElement[]
  declare readonly dropControlTargets: HTMLElement[]
  declare readonly restoreControlTargets: HTMLElement[]
  declare readonly pinControlTargets: HTMLElement[]
  declare readonly modControlTargets: HTMLElement[]
  declare readonly ownerIdValue: number
  declare readonly authorRoleValue: string

  connect (): void {
    this.localizeTimes()
    this.revealControls()
    this.highlightSelfMentions()
    this.fixCsrfTokens()
  }

  reply (event: Event): void {
    const id = this.packetId()
    if (!id) return
    const sender = event.currentTarget instanceof HTMLElement ? event.currentTarget.dataset.replySender ?? '' : ''
    this.dispatch('reply', { detail: { id, sender } })
  }

  // A parent above the loaded history isn't in the DOM: nothing happens.
  jumpToParent (): void {
    jumpToPacket(this.element.dataset.replyTo)
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
        hourCycle: 'h23' // hour12: false resolves to h24 in Chromium ("24:30")
      })
    })
  }

  private revealControls (): void {
    const viewerId = this.metaNumber('current-hackr-id')
    if (viewerId === null) return
    const role = this.meta('current-hackr-role')
    const moderator = isModerator(role)
    const own = viewerId === this.ownerIdValue
    if (moderator || own) {
      this.dropControlTargets.forEach(el => { el.hidden = false })
    }
    if (moderator) {
      this.restoreControlTargets.forEach(el => { el.hidden = false })
      this.pinControlTargets.forEach(el => { el.hidden = false })
    }
    const dropped = this.element.classList.contains('packet--dropped')
    if ((own && (!dropped || moderator)) || (moderator && !own && outranks(role, this.authorRoleValue))) {
      this.modControlTargets.forEach(el => { el.hidden = false })
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

  private packetId (): string | null {
    const match = this.element.id.match(/(\d+)$/)
    return match ? match[1] : null
  }

  private meta (name: string): string | null {
    return document.querySelector<HTMLMetaElement>(`meta[name="${name}"]`)?.content ?? null
  }

  private metaNumber (name: string): number | null {
    const value = this.meta(name)
    return value ? Number(value) : null
  }
}
