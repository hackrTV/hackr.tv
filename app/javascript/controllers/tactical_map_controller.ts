import { Controller } from '@hotwired/stimulus'

// Zone map interaction (spike B controller grown for 6c): wheel zoom,
// drag pan, click-to-move. Lives on the STABLE map region wrapper — the
// SVG fragment inside is replaced per movement, and svgTargetConnected
// re-applies the preserved transform (the SPA kept pan/zoom in React
// state across re-renders). Clicking a room with data-direction submits
// `go <direction>` through the main command form, reusing echo/streams.
export default class extends Controller<HTMLElement> {
  static targets = ['svg', 'world']

  declare readonly svgTarget: SVGSVGElement
  declare readonly hasSvgTarget: boolean
  declare readonly worldTargets: SVGGElement[]

  private scale = 1
  private tx = 0
  private ty = 0
  private panning = false
  private moved = false
  private lastX = 0
  private lastY = 0

  worldTargetConnected (): void {
    this.applyTransform()
  }

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
  }

  panMove (event: PointerEvent): void {
    if (!this.panning || !this.hasSvgTarget) return
    const dx = event.clientX - this.lastX
    const dy = event.clientY - this.lastY
    if (Math.abs(dx) + Math.abs(dy) > 2) this.moved = true
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
  }

  select (event: MouseEvent): void {
    if (this.moved) return // drag, not a click
    const roomEl = (event.target as Element).closest('[data-direction]')
    const direction = roomEl?.getAttribute('data-direction')
    if (!direction) return
    const input = document.querySelector<HTMLInputElement>('.tactical-command-form .grid-command-input')
    const form = input?.closest('form')
    if (!input || !form) return
    input.value = `go ${direction}`
    form.requestSubmit()
  }

  private applyTransform (): void {
    this.worldTargets.forEach(world => {
      world.setAttribute('transform', `translate(${this.tx} ${this.ty}) scale(${this.scale})`)
    })
  }
}
