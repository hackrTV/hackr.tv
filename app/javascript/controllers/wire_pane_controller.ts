import { Controller } from '@hotwired/stimulus'
import { localizeTimeElement } from '~/utils/localTime'
import { readCookie, writeCookie } from '~/utils/cookie'
import { WIDE_MIN_WIDTH, WIDE_QUERY } from '~/utils/wireLayout'

// The feed's context pane: a column beside the ledger (viewports ≥
// WIDE_MIN_WIDTH; open by default from OPEN_DEFAULT_MIN_WIDTH, remembered
// in the wire_pane cookie the server renders from) showing the selected
// root's thread or an operative's record, loaded into
// turbo-frame#wire-pane from the same URLs the rows link to
// (WireController branches on the frame id). Mounted on .wire-page
// beside wire-keys and wire-feed; open → data-pane="open". In MUTT mode
// (.wire-page[data-view="mutt"]) the pane is the pager: always on, the
// toggles inert.
// Rows OFFER their loads through a cancelable wire-row:pane event: an
// active pane claims it (preventDefault + load), otherwise the row's
// inline frame / profile visit runs. wire-keys' wire:cursor is followed
// after FOLLOW_MS (mutt's index + pager); wire-keys:pane toggles. The
// selected row carries .wire-row--sel and is watched: gone → the pane
// empties, replaced (a drop) → it reloads. Loading a root empties its
// inline frame (opened while the pane was closed): one thread list per
// root, or the streams would hit the inline copy first. A Turbo cache
// restore brings the frame back with its src; the selection is
// re-marked from it.
const OPEN_DEFAULT_MIN_WIDTH = 1280
const COOKIE = 'wire_pane'
const FOLLOW_MS = 200
const THREAD_PATH = /^\/wire\/pulse\/(\d+)$/

interface Load { url: string, select?: string | null, focus?: boolean }

// wire-row builds the same path for its offers.
const threadUrl = (id: string): string => `/wire/pulse/${id}`

export default class extends Controller<HTMLElement> {
  static targets = ['frame', 'toggle', 'stamp']

  declare readonly frameTarget: HTMLElement
  declare readonly hasFrameTarget: boolean
  declare readonly toggleTarget: HTMLElement
  declare readonly hasToggleTarget: boolean

  private open = false
  private media: MediaQueryList | null = null
  private selectedId: string | null = null
  private pendingFocus = false
  private followTimer: number | null = null
  private observer: MutationObserver | null = null

  private readonly mediaChanged = (): void => { this.apply() }
  private readonly frameLoaded = (): void => {
    if (!this.pendingFocus) return
    this.pendingFocus = false
    this.focusPrompt()
  }

  connect (): void {
    this.clearMarks()
    this.media = typeof window.matchMedia === 'function' ? window.matchMedia(WIDE_QUERY) : null
    this.media?.addEventListener('change', this.mediaChanged)
    const stored = readCookie(COOKIE)
    this.open = stored ? stored === 'open' : window.innerWidth >= OPEN_DEFAULT_MIN_WIDTH
    if (!stored) this.store() // the first visit's default is the choice until changed — rendered first-paint next time
    this.apply()
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener('turbo:frame-load', this.frameLoaded)
      this.restoreSelection()
    }
    const feed = this.element.querySelector('#wire-feed')
    if (feed) {
      this.observer = new MutationObserver(records => this.feedChanged(records))
      this.observer.observe(feed, { childList: true, subtree: true })
    }
  }

  disconnect (): void {
    this.media?.removeEventListener('change', this.mediaChanged)
    this.media = null
    if (this.hasFrameTarget) this.frameTarget.removeEventListener('turbo:frame-load', this.frameLoaded)
    this.observer?.disconnect()
    this.observer = null
    this.cancelFollow()
  }

  // The pane root's full stamp (pane.html.erb) — rows localize their own.
  stampTargetConnected (el: HTMLTimeElement): void {
    localizeTimeElement(el, 'full')
  }

  // [>] CONTEXT, the c key (wire-keys:pane). Opening onto a cursor row
  // shows that thread right away.
  toggle (): void {
    if (this.mutt()) return
    this.setOpen(!this.open)
    if (!this.active()) return
    const cursor = this.element.querySelector<HTMLElement>('.wire-row--cursor')
    if (cursor?.dataset.threadFrame && cursor.dataset.pulseId) {
      this.load({ url: threadUrl(cursor.dataset.pulseId), select: cursor.dataset.pulseId })
    }
  }

  // The pane's [x].
  close (): void {
    if (this.mutt()) return
    this.setOpen(false)
  }

  // wire-row:pane — a row offers a load; an active pane takes it.
  claim (event: CustomEvent<Load>): void {
    if (!this.active()) return
    event.preventDefault()
    this.load(event.detail)
  }

  // A plain click on the root block's author link: the record replaces
  // the thread (the record's own links are plain visits).
  author (event: MouseEvent): void {
    if (!this.active() || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    const href = (event.currentTarget as HTMLElement).getAttribute('href')
    if (!href) return
    event.preventDefault()
    this.load({ url: href, select: null })
  }

  // wire:cursor from wire-keys: follow root rows after a beat.
  follow (event: Event): void {
    const row = event.target
    if (!this.active() || !(row instanceof HTMLElement)) return
    const id = row.dataset.pulseId
    if (!row.dataset.threadFrame || !id) return
    this.cancelFollow()
    this.followTimer = window.setTimeout(() => {
      this.followTimer = null
      this.load({ url: threadUrl(id), select: id })
    }, FOLLOW_MS)
  }

  private load ({ url, select = null, focus = false }: Load): void {
    this.cancelFollow()
    if (!this.hasFrameTarget) return
    const frame = this.frameTarget
    const shown = select !== null && select === this.selectedId && frame.children.length > 0 && this.current() === this.resolve(url)
    if (select !== null) this.foldInline(select)
    this.select(select)
    if (shown) {
      if (focus) this.focusPrompt()
      return
    }
    this.pendingFocus = focus
    frame.removeAttribute('src') // a fresh src always loads (the same URL again included)
    frame.setAttribute('src', url)
  }

  // The row's inline copy of the thread, if it was expanded while the
  // pane was closed: emptied without its src, so a later ↩ (pane closed
  // again) is a fresh frame navigation.
  private foldInline (id: string): void {
    const frame = document.getElementById(`pulse_${id}_thread`)
    if (!frame) return
    frame.removeAttribute('src')
    frame.innerHTML = ''
    frame.hidden = false
    document.getElementById(`pulse_${id}`)?.querySelector('.splice-button')?.setAttribute('aria-expanded', 'false')
  }

  private reload (): void {
    if (!this.hasFrameTarget) return
    const src = this.frameTarget.getAttribute('src')
    if (!src) return
    this.frameTarget.removeAttribute('src')
    this.frameTarget.setAttribute('src', src)
  }

  private select (id: string | null): void {
    this.selectedId = id
    this.clearMarks()
    if (id) document.getElementById(`pulse_${id}`)?.classList.add('wire-row--sel')
  }

  private clearMarks (): void {
    this.element.querySelectorAll('.wire-row--sel').forEach(el => el.classList.remove('wire-row--sel'))
  }

  private setOpen (open: boolean): void {
    this.open = open
    this.store()
    this.apply()
  }

  private apply (): void {
    if (this.mutt()) { // the shell's own grid places the pager; data-pane would drag the two-column rules in
      delete this.element.dataset.pane
      return
    }
    const active = this.active()
    if (active) this.element.dataset.pane = 'open'
    else delete this.element.dataset.pane
    if (this.hasToggleTarget) this.toggleTarget.setAttribute('aria-pressed', active ? 'true' : 'false')
    if (!active) this.empty()
  }

  private active (): boolean {
    if (this.mutt()) return true
    return this.open && (this.media ? this.media.matches : window.innerWidth >= WIDE_MIN_WIDTH)
  }

  private mutt (): boolean {
    return this.element.dataset.view === 'mutt'
  }

  private empty (): void {
    this.cancelFollow()
    this.select(null)
    this.pendingFocus = false
    if (!this.hasFrameTarget) return
    this.frameTarget.removeAttribute('src')
    this.frameTarget.innerHTML = ''
  }

  // The selected row left (delete) or was replaced (drop).
  private feedChanged (records: MutationRecord[]): void {
    const id = this.selectedId
    if (!id) return
    const rowId = `pulse_${id}`
    const holds = (node: Node): boolean => node instanceof Element && (node.id === rowId || node.querySelector(`#${rowId}`) !== null)
    const removed = records.some(record => Array.from(record.removedNodes).some(holds))
    const added = records.some(record => Array.from(record.addedNodes).some(holds))
    if (!removed && !added) return
    if (!document.getElementById(rowId)) {
      this.empty()
      return
    }
    this.select(id) // a replace comes without the mark
    if (added) this.reload()
  }

  private restoreSelection (): void {
    if (!this.active()) return
    const src = this.frameTarget.getAttribute('src')
    const match = src ? THREAD_PATH.exec(new URL(src, window.location.href).pathname) : null
    if (match?.[1] && this.frameTarget.children.length > 0) this.select(match[1])
  }

  private focusPrompt (): void {
    this.frameTarget.querySelector<HTMLTextAreaElement>('.wire-prompt-input')?.focus()
  }

  private cancelFollow (): void {
    if (this.followTimer !== null) window.clearTimeout(this.followTimer)
    this.followTimer = null
  }

  private current (): string | null {
    const src = this.frameTarget.getAttribute('src')
    return src ? this.resolve(src) : null
  }

  private resolve (url: string): string {
    return new URL(url, window.location.href).href
  }

  private store (): void {
    writeCookie(COOKIE, this.open ? 'open' : 'closed')
  }
}
