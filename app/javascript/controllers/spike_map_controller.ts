import { Controller } from '@hotwired/stimulus'

// Phase 0 spike B: pan/zoom/select for the server-rendered SVG zone map.
// Mirrors the React ZoneMap feel targets: wheel zoom (×1.25 steps), drag
// pan, click-to-select. Transform lives on the inner <g> so a Phase 6c
// Turbo Stream replace of tiles can preserve it by leaving the <g> wrapper
// managed here.
export default class extends Controller {
  static targets = ['svg', 'world']

  declare readonly svgTarget: SVGSVGElement
  declare readonly worldTarget: SVGGElement

  private scale = 1
  private tx = 0
  private ty = 0
  private panning = false
  private moved = false
  private lastX = 0
  private lastY = 0

  zoom (event: WheelEvent): void {
    event.preventDefault()
    const factor = event.deltaY < 0 ? 1.25 : 1 / 1.25
    this.scale = Math.min(8, Math.max(0.2, this.scale * factor))
    this.applyTransform()
  }

  panStart (event: PointerEvent): void {
    this.panning = true
    this.moved = false
    this.lastX = event.clientX
    this.lastY = event.clientY
    this.svgTarget.style.cursor = 'grabbing'
  }

  panMove (event: PointerEvent): void {
    if (!this.panning) return
    const dx = event.clientX - this.lastX
    const dy = event.clientY - this.lastY
    if (Math.abs(dx) + Math.abs(dy) > 2) this.moved = true
    // Convert screen px to viewBox units so pan speed matches zoom level
    const viewBox = this.svgTarget.viewBox.baseVal
    const unitPerPx = viewBox.width / this.svgTarget.clientWidth
    this.tx += dx * unitPerPx
    this.ty += dy * unitPerPx
    this.lastX = event.clientX
    this.lastY = event.clientY
    this.applyTransform()
  }

  panEnd (): void {
    this.panning = false
    this.svgTarget.style.cursor = 'grab'
  }

  select (event: MouseEvent): void {
    if (this.moved) return // drag, not a click
    const roomEl = (event.target as Element).closest('[data-room-id]')
    if (!roomEl) return
    const label = document.getElementById('spike-map-selected')
    if (label) label.textContent = ` selected: ${roomEl.getAttribute('data-room-name')} (#${roomEl.getAttribute('data-room-id')})`
  }

  private applyTransform (): void {
    this.worldTarget.setAttribute('transform', `translate(${this.tx} ${this.ty}) scale(${this.scale})`)
  }
}
