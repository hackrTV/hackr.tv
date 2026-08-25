import { Controller } from '@hotwired/stimulus'

// Per-viewer state for pulse cards. Broadcast-inserted cards render
// viewer-neutral (no session), so on connect this controller:
//   1. reveals login-only controls (splice) when a viewer is present,
//      and owner-only controls (delete) when the viewer owns the pulse
//      — read from the layout's current-hackr meta tags;
//   2. rewrites descendant form CSRF tokens from the page meta — forms
//      rendered by Turbo::StreamsChannel carry the renderer session's
//      token, which the viewer's session would reject.
export default class extends Controller<HTMLElement> {
  static targets = ['loginOnly', 'ownerOnly', 'replyForm']
  static values = { ownerId: Number }

  declare readonly loginOnlyTargets: HTMLElement[]
  declare readonly ownerOnlyTargets: HTMLElement[]
  declare readonly replyFormTargets: HTMLElement[]
  declare readonly ownerIdValue: number

  connect (): void {
    const viewerId = this.currentHackrId()
    if (viewerId !== null) {
      this.loginOnlyTargets.forEach(el => { el.hidden = false })
      if (viewerId === this.ownerIdValue) {
        this.ownerOnlyTargets.forEach(el => { el.hidden = false })
      }
    }
    this.fixCsrfTokens()
  }

  toggleReply (): void {
    this.replyFormTargets.forEach(el => {
      el.hidden = !el.hidden
      if (!el.hidden) el.querySelector('textarea')?.focus()
    })
  }

  private currentHackrId (): number | null {
    const meta = document.querySelector<HTMLMetaElement>('meta[name="current-hackr-id"]')
    return meta?.content ? Number(meta.content) : null
  }

  private fixCsrfTokens (): void {
    const token = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content
    if (!token) return
    this.element.querySelectorAll<HTMLInputElement>('input[name="authenticity_token"]').forEach(input => {
      input.value = token
    })
  }
}
