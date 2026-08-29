import { Controller } from '@hotwired/stimulus'

// Track reorder for the playlist detail table. dnd-kit is replaced by
// hand-rolled HTML5 drag on desktop plus ↑/↓ move buttons (which also
// cover touch — HTML5 drag doesn't fire on mobile). Every change POSTs
// the full track-id order to the surviving API reorder endpoint and
// renumbers the position cells optimistically; on failure the page
// reloads to resync with the server.

export default class extends Controller {
  static targets = ['body', 'position']
  static values = { url: String }

  declare readonly bodyTarget: HTMLTableSectionElement
  declare readonly positionTargets: HTMLElement[]
  declare urlValue: string

  private dragging: HTMLTableRowElement | null = null

  connect (): void {
    this.bodyTarget.addEventListener('dragstart', this.onDragStart)
    this.bodyTarget.addEventListener('dragover', this.onDragOver)
    this.bodyTarget.addEventListener('drop', this.onDrop)
    this.bodyTarget.addEventListener('dragend', this.onDragEnd)
  }

  disconnect (): void {
    this.bodyTarget.removeEventListener('dragstart', this.onDragStart)
    this.bodyTarget.removeEventListener('dragover', this.onDragOver)
    this.bodyTarget.removeEventListener('drop', this.onDrop)
    this.bodyTarget.removeEventListener('dragend', this.onDragEnd)
  }

  private readonly onDragStart = (event: DragEvent): void => {
    const row = (event.target as HTMLElement).closest('tr')
    if (!row) return
    this.dragging = row as HTMLTableRowElement
    row.classList.add('playlist-table__row--dragging')
    event.dataTransfer?.setData('text/plain', '')
    if (event.dataTransfer) event.dataTransfer.effectAllowed = 'move'
  }

  private readonly onDragOver = (event: DragEvent): void => {
    if (!this.dragging) return
    event.preventDefault()
    const over = (event.target as HTMLElement).closest('tr')
    if (!over || over === this.dragging) return

    const rows = Array.from(this.bodyTarget.rows)
    const fromIndex = rows.indexOf(this.dragging)
    const toIndex = rows.indexOf(over as HTMLTableRowElement)
    if (fromIndex < toIndex) {
      over.after(this.dragging)
    } else {
      over.before(this.dragging)
    }
  }

  private readonly onDrop = (event: DragEvent): void => {
    event.preventDefault()
  }

  private readonly onDragEnd = (): void => {
    if (!this.dragging) return
    this.dragging.classList.remove('playlist-table__row--dragging')
    this.dragging = null
    this.persistOrder()
  }

  moveUp (event: Event): void {
    const row = (event.currentTarget as HTMLElement).closest('tr')
    const previous = row?.previousElementSibling
    if (row && previous) {
      previous.before(row)
      this.persistOrder()
    }
  }

  moveDown (event: Event): void {
    const row = (event.currentTarget as HTMLElement).closest('tr')
    const next = row?.nextElementSibling
    if (row && next) {
      next.after(row)
      this.persistOrder()
    }
  }

  private persistOrder (): void {
    this.renumber()
    const trackIds = Array.from(this.bodyTarget.rows)
      .map((row) => Number(row.dataset.trackRefId))

    fetch(this.urlValue, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ track_ids: trackIds })
    }).then((response) => {
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
    }).catch((err) => {
      console.error('Failed to reorder tracks:', err)
      alert('Failed to save new track order')
      window.location.reload()
    })
  }

  private renumber (): void {
    this.positionTargets.forEach((cell) => {
      const row = cell.closest('tr')
      if (row) cell.textContent = String(row.rowIndex)
    })
  }
}
