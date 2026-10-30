import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PeekController from './peek_controller'

// Fixture: two console thumbs on the peek controller — a catalog ledger
// cover with its large rendition, and a VIDZ archive thumb with the
// YouTube fallback. jsdom has no layout, no image loading and no
// matchMedia: rects, the panel's offset size, the viewport and the hover
// media query are stubbed; load/error are dispatched by hand.

function fixture (): string {
  return `
    <a id="cover" href="/xeraen/releases/xordium" class="cc-cover" data-controller="peek"
       data-peek-src-value="/rails/active_storage/large.jpg"
       data-action="mouseenter->peek#show mouseleave->peek#hide"><img src="/thumb.jpg" alt=""></a>
    <a id="vod" href="/thecyberpulse/vidz/1" class="cc-cover cc-cover--wide" data-controller="peek"
       data-peek-src-value="https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
       data-peek-fallback-value="https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg"
       data-action="mouseenter->peek#show mouseleave->peek#hide"><img src="/mq.jpg" alt=""></a>`
}

type Box = { left: number, top: number, width: number, height: number }

function rect (el: Element, { left, top, width, height }: Box): void {
  el.getBoundingClientRect = () => ({ left, top, width, height, right: left + width, bottom: top + height, x: left, y: top, toJSON: () => ({}) }) as DOMRect
}

function size (el: Element, props: Record<string, number>): void {
  for (const [key, value] of Object.entries(props)) Object.defineProperty(el, key, { value, configurable: true })
}

describe('PeekController', () => {
  let application: Application
  let hover = true

  const cover = (): HTMLElement => document.getElementById('cover') as HTMLElement
  const vod = (): HTMLElement => document.getElementById('vod') as HTMLElement
  const panel = (): HTMLElement | null => document.querySelector('.peek')
  const img = (): HTMLImageElement => (panel() as HTMLElement).querySelector('img') as HTMLImageElement

  function enter (el: Element): void { el.dispatchEvent(new MouseEvent('mouseenter')) }
  function leave (el: Element): void { el.dispatchEvent(new MouseEvent('mouseleave')) }

  // The panel exists only once a thumb is hovered; the stub sizes it
  // the way a 480px rendition would lay out, then the load replays place().
  function loaded (): HTMLElement {
    const box = panel() as HTMLElement
    size(box, { offsetWidth: 488, offsetHeight: 488 })
    img().dispatchEvent(new Event('load'))
    return box
  }

  beforeEach(async () => {
    hover = true
    vi.stubGlobal('matchMedia', (query: string) => ({ matches: query === '(hover: hover)' && hover, media: query }))
    Object.defineProperty(window, 'innerWidth', { value: 1400, configurable: true })
    Object.defineProperty(window, 'innerHeight', { value: 900, configurable: true })
    document.body.innerHTML = fixture()
    rect(cover(), { left: 60, top: 200, width: 40, height: 40 })
    rect(vod(), { left: 1200, top: 850, width: 64, height: 36 })
    application = Application.start()
    application.register('peek', PeekController)
    await Promise.resolve()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.unstubAllGlobals()
  })

  it('opens the shared panel right of the hovered cover with its large rendition, and hides on leave', () => {
    enter(cover())
    const box = loaded()

    expect(box.hidden).toBe(false)
    expect(img().getAttribute('src')).toBe('/rails/active_storage/large.jpg')
    expect(box.style.left).toBe('112px') // the thumb's right edge + 12
    expect(box.style.top).toBe('200px')

    leave(cover())
    expect(box.hidden).toBe(true)
  })

  it('flips left and clamps to the viewport when the panel would overflow', () => {
    enter(vod())
    const box = loaded()

    expect(box.style.left).toBe('700px') // 1200 - 12 - 488
    expect(box.style.top).toBe('404px') // 900 - 8 - 488
  })

  it('tries the fallback rendition once on error, then gives up', () => {
    enter(vod())

    expect(img().getAttribute('src')).toBe('https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg')
    img().dispatchEvent(new Event('error'))
    expect(img().getAttribute('src')).toBe('https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg')
    expect((panel() as HTMLElement).hidden).toBe(false)
    img().dispatchEvent(new Event('error'))
    expect((panel() as HTMLElement).hidden).toBe(true)
  })

  it('reuses one panel across thumbs; a stale leave from another thumb does not hide it', () => {
    enter(cover())
    enter(vod())

    expect(document.querySelectorAll('.peek').length).toBe(1)
    expect(img().getAttribute('src')).toContain('maxresdefault')
    leave(cover())
    expect((panel() as HTMLElement).hidden).toBe(false)
    leave(vod())
    expect((panel() as HTMLElement).hidden).toBe(true)
  })

  it('does nothing without hover media (touch screens)', () => {
    hover = false
    enter(cover())

    expect(panel()).toBeNull()
  })

  it('hides before Turbo caches the page and on scroll', () => {
    enter(cover())
    document.dispatchEvent(new Event('turbo:before-cache'))
    expect((panel() as HTMLElement).hidden).toBe(true)

    enter(cover())
    window.dispatchEvent(new Event('scroll'))
    expect((panel() as HTMLElement).hidden).toBe(true)
  })
})
