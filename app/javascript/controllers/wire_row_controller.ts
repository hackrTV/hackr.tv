import { Controller } from '@hotwired/stimulus'
import { localizeTimeElement } from '~/utils/localTime'

// Per-viewer state for a WIRE ledger row (wire/_pulse_row) and its
// inline thread. Broadcast-inserted rows render viewer-neutral (no
// session), so on connect this controller:
//   1. reveals the owner-only delete form when the viewer owns the
//      pulse — read from the layout's current-hackr-id meta — and
//      classes the row --own (MUTT's F flag);
//   2. rewrites descendant form CSRF tokens from the page meta — forms
//      rendered by Turbo::StreamsChannel carry the renderer session's
//      token, which the viewer's session would reject;
//   3. localizes the HH:MM stamps (server-rendered in its zone).
// The thread frame (pulse_N_thread) is the row's SIBLING, found by the
// row's data-thread-frame: the ↩ link loads it through Turbo on the
// first click (data-turbo-frame) and this controller folds/unfolds it
// after that; `o` / `r` from wire-keys arrive as wire:open / wire:reply.
// A row inside a thread list (an inline frame or the context pane) has
// no frame of its own — its ↩ aims the enclosing thread's reply prompt
// at this pulse instead.
// Thread opens (↩ / o / r on a root) and plain author clicks are first
// OFFERED to the page's context pane through a cancelable wire-row:pane
// event (detail: url, select, focus); when the pane claims it the row
// does nothing more, otherwise the inline frame / profile visit runs.
export default class extends Controller<HTMLElement> {
  static targets = ['ownerOnly', 'time']
  static values = { ownerId: Number }

  declare readonly ownerOnlyTargets: HTMLElement[]
  declare readonly timeTargets: HTMLTimeElement[]
  declare readonly ownerIdValue: number

  private focusPromptOnLoad = false
  private boundFrame: HTMLElement | null = null
  private readonly frameLoaded = (): void => {
    const frame = this.frame()
    if (!frame) return
    frame.hidden = false
    this.syncExpanded()
    if (this.focusPromptOnLoad) {
      this.focusPromptOnLoad = false
      this.aimPrompt(frame, this.pulseId())
    }
  }

  connect (): void {
    const viewerId = this.currentHackrId()
    if (viewerId !== null && viewerId === this.ownerIdValue) {
      this.ownerOnlyTargets.forEach(el => { el.hidden = false })
      this.element.classList.add('wire-row--own')
    }
    this.fixCsrfTokens()
    this.localizeTimes()
    this.boundFrame = this.frame()
    this.boundFrame?.addEventListener('turbo:frame-load', this.frameLoaded)
    this.syncExpanded()
  }

  disconnect (): void {
    this.boundFrame?.removeEventListener('turbo:frame-load', this.frameLoaded)
    this.boundFrame = null
  }

  // ↩ on a root row: the first click is a plain frame navigation (Turbo
  // fetches the thread into the frame); later clicks fold/unfold.
  toggleThread (event: Event): void {
    if (this.offerThread()) {
      event.preventDefault()
      return
    }
    const frame = this.frame()
    if (!frame || !this.loaded(frame)) return
    event.preventDefault()
    this.fold(frame)
  }

  // wire:open (the `o` key).
  openThread (): void {
    if (this.offerThread()) return
    const frame = this.frame()
    if (!frame) return
    if (!this.loaded(frame)) {
      this.spliceLink()?.click()
      return
    }
    this.fold(frame)
  }

  // ↩ on a thread row / wire:reply (the `r` key): aim the thread's
  // prompt at this pulse — a reply row names itself, a root row resets
  // the prompt to itself (opening the thread first when still folded).
  reply (): void {
    const thread = this.element.closest<HTMLElement>('turbo-frame.wire-thread, turbo-frame#wire-pane')
    if (thread) {
      const alias = this.element.querySelector('.wire-author')?.textContent?.trim()
      this.aimPrompt(thread, this.pulseId(), alias)
      return
    }
    if (this.offerThread(true)) return
    const frame = this.frame()
    if (!frame) return
    if (!this.loaded(frame)) {
      this.focusPromptOnLoad = true
      this.spliceLink()?.click()
      return
    }
    if (frame.hidden) this.fold(frame)
    this.aimPrompt(frame, this.pulseId())
  }

  // A plain click on the author link: the pane shows the record when it
  // claims the offer; modified clicks always reach the profile page.
  author (event: MouseEvent): void {
    if (event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    const href = (event.currentTarget as HTMLElement).getAttribute('href')
    if (href && this.offer({ url: href })) event.preventDefault()
  }

  // Root rows only (the ones with an inline frame): a reply row inside
  // an open thread keeps its own ↩ / o behavior.
  private offerThread (focus = false): boolean {
    if (!this.element.dataset.threadFrame) return false
    const id = this.pulseId()
    const url = this.spliceLink()?.getAttribute('href') ?? `/wire/pulse/${id}` // wire-pane's threadUrl
    return this.offer({ url, select: id, focus })
  }

  private offer (detail: { url: string, select?: string, focus?: boolean }): boolean {
    return this.dispatch('pane', { detail, cancelable: true }).defaultPrevented
  }

  private fold (frame: HTMLElement): void {
    frame.hidden = !frame.hidden
    this.syncExpanded()
  }

  // Without an alias the prompt goes back to its default placeholder
  // (the root's); composer#submitted resets the same way after a send.
  private aimPrompt (frame: HTMLElement, parentId: string, alias?: string): void {
    const input = frame.querySelector<HTMLTextAreaElement>('.wire-prompt-input')
    const parentField = frame.querySelector<HTMLInputElement>('input[name="parent_pulse_id"]')
    if (!input || !parentField) return
    parentField.value = parentId
    input.placeholder = alias ? `Reply to ${alias}...` : (input.dataset.defaultPlaceholder ?? input.placeholder)
    input.focus()
  }

  private pulseId (): string {
    return this.element.dataset.pulseId ?? ''
  }

  private syncExpanded (): void {
    const frame = this.frame()
    const link = this.spliceLink()
    if (!link) return
    const open = !!frame && this.loaded(frame) && !frame.hidden
    link.setAttribute('aria-expanded', open ? 'true' : 'false')
  }

  private loaded (frame: HTMLElement): boolean {
    return frame.children.length > 0
  }

  private frame (): HTMLElement | null {
    const id = this.element.dataset.threadFrame
    return id ? document.getElementById(id) : null
  }

  private spliceLink (): HTMLElement | null {
    return this.element.querySelector<HTMLElement>('.splice-button')
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

  private localizeTimes (): void {
    this.timeTargets.forEach(el => localizeTimeElement(el))
  }
}
