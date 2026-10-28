import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import WireViewController from './wire_view_controller'

vi.mock('@hotwired/turbo-rails', () => ({ Turbo: { visit: vi.fn() } }))

// Fixtures mirror wire/index.html.erb (ledger: the bar's [≡] MUTT) and
// wire/_mutt.html.erb (the index box with #wire-feed, the status line,
// [≡] LEDGER). Rows are the ledger's; the cursor class is set by hand
// (wire-keys owns it) and announced with wire:cursor.

function entry (id: number, inner = '', owner = 8): string {
  return `<div id="pulse_${id}_entry" class="wire-entry"><div id="pulse_${id}" class="wire-row" data-pulse-id="${id}" data-wire-row-owner-id-value="${owner}">p${id}</div>${inner}</div>`
}

const ledger = (): string => `
  <div class="wire-page" data-view="ledger" data-controller="wire-view" data-action="wire-keys:view->wire-view#toggle">
    <button class="wire-bar-view" data-action="click->wire-view#toggle">[≡] MUTT</button>
    <div class="wire-main"><div id="wire-feed">${entry(1)}</div></div>
  </div>`

const mutt = (rows: string): string => `
  <div class="wire-page wire-mutt" data-view="mutt" data-controller="wire-view" data-wire-view-total-value="1204"
       data-action="wire:cursor->wire-view#cursor wire-keys:view->wire-view#toggle">
    <button class="wire-bar-view" data-action="click->wire-view#toggle">[≡] LEDGER</button>
    <div class="wire-index"><div id="wire-feed">${rows}</div></div>
    <div class="wire-mutt-status" data-wire-view-target="status"></div>
  </div>`

describe('WireViewController', () => {
  let application: Application | null = null

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('wire-view', WireViewController)
    await Promise.resolve()
  }

  const status = (): string => document.querySelector('.wire-mutt-status')!.textContent!.replace(/-{4,}/g, '~')
  const cookie = (): string => document.cookie
  const width = (value: number): void => { Object.defineProperty(window, 'innerWidth', { value, configurable: true, writable: true }) }

  function cursorOn (id: number): void {
    document.querySelectorAll('.wire-row--cursor').forEach(el => el.classList.remove('wire-row--cursor'))
    const row = document.getElementById(`pulse_${id}`)!
    row.classList.add('wire-row--cursor')
    row.dispatchEvent(new CustomEvent('wire:cursor', { bubbles: true }))
  }

  beforeEach(() => {
    document.cookie = 'wire_view=; path=/; max-age=0'
    vi.mocked(Turbo.visit).mockClear()
    width(1400)
  })

  afterEach(() => {
    application?.stop()
    application = null
    document.body.innerHTML = ''
  })

  it('switches the ledger to MUTT with the cookie and an in-place visit, only on wide viewports', async () => {
    await start(ledger())

    width(1000)
    document.querySelector<HTMLElement>('.wire-bar-view')!.click()
    expect(cookie()).not.toContain('wire_view=mutt')
    expect(Turbo.visit).not.toHaveBeenCalled()

    width(1400)
    document.querySelector<HTMLElement>('.wire-page')!.dispatchEvent(new CustomEvent('wire-keys:view'))
    expect(cookie()).toContain('wire_view=mutt')
    expect(Turbo.visit).toHaveBeenCalledWith(window.location.href, { action: 'replace' })
  })

  it('switches MUTT back to the ledger at any width', async () => {
    width(1000)
    await start(mutt(entry(1)))

    document.querySelector<HTMLElement>('.wire-bar-view')!.click()
    expect(cookie()).toContain('wire_view=ledger')
    expect(Turbo.visit).toHaveBeenCalledTimes(1)
  })

  it('writes the status line and follows the cursor', async () => {
    await start(mutt(entry(1) + entry(2) + entry(3)))
    expect(status()).toBe('-*-WIRE: ALL TRAFFIC [Pulses:1204 New:0]~(-/3)---(-)---')

    cursorOn(2)
    expect(status()).toBe('-*-WIRE: ALL TRAFFIC [Pulses:1204 New:0]~(2/3)---(67%)---')
  })

  it('flags live arrivals N until the cursor reads them, counting them in the status line', async () => {
    await start(mutt(entry(2)))
    document.getElementById('wire-feed')!.insertAdjacentHTML('afterbegin', entry(9))
    document.getElementById('wire-feed')!.insertAdjacentHTML('afterbegin', '<div class="wire-day">// TODAY //</div>')
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(document.getElementById('pulse_9')!.classList.contains('wire-row--new')).toBe(true)
    expect(document.getElementById('pulse_2')!.classList.contains('wire-row--new')).toBe(false)
    expect(status()).toContain('[Pulses:1205 New:1]')

    cursorOn(9)
    expect(document.getElementById('pulse_9')!.classList.contains('wire-row--new')).toBe(false)
    expect(status()).toContain('New:0]~(1/2)')
  })

  it('never flags the viewer\'s own send, counts its re-add (the broadcast) once, and subtracts deletes', async () => {
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    meta.content = '7'
    document.head.appendChild(meta)
    await start(mutt(entry(2)))
    const feed = document.getElementById('wire-feed')!

    feed.insertAdjacentHTML('afterbegin', entry(9, '', 7)) // the form's stream
    await new Promise(resolve => setTimeout(resolve, 0))
    document.getElementById('pulse_9_entry')!.remove() // Turbo's prepend of the broadcast copy: same id, out and back in
    feed.insertAdjacentHTML('afterbegin', entry(9, '', 7))
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(document.getElementById('pulse_9')!.classList.contains('wire-row--new')).toBe(false)
    expect(status()).toContain('[Pulses:1205 New:0]')

    document.getElementById('pulse_2_entry')!.remove()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(status()).toContain('[Pulses:1204 New:0]~(-/1)')
    meta.remove()
  })

  it('empties inline thread frames on connect (the pager is the one thread surface)', async () => {
    await start(mutt(entry(1, '<turbo-frame id="pulse_1_thread" class="wire-thread" src="/wire/pulse/1"><div id="pulse_1_thread_list"></div></turbo-frame>')))

    const frame = document.getElementById('pulse_1_thread')!
    expect(frame.innerHTML).toBe('')
    expect(frame.hasAttribute('src')).toBe(false)
  })
})
