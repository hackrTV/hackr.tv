import { Controller } from '@hotwired/stimulus'

// Day separators for the WIRE feed ("// TODAY · 2026-10-26 //",
// "// 2026-10-25 //"), computed client-side from each entry's data-at so
// they fall on the viewer's local days and survive live prepends and
// lazy page frames (mirrors the Uplink log's client-side grouping).
// Entries inside open threads and the context pane are skipped. Reconciled on connect and
// whenever entries (or the frames that hold them) come and go — not on
// every text change under the page, like the prompt's counter; the
// observer is paused while the separators themselves are written.
export default class extends Controller<HTMLElement> {
  private observer: MutationObserver | null = null
  private scheduled = false

  connect (): void {
    this.observer = new MutationObserver(records => {
      if (records.some(record => this.touchesEntries(record))) this.schedule()
    })
    this.observe()
    this.reconcile()
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.observer = null
  }

  reconcile (): void {
    this.observer?.disconnect()
    this.element.querySelectorAll('.wire-day').forEach(el => el.remove())
    let lastDay: string | null = null
    const today = this.dayKey(new Date())
    for (const entry of this.entries()) {
      const at = Number(entry.dataset.at)
      if (!Number.isFinite(at)) continue
      const day = this.dayKey(new Date(at))
      if (day === lastDay) continue
      lastDay = day
      const sep = document.createElement('div')
      sep.className = 'wire-day'
      sep.setAttribute('role', 'separator')
      sep.textContent = day === today ? `// TODAY · ${day} //` : `// ${day} //`
      entry.before(sep)
    }
    this.observe()
  }

  private entries (): HTMLElement[] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('.wire-entry[data-at]'))
      .filter(entry => !entry.closest('turbo-frame.wire-thread, #wire-pane'))
  }

  private touchesEntries (record: MutationRecord): boolean {
    return [...record.addedNodes, ...record.removedNodes].some(node =>
      node instanceof Element && (node.matches('.wire-entry, turbo-frame') || node.querySelector('.wire-entry') !== null))
  }

  private schedule (): void {
    if (this.scheduled) return
    this.scheduled = true
    queueMicrotask(() => {
      this.scheduled = false
      this.reconcile()
    })
  }

  private observe (): void {
    this.observer?.observe(this.element, { childList: true, subtree: true })
  }

  // Local YYYY-MM-DD.
  private dayKey (date: Date): string {
    const y = date.getFullYear()
    const m = String(date.getMonth() + 1).padStart(2, '0')
    const d = String(date.getDate()).padStart(2, '0')
    return `${y}-${m}-${d}`
  }
}
