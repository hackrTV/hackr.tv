import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import UplinkShellController from './uplink_shell_controller'

vi.mock('@hotwired/turbo-rails', () => ({ Turbo: { visit: vi.fn() } }))

// Fixture mirrors uplink/_shell's chrome: sidebar (the switcher button,
// category groups of rows with unread badges + the hidden bump block)
// + members panes (the roster and the search face with two hits), the
// main pane with a log of packets, backdrop, jump pill, stage, composer,
// the quick switcher dialog. matchMedia is stubbed per example to flip
// the mobile breakpoint.

let mobile = false

function channelRow (slug: string, extra = '', count = 0, tabindex = -1): string {
  const badge = count > 0 ? `<span class="uplink-channel-badge" data-count="${count}">${count}</span>` : '<span class="uplink-channel-badge" hidden data-count="0"></span>'
  return `<a href="/uplink?channel=${slug}" ${slug === 'ambient' ? 'id="first-channel" ' : ''}class="uplink-channel${extra}" data-channel="${slug}" tabindex="${tabindex}"><span class="uplink-channel-name">#${slug}</span>${badge}</a>`
}

function fixture (withStage = true, opsCount = 99): string {
  return `
    <div class="uplink-shell" data-controller="uplink-shell" data-members="open" data-drawer="" data-pane="members" data-uplink-shell-channel-value="ambient" data-uplink-shell-ack-url-value="/uplink/reads" data-uplink-shell-present-url-value="/uplink?channel=ambient"
         data-action="packet-log:state->uplink-shell#logState turbo:submit-end->uplink-shell#sent keydown@document->uplink-shell#hotkey toast:connected@document->uplink-shell#toast">
      <aside data-uplink-shell-target="sidebar">
        <button type="button" id="switch-button" data-action="click->uplink-shell#openSwitcher">[&gt;] JUMP TO CHANNEL</button>
        <div class="uplink-channels" data-action="keydown->uplink-shell#channelKey">
          <div class="uplink-category-group" data-category="COMMS">
            <button type="button" class="uplink-category" aria-expanded="true" tabindex="-1" data-action="click->uplink-shell#toggleCategory"><span class="uplink-category-glyph">[-]</span> COMMS</button>
            <div class="uplink-category-rows">
              ${channelRow('ambient', ' uplink-channel--active', 0, 0)}
              ${channelRow('trace')}
            </div>
          </div>
          <div class="uplink-category-group" data-category="OPERATIONS">
            <button type="button" class="uplink-category" aria-expanded="true" tabindex="-1" data-action="click->uplink-shell#toggleCategory"><span class="uplink-category-glyph">[-]</span> OPERATIONS</button>
            <div class="uplink-category-rows">
              ${channelRow('ops', ' uplink-channel--unread', opsCount)}
              ${channelRow('recon')}
              <span class="uplink-channel uplink-channel--disabled" aria-disabled="true" data-channel="live"><span class="uplink-channel-name">#live</span></span>
            </div>
          </div>
          <div class="uplink-bumps" hidden data-uplink-shell-target="bumps">
            <span id="uplink-bump-trace" data-channel="trace"></span>
            <span id="uplink-bump-ops" data-channel="ops"></span>
            <span id="uplink-bump-recon" data-channel="recon"></span>
            <span id="uplink-bump-nope" data-channel="../nope"></span>
          </div>
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
      <div class="uplink-switcher" hidden data-uplink-shell-target="switcher" data-action="mousedown->uplink-shell#switcherOutside">
        <div class="uplink-switcher-box" role="dialog">
          <input type="text" class="uplink-switcher-field" data-uplink-shell-target="switcherField" data-action="input->uplink-shell#switcherInput keydown->uplink-shell#switcherKey">
          <ul class="uplink-switcher-list" data-uplink-shell-target="switcherList" data-action="click->uplink-shell#switcherPick"></ul>
        </div>
      </div>
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

  async function start (html = fixture(), title = 'Uplink — hackr.tv'): Promise<void> {
    document.body.innerHTML = html
    document.title = title
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

  describe('deferred shell UX: categories, keyboard ring, quick switcher, tab title', () => {
    const group = (name: string): HTMLElement => document.querySelector(`.uplink-category-group[data-category="${name}"]`)!
    const heading = (name: string): HTMLButtonElement => group(name).querySelector('.uplink-category')!
    const glyph = (name: string): string => heading(name).querySelector('.uplink-category-glyph')!.textContent!
    const switcher = (): HTMLElement => document.querySelector('[data-uplink-shell-target="switcher"]')!
    const field = (): HTMLInputElement => document.querySelector('[data-uplink-shell-target="switcherField"]')!
    const options = (): HTMLElement[] => Array.from(document.querySelectorAll<HTMLElement>('.uplink-switcher-option'))
    const listed = (): string[] => options().map(option => option.dataset.channel!)
    const selected = (): string | undefined => options().find(option => option.getAttribute('aria-selected') === 'true')?.dataset.channel
    const stops = (): string[] => Array.from(document.querySelectorAll<HTMLElement>('.uplink-category, .uplink-channel')).filter(el => el.getAttribute('tabindex') === '0').map(el => el.dataset.channel ?? el.textContent!.trim())

    function type (value: string): void {
      field().value = value
      field().dispatchEvent(new Event('input', { bubbles: true }))
    }

    function mention (channel: string): void {
      document.body.dispatchEvent(new CustomEvent('toast:connected', { bubbles: true, detail: { channel } }))
    }

    it('collapses a category from its heading — rows hide but the active and unread ones, [+] and aria-expanded flip, remembered across loads — and a bump or a mention toast brings a hidden row out', async () => {
      await start()
      heading('OPERATIONS').click()
      expect(group('OPERATIONS').hasAttribute('data-collapsed')).toBe(true)
      expect(heading('OPERATIONS').getAttribute('aria-expanded')).toBe('false')
      expect(glyph('OPERATIONS')).toBe('[+]')
      expect(row('ops').hidden).toBe(false) // unread: stays in view
      expect(row('recon').hidden).toBe(true)
      expect(document.querySelector<HTMLElement>('.uplink-channel[data-channel="live"]')!.hidden).toBe(true) // the disabled span too
      expect(localStorage.getItem('uplink:collapsed')).toBe('["OPERATIONS"]')

      heading('COMMS').click()
      expect(row('ambient').hidden).toBe(false) // the channel on screen stays
      expect(row('trace').hidden).toBe(true)
      expect(localStorage.getItem('uplink:collapsed')).toBe('["COMMS","OPERATIONS"]')

      await bump('trace')
      expect(row('trace').hidden).toBe(false) // unread now: out it comes
      expect(group('COMMS').hasAttribute('data-collapsed')).toBe(true) // the group stays folded
      mention('recon')
      expect(row('recon').hidden).toBe(false)
      expect(row('recon').classList.contains('uplink-channel--mention')).toBe(true)

      heading('COMMS').click()
      expect(group('COMMS').hasAttribute('data-collapsed')).toBe(false)
      expect(glyph('COMMS')).toBe('[-]')
      expect(localStorage.getItem('uplink:collapsed')).toBe('["OPERATIONS"]')

      application.stop()
      await start()
      expect(group('OPERATIONS').hasAttribute('data-collapsed')).toBe(true) // remembered
      expect(row('recon').hidden).toBe(true)
      expect(group('COMMS').hasAttribute('data-collapsed')).toBe(false)

      localStorage.setItem('uplink:collapsed', '{"not":"a list"}') // garbage in storage is ignored
      application.stop()
      await start()
      expect(document.querySelectorAll('[data-collapsed]').length).toBe(0)
    })

    it('keeps the list one Tab stop — tabindex 0 on the active row — and walks headings + shown rows with the arrows (wrapping, Home/End; Left/Right fold a heading, Left climbs from a row; hidden rows skipped, disabled spans never in)', async () => {
      await start()
      expect(stops()).toEqual(['ambient'])

      row('ambient').focus()
      expect(press('ArrowDown', row('ambient')).defaultPrevented).toBe(true)
      expect(document.activeElement).toBe(row('trace'))
      expect(stops()).toEqual(['trace']) // the stop moves with focus
      press('ArrowDown', row('trace'))
      expect(document.activeElement).toBe(heading('OPERATIONS'))
      press('ArrowDown', heading('OPERATIONS'))
      expect(document.activeElement).toBe(row('ops'))
      press('End', row('ops'))
      expect(document.activeElement).toBe(row('recon')) // #live's disabled span is not in the ring
      press('ArrowDown', row('recon'))
      expect(document.activeElement).toBe(heading('COMMS')) // wraps
      press('ArrowUp', heading('COMMS'))
      expect(document.activeElement).toBe(row('recon'))
      press('Home', row('recon'))
      expect(document.activeElement).toBe(heading('COMMS'))

      press('ArrowLeft', heading('COMMS')) // fold
      expect(group('COMMS').hasAttribute('data-collapsed')).toBe(true)
      expect(localStorage.getItem('uplink:collapsed')).toBe('["COMMS"]')
      expect(stops()).toEqual(['ambient']) // the active row takes the stop back
      press('ArrowDown', heading('COMMS'))
      expect(document.activeElement).toBe(row('ambient'))
      press('ArrowDown', row('ambient'))
      expect(document.activeElement).toBe(heading('OPERATIONS')) // #trace, hidden, is skipped
      press('ArrowDown', heading('OPERATIONS'))
      press('ArrowLeft', row('ops'))
      expect(document.activeElement).toBe(heading('OPERATIONS')) // a row climbs to its heading
      expect(press('ArrowRight', row('ops')).defaultPrevented).toBe(false) // nothing to the right of a row
      press('Home', heading('OPERATIONS'))
      press('ArrowRight', heading('COMMS')) // unfold
      expect(group('COMMS').hasAttribute('data-collapsed')).toBe(false)
      expect(row('trace').hidden).toBe(false)

      expect(press('ArrowDown', row('ambient'), { ctrlKey: true }).defaultPrevented).toBe(false) // modified keys are not the list's
      expect(press('ArrowDown', composer()).defaultPrevented).toBe(false) // nor keys elsewhere
      expect(press('ArrowDown', document.getElementById('switch-button')!).defaultPrevented).toBe(false) // the button above the list is outside the ring
    })

    it('opens the quick switcher on Ctrl/Cmd+K or the sidebar button with every row listed (the channel on screen marked HERE, badges carried), filters as you type — name first, then category — walks with Up/Down, visits on Enter or click, and closes on Escape back to where focus was, on Tab, on a second Ctrl+K, on a scrim press', async () => {
      await start()
      expect(switcher().hidden).toBe(true)
      composer().focus()
      expect(press('k', document.body, { ctrlKey: true }).defaultPrevented).toBe(true)
      expect(switcher().hidden).toBe(false)
      expect(document.activeElement).toBe(field())
      expect(listed()).toEqual(['ambient', 'trace', 'ops', 'recon']) // links only, sidebar order
      expect(options()[0]!.querySelector('.uplink-switcher-here')!.textContent).toBe('HERE')
      expect(options()[0]!.querySelector('.uplink-switcher-cat')!.textContent).toBe('COMMS')
      expect(options()[2]!.querySelector('.uplink-switcher-badge')!.textContent).toBe('99')
      expect(options()[1]!.querySelector('.uplink-switcher-badge')).toBeNull()
      expect(selected()).toBe('ambient')
      expect(field().getAttribute('aria-activedescendant')).toBe('uplink-switcher-option-ambient')

      type('#R')
      expect(listed()).toEqual(['recon', 'trace', 'ops']) // starts with it, contains it, its category (OPERATIONS) does
      expect(selected()).toBe('recon')
      press('ArrowDown', field())
      expect(selected()).toBe('trace')
      press('ArrowUp', field())
      press('ArrowUp', field())
      expect(selected()).toBe('ops') // wraps
      expect(field().getAttribute('aria-activedescendant')).toBe('uplink-switcher-option-ops')
      type('zzz')
      expect(options()).toEqual([])
      expect(document.querySelector('.uplink-switcher-empty')!.textContent).toBe('NO CHANNEL MATCHES')
      expect(field().hasAttribute('aria-activedescendant')).toBe(false)
      press('Enter', field()) // nothing to pick
      expect(Turbo.visit).not.toHaveBeenCalled()
      expect(switcher().hidden).toBe(false)

      expect(press('Escape', field()).defaultPrevented).toBe(true)
      expect(switcher().hidden).toBe(true)
      expect(document.activeElement).toBe(composer()) // back where focus was

      document.getElementById('switch-button')!.click()
      expect(switcher().hidden).toBe(false)
      expect(field().value).toBe('') // a fresh query each time
      type('tr')
      press('Enter', field())
      expect(Turbo.visit).toHaveBeenCalledWith('/uplink?channel=trace')
      expect(switcher().hidden).toBe(true)

      press('k', document.body, { metaKey: true })
      expect(switcher().hidden).toBe(false)
      press('k', field(), { ctrlKey: true }) // toggles closed from the field too
      expect(switcher().hidden).toBe(true)

      press('k', document.body, { ctrlKey: true })
      options()[0]!.click() // the channel on screen: just closes
      expect(switcher().hidden).toBe(true)
      expect(Turbo.visit).toHaveBeenCalledTimes(1)

      press('k', document.body, { ctrlKey: true })
      options()[3]!.querySelector('.uplink-switcher-name')!.dispatchEvent(new MouseEvent('click', { bubbles: true }))
      expect(Turbo.visit).toHaveBeenLastCalledWith('/uplink?channel=recon')

      press('k', document.body, { ctrlKey: true })
      switcher().dispatchEvent(new MouseEvent('mousedown', { bubbles: true })) // the scrim
      expect(switcher().hidden).toBe(true)
      press('k', document.body, { ctrlKey: true })
      expect(options()[1]!.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }))).toBe(false) // inside the box: the field keeps focus
      expect(switcher().hidden).toBe(false)
      press('Tab', field())
      expect(switcher().hidden).toBe(true)
      expect(press('k', document.body, { ctrlKey: true, altKey: true }).defaultPrevented).toBe(false) // not the chord
    })

    it('badges the tab title with the unread total — the sidebar badges plus this channel\'s — with @ when one mentions you, capped 99+, cleared when nothing waits, dropped on the way out unless the next page\'s title is in', async () => {
      await start(fixture(true, 3), '(7) Uplink — hackr.tv') // a stale prefix is not part of the base
      expect(document.title).toBe('(3) Uplink — hackr.tv') // #ops' server-rendered badge
      await bump('trace')
      expect(document.title).toBe('(4) Uplink — hackr.tv')
      state({ atBottom: false, unread: 2 })
      expect(document.title).toBe('(6) Uplink — hackr.tv')
      state({ atBottom: false, unread: 2, mentions: 1 })
      expect(document.title).toBe('(@6) Uplink — hackr.tv')
      state({ atBottom: true, unread: 0 })
      expect(document.title).toBe('(4) Uplink — hackr.tv')
      mention('recon')
      expect(document.title).toBe('(4) Uplink — hackr.tv') // no count yet: the packet's bump brings it
      await bump('recon')
      expect(document.title).toBe('(@5) Uplink — hackr.tv')
      for (let i = 0; i < 95; i++) await bump('trace')
      expect(document.title).toBe('(@99+) Uplink — hackr.tv')

      document.body.innerHTML = '' // the body swapped out: disconnect
      await Promise.resolve()
      expect(document.title).toBe('Uplink — hackr.tv') // restored on disconnect
      application.stop()

      await start(fixture(true, 0))
      expect(document.title).toBe('Uplink — hackr.tv') // nothing waits
      await bump('trace')
      expect(document.title).toBe('(1) Uplink — hackr.tv')
      document.title = 'Vault — hackr.tv' // Turbo merged the next page's head before the swap
      document.body.innerHTML = ''
      await Promise.resolve()
      expect(document.title).toBe('Vault — hackr.tv')
    })
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
