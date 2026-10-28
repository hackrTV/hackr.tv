import { Controller } from '@hotwired/stimulus'

// Keyboard layer for the WIRE pages (mounted on .wire-page with
// keydown@document->wire-keys#key): a cursor row moved with j/k (g/G
// first/last) that e/r/o/x act on, / focuses the prompt, ? toggles the
// legend, Escape closes it and clears the cursor. Keys are ignored while
// typing (input/textarea/select/contenteditable) and with a modifier
// held. Rows are re-read from the DOM on every key — broadcasts
// prepend, replace and remove them — and the cursor is kept by id, so a
// replaced row (a drop) stays the cursor; rows inside open inline
// threads are walked in document order, rows inside the context pane
// never (the pane is read, not walked). Every cursor move dispatches
// wire:cursor on the row (the pane follows it); c dispatches
// wire-keys:pane (the pane toggles); a clicks the row's author link
// (record in the pane, else the profile). x is press-twice (1.5s) on
// the owner's own row: no native confirm dialog on a TUI.
const ARM_MS = 1500

export default class extends Controller<HTMLElement> {
  static targets = ['legend']

  declare readonly legendTarget: HTMLElement
  declare readonly hasLegendTarget: boolean

  private cursorId: string | null = null
  private armedId: string | null = null
  private armTimer: number | null = null
  private observer: MutationObserver | null = null

  connect (): void {
    // A Turbo cache restore brings the snapshot's classes back with no
    // controller state behind them.
    this.element.querySelectorAll('.wire-row--cursor, .wire-row--armed')
      .forEach(el => el.classList.remove('wire-row--cursor', 'wire-row--armed'))
    this.closeLegend()
    this.observer = new MutationObserver(() => this.applyCursor())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = null
    this.disarm()
  }

  key (event: KeyboardEvent): void {
    if (event.defaultPrevented || event.ctrlKey || event.metaKey || event.altKey) return
    if (this.inEditable(event.target)) return
    switch (event.key) {
    case 'j': this.move(1); break
    case 'k': this.move(-1); break
    case 'g': this.first(); break
    case 'G': this.last(); break
    case 'e': this.press('.echo-button'); break
    case 'o': this.emit('wire:open'); break
    case 'r': event.preventDefault(); this.emit('wire:reply'); break // a prompt may take focus now: no stray "r"
    case 'a': this.press('.wire-author'); break
    case 'c': this.dispatch('pane'); break
    case 'x': this.deleteCursor(); break
    case '/': event.preventDefault(); this.focusPrompt(); break
    case '?': this.toggleLegend(); break
    case 'Escape': this.escape(); break
    default: return
    }
    if (event.key !== 'x') this.disarm()
  }

  toggleLegend (): void {
    if (this.hasLegendTarget) this.legendTarget.hidden = !this.legendTarget.hidden
  }

  closeLegend (): void {
    if (this.hasLegendTarget) this.legendTarget.hidden = true
  }

  private rows (): HTMLElement[] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('.wire-row'))
      .filter(row => !row.closest('[hidden], #wire-pane') && !row.classList.contains('wire-row--dropped'))
  }

  private cursor (): HTMLElement | null {
    return this.cursorId ? document.getElementById(this.cursorId) : null
  }

  private move (delta: number): void {
    const rows = this.rows()
    if (rows.length === 0) return
    const current = this.cursor()
    const index = current ? rows.indexOf(current) : -1
    const next = index < 0 ? (delta > 0 ? 0 : rows.length - 1) : Math.min(Math.max(index + delta, 0), rows.length - 1)
    this.setCursor(rows[next] ?? null)
  }

  private first (): void {
    this.setCursor(this.rows()[0] ?? null)
  }

  private last (): void {
    const rows = this.rows()
    this.setCursor(rows[rows.length - 1] ?? null)
  }

  private setCursor (row: HTMLElement | null): void {
    this.cursorId = row?.id ?? null
    this.applyCursor()
    row?.scrollIntoView({ block: 'nearest' })
    row?.dispatchEvent(new CustomEvent('wire:cursor', { bubbles: true }))
  }

  private applyCursor (): void {
    this.element.querySelectorAll<HTMLElement>('.wire-row--cursor').forEach(el => {
      if (el.id !== this.cursorId) el.classList.remove('wire-row--cursor')
    })
    this.cursor()?.classList.add('wire-row--cursor')
  }

  private press (selector: string): void {
    this.cursor()?.querySelector<HTMLElement>(selector)?.click()
  }

  private emit (name: string): void {
    this.cursor()?.dispatchEvent(new CustomEvent(name))
  }

  // Owner only (the delete form is revealed by wire-row): the first x
  // arms the row, a second within ARM_MS deletes.
  private deleteCursor (): void {
    const row = this.cursor()
    const button = row?.querySelector<HTMLElement>('.delete-button')
    if (!row || !button || button.closest('form')?.hidden) { this.disarm(); return }
    if (this.armedId === row.id) {
      this.disarm()
      button.click()
      return
    }
    this.disarm()
    this.armedId = row.id
    row.classList.add('wire-row--armed')
    this.armTimer = window.setTimeout(() => this.disarm(), ARM_MS)
  }

  private disarm (): void {
    if (this.armTimer !== null) window.clearTimeout(this.armTimer)
    this.armTimer = null
    if (this.armedId) document.getElementById(this.armedId)?.classList.remove('wire-row--armed')
    this.armedId = null
  }

  private focusPrompt (): void {
    this.element.querySelector<HTMLTextAreaElement>('.wire-prompt-input')?.focus()
  }

  private escape (): void {
    this.closeLegend()
    this.setCursor(null)
  }

  private inEditable (target: EventTarget | null): boolean {
    if (!(target instanceof Element)) return false
    return target.matches('input, textarea, select, [contenteditable="true"]')
  }
}
