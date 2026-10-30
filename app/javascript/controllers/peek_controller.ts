import { Controller } from '@hotwired/stimulus'

// Hover peek for the console pages' thumbnails (2026-10-29): the catalog
// ledger's 40px covers, the release / track screen's cover, the XERAEN
// bio's track row thumb and the VIDZ archive's 64×36 YouTube thumbs.
// Resting the pointer on a thumb opens one shared fixed panel beside it
// with the large rendition (data-peek-src-value — Release#cover_large,
// YouTube's maxresdefault; data-peek-fallback-value is tried when the
// first 404s, as maxresdefault does for older uploads). Hover-only: on a
// touch screen (no hover media) the thumb stays a plain link. The panel
// parks right of the thumb when it fits, else left, clamped to the
// viewport, and hides on mouseleave, scroll, the thumb's disconnect and
// before Turbo caches the page. pointer-events are off on the panel so
// it never traps the mouse.

const GAP_PX = 12
const MARGIN_PX = 8

// The thumb being peeked, as callbacks (not the controller itself, so no
// `this` alias): the shared image's load/error and the page-level hides
// route to it.
type Active = { element: HTMLElement, place: () => void, fallback: () => void, hide: () => void }

let panel: HTMLDivElement | null = null
let image: HTMLImageElement | null = null
let active: Active | null = null
let listening = false

function hideAll (): void {
  active?.hide()
}

function ensurePanel (): { panel: HTMLDivElement, image: HTMLImageElement } {
  if (panel === null || image === null || !document.body.contains(panel)) {
    panel = document.createElement('div')
    panel.className = 'peek'
    panel.hidden = true
    panel.setAttribute('aria-hidden', 'true')
    image = document.createElement('img')
    image.className = 'peek-img'
    image.alt = ''
    image.decoding = 'async'
    image.addEventListener('load', () => { active?.place() })
    image.addEventListener('error', () => { active?.fallback() })
    panel.append(image)
    document.body.append(panel)
  }
  if (!listening) {
    listening = true
    document.addEventListener('turbo:before-cache', hideAll)
    window.addEventListener('scroll', hideAll, { passive: true, capture: true })
  }
  return { panel, image }
}

export default class PeekController extends Controller<HTMLElement> {
  static values = { src: String, fallback: String }

  declare srcValue: string
  declare fallbackValue: string

  private triedFallback = false

  disconnect (): void {
    this.hide()
  }

  show (): void {
    if (!this.srcValue) return
    if (!window.matchMedia('(hover: hover)').matches) return
    const { panel: box, image: img } = ensurePanel()
    active = { element: this.element, place: () => { this.place() }, fallback: () => { this.fallback() }, hide: () => { this.hide() } }
    this.triedFallback = false
    if (img.getAttribute('src') !== this.srcValue) img.src = this.srcValue
    box.hidden = false
    this.place()
  }

  hide (): void {
    if (active?.element !== this.element) return
    active = null
    if (panel !== null) panel.hidden = true
  }

  // The image's error: one more try with the fallback, then give up.
  fallback (): void {
    if (active?.element !== this.element || image === null) return
    if (this.triedFallback || !this.fallbackValue) { this.hide(); return }
    this.triedFallback = true
    image.src = this.fallbackValue
  }

  place (): void {
    if (active?.element !== this.element || panel === null) return
    const rect = this.element.getBoundingClientRect()
    const width = panel.offsetWidth
    const height = panel.offsetHeight
    let left = rect.right + GAP_PX
    if (left + width > window.innerWidth - MARGIN_PX) left = rect.left - GAP_PX - width
    if (left < MARGIN_PX) left = MARGIN_PX
    let top = rect.top
    if (top + height > window.innerHeight - MARGIN_PX) top = window.innerHeight - MARGIN_PX - height
    if (top < MARGIN_PX) top = MARGIN_PX
    panel.style.left = `${Math.round(left)}px`
    panel.style.top = `${Math.round(top)}px`
  }
}
