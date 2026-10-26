import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import UplinkShellController from './uplink_shell_controller'

vi.mock('@hotwired/turbo-rails', () => ({ Turbo: { visit: vi.fn() } }))

// Fixture mirrors uplink/_shell's chrome: sidebar (rows with unread
// badges + the hidden bump block) + members panes (the roster and the
// search face with two hits), the main pane with a log of packets,
// backdrop, jump pill, stage, composer. matchMedia is stubbed per
// example to flip the mobile breakpoint.

let mobile = false

function fixture (withStage = true): string {
  return `
    <div class="uplink-shell" data-controller="uplink-shell" data-members="open" data-drawer="" data-pane="members" data-uplink-shell-channel-value="ambient" data-uplink-shell-ack-url-value="/uplink/reads" data-uplink-shell-present-url-value="/uplink?channel=ambient"
         data-action="packet-log:state->uplink-shell#logState turbo:submit-end->uplink-shell#sent keydown@document->uplink-shell#hotkey toast:connected@document->uplink-shell#toast">
      <aside data-uplink-shell-target="sidebar">
        <a href="/uplink?channel=ambient" id="first-channel" class="uplink-channel uplink-channel--active" data-channel="ambient">#ambient<span class="uplink-channel-badge" hidden data-count="0"></span></a>
        <a href="/uplink?channel=trace" class="uplink-channel" data-channel="trace">#trace<span class="uplink-channel-badge" hidden data-count="0"></span></a>
        <a href="/uplink?channel=ops" class="uplink-channel uplink-channel--unread" data-channel="ops">#ops<span class="uplink-channel-badge" data-count="99">99</span></a>
        <div class="uplink-bumps" hidden data-uplink-shell-target="bumps">
          <span id="uplink-bump-trace" data-channel="trace"></span>
          <span id="uplink-bump-ops" data-channel="ops"></span>
          <span id="uplink-bump-nope" data-channel="../nope"></span>
        </div>
      </aside>
      <div data-uplink-shell-target="main">
        <button type="button" data-uplink-shell-target="membersToggle" data-action="click->uplink-shell#toggleMembers" aria-pressed="true">[o]</button>
        <button type="button" id="sidebar-toggle" data-action="click->uplink-shell#toggleSidebar">[#]</button>
        <button type="button" data-uplink-shell-target="searchToggle" data-action="click->uplink-shell#toggleSearch" aria-pressed="false">[/]</button>
        ${withStage ? `
        <section class="uplink-stage" data-uplink-shell-target="stage">
          <button type="button" data-uplink-shell-target="stageToggle" data-action="click->uplink-shell#toggleStage">[-] HIDE VIDEO</button>
          <iframe data-src="https://www.youtube.com/embed/abc" data-uplink-shell-target="stageFrame"></iframe>
        </section>` : ''}
        <div id="uplink-log"><div id="chat_message_41" class="packet" data-packet-owner-id-value="8"></div></div>
        <button type="button" hidden data-uplink-shell-target="jump" data-action="click->uplink-shell#jump">[v] <span data-uplink-shell-target="jumpCount"></span></button>
        <form class="packet-input-form"><textarea class="packet-input-text"></textarea></form>
        <input id="other-field">
      </div>
      <aside data-uplink-shell-target="members"><button id="first-member">x</button>
        <section class="uplink-search" data-uplink-shell-target="search">
          <button type="button" id="search-close" data-action="click->uplink-shell#closeSearch">[x]</button>
          <input type="text" class="uplink-search-field" data-uplink-shell-target="searchField" data-action="keydown->uplink-shell#searchKey">
          <turbo-frame id="uplink-search">
            <a id="hit-41" href="/uplink?around=41&channel=ambient" data-action="click->uplink-shell#locate" data-uplink-shell-id-param="41">hit</a>
            <a id="hit-404" href="/uplink?around=404&channel=ambient" data-action="click->uplink-shell#locate" data-uplink-shell-id-param="404">miss</a>
          </turbo-frame>
        </section>
      </aside>
      <div class="uplink-backdrop" data-action="click->uplink-shell#closeDrawers"></div>
    </div>`
}

describe('UplinkShellController', () => {
  let application: Application

  const shell = (): HTMLElement => document.querySelector('.uplink-shell')!
  const main = (): HTMLElement => document.querySelector('[data-uplink-shell-target="main"]')!
  const backdrop = (): HTMLElement => document.querySelector('.uplink-backdrop')!
  const jump = (): HTMLButtonElement => document.querySelector('[data-uplink-shell-target="jump"]')!
  const stage = (): HTMLElement => document.querySelector('[data-uplink-shell-target="stage"]')!
  const frame = (): HTMLIFrameElement => document.querySelector('[data-uplink-shell-target="stageFrame"]')!
  const composer = (): HTMLTextAreaElement => document.querySelector('.packet-input-text')!

  function press (key: string, target: EventTarget = document.body, init: KeyboardEventInit = {}): KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...init })
    target.dispatchEvent(event)
    return event
  }

  async function start (html = fixture()): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('uplink-shell', UplinkShellController)
    await Promise.resolve()
  }

  beforeEach(() => {
    mobile = false
    localStorage.clear()
    vi.mocked(Turbo.visit).mockClear()
    vi.stubGlobal('matchMedia', vi.fn((query: string) => ({
      matches: query.includes('max-width') ? mobile : query.includes('pointer: fine'),
      media: query,
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    })))
    Object.defineProperty(window, 'innerWidth', { value: 1400, configurable: true, writable: true })
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.unstubAllGlobals()
    vi.useRealTimers()
    document.head.querySelector('meta[name="current-hackr-id"]')?.remove()
  })

  const badge = (slug: string): HTMLElement => document.querySelector(`.uplink-channel[data-channel="${slug}"] .uplink-channel-badge`)!
  const row = (slug: string): HTMLElement => document.querySelector(`.uplink-channel[data-channel="${slug}"]`)!

  // Turbo's append into a bump slot, as ChatMessage#broadcast_bump sends it.
  async function bump (slug: string): Promise<void> {
    document.getElementById(`uplink-bump-${slug}`)!.insertAdjacentHTML('beforeend', '<i></i>')
    await Promise.resolve()
  }

  function viewerMeta (id: string): void {
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    meta.content = id
    document.head.appendChild(meta)
  }

  function state (detail: { atBottom: boolean, unread: number, mentions?: number, atPresent?: boolean }): void {
    document.getElementById('uplink-log')!.dispatchEvent(new CustomEvent('packet-log:state', { bubbles: true, detail }))
  }

  function landed (id: number, owner: string): void {
    document.getElementById('uplink-log')!.insertAdjacentHTML('beforeend', `<div id="chat_message_${id}" class="packet" data-packet-owner-id-value="${owner}"></div>`)
  }

  it('opens the members pane by default on wide viewports and persists the toggle', async () => {
    await start()
    expect(shell().dataset.members).toBe('open')
    expect(composer()).toBe(document.activeElement) // fine pointer: composer autofocus

    document.querySelector<HTMLButtonElement>('[data-uplink-shell-target="membersToggle"]')!.click()
    expect(shell().dataset.members).toBe('closed')
    expect(localStorage.getItem('uplink:members')).toBe('closed')

    application.stop()
    await start()
    expect(shell().dataset.members).toBe('closed') // remembered
  })

  it('defaults the members pane closed on narrow desktops', async () => {
    Object.defineProperty(window, 'innerWidth', { value: 1000, configurable: true, writable: true })
    await start()
    expect(shell().dataset.members).toBe('closed')
  })

  it('runs drawers under 768px: data-drawer (CSS backdrop), inert main, Escape + backdrop close', async () => {
    mobile = true
    await start()

    document.getElementById('sidebar-toggle')!.click()
    expect(shell().dataset.drawer).toBe('sidebar')
    expect(main().hasAttribute('inert')).toBe(true)
    expect(document.activeElement).toBe(document.getElementById('first-channel'))

    expect(press('Escape').defaultPrevented).toBe(true)
    expect(shell().dataset.drawer).toBe('')
    expect(main().hasAttribute('inert')).toBe(false)

    document.querySelector<HTMLButtonElement>('[data-uplink-shell-target="membersToggle"]')!.click()
    expect(shell().dataset.drawer).toBe('members')
    expect(shell().dataset.members).toBe('open') // desktop preference untouched
    backdrop().click()
    expect(shell().dataset.drawer).toBe('')
  })

  it('collapses the stage by clearing the iframe src and remembers it', async () => {
    await start()
    expect(frame().getAttribute('src')).toBe('https://www.youtube.com/embed/abc')

    stage().querySelector<HTMLButtonElement>('[data-uplink-shell-target="stageToggle"]')!.click()
    expect(stage().classList.contains('uplink-stage--collapsed')).toBe(true)
    expect(frame().getAttribute('src')).toBeNull()
    expect(stage().querySelector('button')!.textContent).toBe('[+] SHOW VIDEO')
    expect(localStorage.getItem('uplink:stage')).toBe('closed')

    application.stop()
    await start()
    expect(frame().getAttribute('src')).toBeNull() // stays collapsed, no audio
  })

  it('shows the jump pill from packet-log:state and jumps on click or own send, not on moderation forms', async () => {
    await start()
    const log = document.getElementById('uplink-log')!
    Object.defineProperty(log, 'scrollHeight', { value: 500, configurable: true })

    log.dispatchEvent(new CustomEvent('packet-log:state', { bubbles: true, detail: { atBottom: false, unread: 3 } }))
    expect(jump().hidden).toBe(false)
    expect(jump().textContent).toContain('3 NEW PACKETS')

    jump().click()
    expect(log.scrollTop).toBe(500)

    log.dispatchEvent(new CustomEvent('packet-log:state', { bubbles: true, detail: { atBottom: true, unread: 0 } }))
    expect(jump().hidden).toBe(true)

    log.scrollTop = 0
    vi.stubGlobal('requestAnimationFrame', (cb: () => void) => { cb(); return 0 })
    log.insertAdjacentHTML('beforeend', '<form class="uplink-inline-form"></form>')
    log.querySelector('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(log.scrollTop).toBe(0) // a drop/restore inside the log leaves the reader's place alone

    document.querySelector('.packet-input-form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(log.scrollTop).toBe(500)
  })

  it('recolors the sidebar row for a mention toast from another channel (the bump shows the count) and drops one for this channel', async () => {
    await start()
    document.body.insertAdjacentHTML('beforeend', '<div id="toast-region"></div>')
    const region = document.getElementById('toast-region')!
    const toast = (channel: string): HTMLElement => {
      region.insertAdjacentHTML('beforeend', `<a class="toast toast--mention" data-channel="${channel}">@MENTION</a>`)
      const el = region.lastElementChild as HTMLElement
      el.dispatchEvent(new CustomEvent('toast:connected', { bubbles: true, detail: { channel } }))
      return el
    }

    toast('trace')
    expect(row('trace').classList.contains('uplink-channel--mention')).toBe(true)
    expect(badge('trace').hidden).toBe(true) // no count yet: the packet's own bump brings it
    expect(region.children.length).toBe(1) // the toast stays
    await bump('trace')
    expect(badge('trace').hidden).toBe(false)
    expect(badge('trace').textContent).toBe('1')

    const own = toast('ambient')
    expect(own.isConnected).toBe(false) // already reading this channel
    expect(row('ambient').classList.contains('uplink-channel--mention')).toBe(false)

    toast('../nope') // unknown / unsafe slugs are ignored
    expect(document.querySelectorAll('.uplink-channel--mention').length).toBe(1)
  })

  it('bumps a row\'s unread badge per <i> appended into its bump slot, capped at 99+, and empties the slot', async () => {
    await start()
    expect(badge('trace').hidden).toBe(true)

    await bump('trace')
    expect(badge('trace').hidden).toBe(false)
    expect(badge('trace').textContent).toBe('1')
    expect(badge('trace').dataset.count).toBe('1')
    expect(row('trace').classList.contains('uplink-channel--unread')).toBe(true)
    expect(document.getElementById('uplink-bump-trace')!.children.length).toBe(0)

    await bump('trace')
    expect(badge('trace').textContent).toBe('2')

    await bump('ops') // server-rendered 99 → 100 reads 99+
    expect(badge('ops').textContent).toBe('99+')
    expect(badge('ops').dataset.count).toBe('100')

    await bump('nope') // a slot naming an unsafe slug never reaches querySelector
    expect(document.querySelectorAll('.uplink-channel--unread').length).toBe(2)
    expect(badge('ambient').hidden).toBe(true) // this channel has no slot
  })

  it('acks this channel as read when a foreign packet lands at the bottom: debounced, newest id, never for own packets or ids already acked', async () => {
    vi.useFakeTimers()
    viewerMeta('7')
    const fetchMock = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('fetch', fetchMock)
    await start()

    state({ atBottom: true, unread: 0 }) // connect's state: packet 41 was marked by the render
    vi.advanceTimersByTime(2000)
    expect(fetchMock).not.toHaveBeenCalled()

    landed(42, '8')
    state({ atBottom: true, unread: 0 })
    landed(43, '8')
    state({ atBottom: true, unread: 0 }) // within the debounce: one POST for the newest id
    vi.advanceTimersByTime(1499)
    expect(fetchMock).not.toHaveBeenCalled()
    vi.advanceTimersByTime(1)
    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit]
    expect(url).toBe('/uplink/reads')
    expect(init.method).toBe('POST')
    expect(init.keepalive).toBe(false)
    expect(String(init.body)).toBe('channel=ambient&last_read_message_id=43')

    state({ atBottom: true, unread: 0 }) // nothing new
    vi.advanceTimersByTime(2000)
    expect(fetchMock).toHaveBeenCalledTimes(1)

    landed(44, '7') // own packet: its POST already marked it
    state({ atBottom: true, unread: 0 })
    vi.advanceTimersByTime(2000)
    expect(fetchMock).toHaveBeenCalledTimes(1)

    landed(45, '8')
    state({ atBottom: false, unread: 1 }) // scrolled up: not seen
    vi.advanceTimersByTime(2000)
    expect(fetchMock).toHaveBeenCalledTimes(1)

    state({ atBottom: true, unread: 0 }) // jumped down, then left before the debounce
    shell().remove() // navigation: disconnect flushes, keepalive (application.stop() alone never disconnects)
    await Promise.resolve()
    expect(fetchMock).toHaveBeenCalledTimes(2)
    const [, leaving] = fetchMock.mock.calls[1] as [string, RequestInit]
    expect(leaving.keepalive).toBe(true)
    expect(String(leaving.body)).toBe('channel=ambient&last_read_message_id=45')
  })

  it('flushes a pending ack on pagehide and stays quiet without an ack url', async () => {
    vi.useFakeTimers()
    viewerMeta('7')
    const fetchMock = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('fetch', fetchMock)
    await start()

    landed(42, '8')
    state({ atBottom: true, unread: 0 })
    window.dispatchEvent(new Event('pagehide'))
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect((fetchMock.mock.calls[0][1] as RequestInit).keepalive).toBe(true)
    vi.advanceTimersByTime(2000)
    expect(fetchMock).toHaveBeenCalledTimes(1) // the timer was cleared by the flush

    shell().remove() // nothing pending: leaving posts nothing
    await Promise.resolve()
    application.stop()
    await start(fixture().replace('data-uplink-shell-ack-url-value="/uplink/reads"', ''))
    landed(50, '8')
    state({ atBottom: true, unread: 0 })
    vi.advanceTimersByTime(2000)
    shell().remove()
    await Promise.resolve()
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('prefixes the jump pill with @ MENTION when unread packets mention the viewer', async () => {
    await start()
    const log = document.getElementById('uplink-log')!

    log.dispatchEvent(new CustomEvent('packet-log:state', { bubbles: true, detail: { atBottom: false, unread: 2, mentions: 1 } }))
    expect(jump().hidden).toBe(false)
    expect(jump().textContent).toContain('@ MENTION · 2 NEW PACKETS')
    expect(jump().classList.contains('uplink-jump--mention')).toBe(true)

    log.dispatchEvent(new CustomEvent('packet-log:state', { bubbles: true, detail: { atBottom: false, unread: 3, mentions: 0 } }))
    expect(jump().textContent).toContain('3 NEW PACKETS')
    expect(jump().textContent).not.toContain('MENTION')
    expect(jump().classList.contains('uplink-jump--mention')).toBe(false)
  })

  it('focuses the composer on "/" unless typing in a field', async () => {
    await start()
    composer().blur()
    document.getElementById('other-field')!.focus()
    expect(press('/', document.getElementById('other-field')!).defaultPrevented).toBe(false)

    document.getElementById('other-field')!.blur()
    expect(press('/').defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(composer())
  })

  describe('search face (Phase 2 item 9)', () => {
    const toggle = (): HTMLButtonElement => document.querySelector('[data-uplink-shell-target="searchToggle"]')!
    const field = (): HTMLInputElement => document.querySelector('.uplink-search-field')!
    const membersToggle = (): HTMLButtonElement => document.querySelector('[data-uplink-shell-target="membersToggle"]')!

    it('flips the pane to search with the field focused — the roster preference untouched — Escape in the field closes it back to the toggle, [o] returns to the roster and opens it, [x] and a second [/] close it', async () => {
      localStorage.setItem('uplink:members', 'closed')
      await start()
      expect(shell().dataset.members).toBe('closed')
      expect(shell().dataset.pane).toBe('members')

      toggle().click()
      expect(shell().dataset.pane).toBe('search')
      expect(toggle().getAttribute('aria-pressed')).toBe('true')
      expect(document.activeElement).toBe(field())
      expect(shell().dataset.members).toBe('closed') // the CSS shows the pane for the face regardless

      expect(press('Escape', field()).defaultPrevented).toBe(true)
      expect(shell().dataset.pane).toBe('members')
      expect(toggle().getAttribute('aria-pressed')).toBe('false')
      expect(document.activeElement).toBe(toggle())

      toggle().click()
      membersToggle().click()
      expect(shell().dataset.pane).toBe('members')
      expect(shell().dataset.members).toBe('open')
      expect(localStorage.getItem('uplink:members')).toBe('open')

      toggle().click()
      toggle().click()
      expect(shell().dataset.pane).toBe('members')

      toggle().click()
      document.getElementById('search-close')!.click()
      expect(shell().dataset.pane).toBe('members')
      expect(document.activeElement).toBe(toggle())
    })

    it('runs the face as the members drawer under 768px: [/] opens it, [x] closes it, a backdrop close leaves [/] reopening it', async () => {
      mobile = true
      await start()

      toggle().click()
      expect(shell().dataset.drawer).toBe('members')
      expect(shell().dataset.pane).toBe('search')
      expect(main().hasAttribute('inert')).toBe(true)
      expect(document.activeElement).toBe(field())

      document.getElementById('search-close')!.click()
      expect(shell().dataset.drawer).toBe('')
      expect(shell().dataset.pane).toBe('members')
      expect(main().hasAttribute('inert')).toBe(false)

      toggle().click()
      backdrop().click()
      expect(shell().dataset.drawer).toBe('')
      expect(shell().dataset.pane).toBe('search') // the face is kept behind the closed drawer…
      toggle().click() // …so [/] reopens rather than closing an invisible face
      expect(shell().dataset.drawer).toBe('members')
      expect(shell().dataset.pane).toBe('search')
    })

    it('locates a hit in place when the log has the packet — the visit swallowed — and lets the link go otherwise', async () => {
      await start()
      const scrollIntoView = vi.fn()
      Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', { value: scrollIntoView, configurable: true })
      const outcomes: boolean[] = []
      const guard = new AbortController() // jsdom cannot navigate: record the controller's verdict, then swallow the click
      document.addEventListener('click', event => { outcomes.push(event.defaultPrevented); event.preventDefault() }, { signal: guard.signal })

      document.getElementById('hit-41')!.click()
      expect(outcomes).toEqual([true])
      expect(scrollIntoView.mock.instances[0]).toBe(document.getElementById('chat_message_41'))
      expect(document.getElementById('chat_message_41')!.classList.contains('packet--flash')).toBe(true)

      document.getElementById('hit-404')!.click()
      expect(outcomes).toEqual([true, false])
      expect(scrollIntoView).toHaveBeenCalledTimes(1)
      guard.abort()
    })

    it('leads back to the present: on a located log the pill reads JUMP TO PRESENT and visits the present url, as does an own send', async () => {
      await start()

      state({ atBottom: true, unread: 0, atPresent: false })
      expect(jump().hidden).toBe(false)
      expect(jump().classList.contains('uplink-jump--present')).toBe(true)
      expect(jump().textContent).toContain('JUMP TO PRESENT')
      jump().click()
      expect(Turbo.visit).toHaveBeenCalledWith('/uplink?channel=ambient')

      vi.stubGlobal('requestAnimationFrame', (cb: () => void) => { cb(); return 0 })
      composer().closest('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
      expect(Turbo.visit).toHaveBeenCalledTimes(2)

      state({ atBottom: false, unread: 2, atPresent: true })
      expect(jump().classList.contains('uplink-jump--present')).toBe(false)
      expect(jump().textContent).toContain('2 NEW PACKETS')
      jump().click()
      expect(Turbo.visit).toHaveBeenCalledTimes(2) // a plain scroll to the bottom
    })
  })
})
