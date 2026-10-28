import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WirePaneController from './wire_pane_controller'

// Fixture mirrors wire/index.html.erb: the page root carrying the pane's
// actions, the bar's [>] CONTEXT toggle, root rows in #wire-feed
// (data-thread-frame), the turbo-frame#wire-pane with its placeholder.
// matchMedia is stubbed (≥1100px available unless `wide` is flipped);
// innerWidth drives the first-visit default.

function row (id: number, root = true): string {
  return `
    <div id="pulse_${id}_entry" class="wire-entry">
      <div id="pulse_${id}" class="wire-row" data-pulse-id="${id}"${root ? ` data-thread-frame="pulse_${id}_thread"` : ''}>
        <a class="wire-author" href="/wire/ghost">@ghost</a>
        <a class="splice-button" href="/wire/pulse/${id}">↩</a>
      </div>
      ${root ? `<turbo-frame id="pulse_${id}_thread" class="wire-thread"></turbo-frame>` : ''}
    </div>`
}

function page (rows: string, pane = '', src: string | null = null, view = ''): string {
  return `
    <div class="wire-page"${view ? ` data-view="${view}"` : ''} data-controller="wire-pane" data-action="wire:cursor->wire-pane#follow wire-row:pane->wire-pane#claim wire-keys:pane->wire-pane#toggle">
      <div class="wire-bar"><button class="wire-bar-pane" aria-pressed="false" data-wire-pane-target="toggle" data-action="click->wire-pane#toggle">[>] CONTEXT</button></div>
      <div class="wire-main"><div id="wire-feed">${rows}</div></div>
      <aside class="wire-pane">
        <turbo-frame id="wire-pane" target="_top"${src ? ` src="${src}"` : ''} data-wire-pane-target="frame">${pane}</turbo-frame>
        <div class="wire-pane-empty">// SELECT A PULSE //</div>
      </aside>
    </div>`
}

// What pane.html.erb puts in the frame, minus the rows.
const thread = (id: number): string => `
  <div class="wire-pane-head"><button type="button" class="wire-pane-close" data-action="click->wire-pane#close">[x]</button></div>
  <div class="wire-pane-body">
    <div class="wire-pane-root">
      <time datetime="2026-10-26T14:03:00Z" data-wire-pane-target="stamp">2026-10-26 14:03</time>
      <a class="wire-author" href="/wire/ghost" data-action="click->wire-pane#author">@ghost</a>
    </div>
    <div id="pulse_${id}_thread_list"></div>
    <form class="wire-prompt"><textarea class="wire-prompt-input"></textarea></form>
  </div>`

describe('WirePaneController', () => {
  let application: Application | null = null
  let wide = true
  let mediaListener: (() => void) | null = null

  async function start (html: string): Promise<void> {
    application?.stop()
    document.body.innerHTML = html
    application = Application.start()
    application.register('wire-pane', WirePaneController)
    await Promise.resolve()
  }

  const pageEl = (): HTMLElement => document.querySelector<HTMLElement>('.wire-page')!
  const frame = (): HTMLElement => document.getElementById('wire-pane')!
  const toggle = (): HTMLElement => document.querySelector<HTMLElement>('.wire-bar-pane')!
  const sel = (): string | undefined => document.querySelector('.wire-row--sel')?.id
  const width = (value: number): void => { Object.defineProperty(window, 'innerWidth', { value, configurable: true, writable: true }) }

  function offer (rowId: string, detail: Record<string, unknown>): CustomEvent {
    const event = new CustomEvent('wire-row:pane', { bubbles: true, cancelable: true, detail })
    document.getElementById(rowId)!.dispatchEvent(event)
    return event
  }

  function cursor (rowId: string): void {
    document.getElementById(rowId)!.dispatchEvent(new CustomEvent('wire:cursor', { bubbles: true }))
  }

  const cookie = (): string | null => document.cookie.match(/(?:^|; )wire_pane=([^;]*)/)?.[1] ?? null

  beforeEach(() => {
    wide = true
    mediaListener = null
    document.cookie = 'wire_pane=; path=/; max-age=0'
    vi.stubGlobal('matchMedia', vi.fn(() => ({
      get matches (): boolean { return wide },
      addEventListener: (_: string, fn: () => void): void => { mediaListener = fn },
      removeEventListener: vi.fn()
    })))
    width(1400)
  })

  afterEach(() => {
    application?.stop()
    application = null
    document.body.innerHTML = ''
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  it('opens by default on a wide first visit (writing the cookie), stays closed under 1280px, and honors the remembered choice', async () => {
    await start(page(row(1)))
    expect(pageEl().dataset.pane).toBe('open')
    expect(toggle().getAttribute('aria-pressed')).toBe('true')
    expect(cookie()).toBe('open') // the server renders it open from here on

    document.cookie = 'wire_pane=; path=/; max-age=0'
    width(1200)
    await start(page(row(1)))
    expect(pageEl().dataset.pane).toBeUndefined()
    expect(toggle().getAttribute('aria-pressed')).toBe('false')
    expect(cookie()).toBe('closed')

    document.cookie = 'wire_pane=open; path=/'
    await start(page(row(1)))
    expect(pageEl().dataset.pane).toBe('open')

    width(1400)
    document.cookie = 'wire_pane=closed; path=/'
    await start(page(row(1)))
    expect(pageEl().dataset.pane).toBeUndefined()
  })

  it('is the pager in MUTT mode: always on without data-pane (the shell lays it out), the toggles inert', async () => {
    document.cookie = 'wire_pane=closed; path=/'
    await start(page(row(1), '', null, 'mutt'))
    expect(pageEl().dataset.pane).toBeUndefined()

    toggle().click()
    pageEl().dispatchEvent(new CustomEvent('wire-keys:pane'))
    expect(pageEl().dataset.pane).toBeUndefined()
    expect(cookie()).toBe('closed') // untouched
    expect(offer('pulse_1', { url: '/wire/pulse/1', select: '1' }).defaultPrevented).toBe(true)
    expect(frame().getAttribute('src')).toBe('/wire/pulse/1')
  })

  it('toggles from the bar, the c key (wire-keys:pane) and the pane\'s [x], remembering the choice; opening onto a cursor row shows it', async () => {
    await start(page(row(1) + row(2)))

    toggle().click()
    expect(pageEl().dataset.pane).toBeUndefined()
    expect(toggle().getAttribute('aria-pressed')).toBe('false')
    expect(cookie()).toBe('closed')

    document.getElementById('pulse_2')!.classList.add('wire-row--cursor')
    pageEl().dispatchEvent(new CustomEvent('wire-keys:pane'))
    expect(pageEl().dataset.pane).toBe('open')
    expect(cookie()).toBe('open')
    expect(frame().getAttribute('src')).toBe('/wire/pulse/2')
    expect(sel()).toBe('pulse_2')

    frame().innerHTML = thread(2)
    await Promise.resolve()
    document.querySelector<HTMLElement>('.wire-pane-close')!.click()
    expect(pageEl().dataset.pane).toBeUndefined()
    expect(frame().innerHTML).toBe('')
    expect(frame().hasAttribute('src')).toBe(false)
    expect(sel()).toBeUndefined()
  })

  it('claims a row\'s offer while active and leaves it alone when closed', async () => {
    await start(page(row(1)))

    const claimed = offer('pulse_1', { url: '/wire/pulse/1', select: '1' })
    expect(claimed.defaultPrevented).toBe(true)
    expect(frame().getAttribute('src')).toBe('/wire/pulse/1')
    expect(sel()).toBe('pulse_1')

    toggle().click()
    const declined = offer('pulse_1', { url: '/wire/pulse/1', select: '1' })
    expect(declined.defaultPrevented).toBe(false)
    expect(frame().hasAttribute('src')).toBe(false)
    expect(sel()).toBeUndefined()
  })

  it('empties an inline copy of the thread it loads, so the streams have one target', async () => {
    await start(page(row(1)))
    const inline = document.getElementById('pulse_1_thread') as HTMLElement
    inline.setAttribute('src', '/wire/pulse/1')
    inline.innerHTML = '<div id="pulse_1_thread_list"></div>'
    inline.hidden = true
    document.querySelector('#pulse_1 .splice-button')!.setAttribute('aria-expanded', 'true')

    offer('pulse_1', { url: '/wire/pulse/1', select: '1' })

    expect(frame().getAttribute('src')).toBe('/wire/pulse/1')
    expect(inline.innerHTML).toBe('')
    expect(inline.hasAttribute('src')).toBe(false)
    expect(inline.hidden).toBe(false)
    expect(document.querySelector('#pulse_1 .splice-button')!.getAttribute('aria-expanded')).toBe('false')
    expect(document.querySelectorAll('#pulse_1_thread_list')).toHaveLength(0)
  })

  it('follows the cursor onto root rows after a beat, coalescing quick moves, and ignores reply rows', async () => {
    vi.useFakeTimers()
    await start(page(row(1) + row(2) + row(3, false)))

    cursor('pulse_1')
    vi.advanceTimersByTime(100)
    cursor('pulse_2')
    vi.advanceTimersByTime(100)
    expect(frame().hasAttribute('src')).toBe(false)
    vi.advanceTimersByTime(150)
    expect(frame().getAttribute('src')).toBe('/wire/pulse/2')
    expect(sel()).toBe('pulse_2')

    cursor('pulse_3')
    vi.advanceTimersByTime(300)
    expect(frame().getAttribute('src')).toBe('/wire/pulse/2')
    expect(sel()).toBe('pulse_2')
  })

  it('does not reload what is already shown (a reply offer just focuses the prompt); a record offer replaces it and clears the selection', async () => {
    await start(page(row(1), thread(1), '/wire/pulse/1'))
    expect(sel()).toBe('pulse_1') // restored from the frame's src
    const set = vi.spyOn(frame(), 'setAttribute')

    const claimed = offer('pulse_1', { url: '/wire/pulse/1', select: '1', focus: true })
    expect(claimed.defaultPrevented).toBe(true)
    expect(set).not.toHaveBeenCalledWith('src', expect.anything())
    expect(document.activeElement).toBe(frame().querySelector('.wire-prompt-input'))

    offer('pulse_1', { url: '/wire/ghost' })
    expect(frame().getAttribute('src')).toBe('/wire/ghost')
    expect(sel()).toBeUndefined()
  })

  it('focuses the prompt once a reply load lands and localizes the root stamp', async () => {
    await start(page(row(1)))
    offer('pulse_1', { url: '/wire/pulse/1', select: '1', focus: true })

    frame().innerHTML = thread(1)
    await Promise.resolve()
    frame().dispatchEvent(new Event('turbo:frame-load', { bubbles: true }))

    expect(document.activeElement).toBe(frame().querySelector('.wire-prompt-input'))
    expect(frame().querySelector('time')!.textContent).toMatch(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/)
  })

  it('loads the record from a plain click on an author link inside the pane, letting modified clicks through', async () => {
    await start(page(row(1), thread(1), '/wire/pulse/1'))
    const link = frame().querySelector<HTMLAnchorElement>('.wire-author')!

    const modified = new MouseEvent('click', { bubbles: true, cancelable: true, ctrlKey: true })
    link.dispatchEvent(modified)
    expect(modified.defaultPrevented).toBe(false)
    expect(frame().getAttribute('src')).toBe('/wire/pulse/1')

    const plain = new MouseEvent('click', { bubbles: true, cancelable: true })
    link.dispatchEvent(plain)
    expect(plain.defaultPrevented).toBe(true)
    expect(frame().getAttribute('src')).toBe('/wire/ghost')
    expect(sel()).toBeUndefined()
  })

  it('reloads when the selected row is replaced (a drop) and empties when it leaves the feed (a delete)', async () => {
    await start(page(row(1) + row(2), thread(1), '/wire/pulse/1'))
    const set = vi.spyOn(frame(), 'setAttribute')

    const stale = document.getElementById('pulse_1')!
    const fresh = stale.cloneNode(true) as HTMLElement
    fresh.classList.remove('wire-row--sel')
    fresh.classList.add('wire-row--dropped')
    stale.replaceWith(fresh)
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(set).toHaveBeenCalledWith('src', '/wire/pulse/1')
    expect(sel()).toBe('pulse_1')

    document.getElementById('pulse_1_entry')!.remove()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(frame().innerHTML).toBe('')
    expect(frame().hasAttribute('src')).toBe(false)
    expect(sel()).toBeUndefined()
  })

  it('drops out under 1100px without touching the remembered choice, and clears a snapshot\'s selection mark on connect', async () => {
    await start(page(row(1).replace('class="wire-row"', 'class="wire-row wire-row--sel"')))
    expect(sel()).toBeUndefined()
    offer('pulse_1', { url: '/wire/pulse/1', select: '1' })

    wide = false
    mediaListener?.()
    expect(pageEl().dataset.pane).toBeUndefined()
    expect(frame().hasAttribute('src')).toBe(false)
    expect(sel()).toBeUndefined()
    expect(cookie()).toBe('open') // availability is not a choice

    wide = true
    mediaListener?.()
    expect(pageEl().dataset.pane).toBe('open')
  })
})
