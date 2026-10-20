import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import UplinkShellController from './uplink_shell_controller'

// Fixture mirrors uplink/_shell's chrome: sidebar + members panes, the
// main pane, backdrop, jump pill, stage, composer. matchMedia is stubbed
// per example to flip the mobile breakpoint.

let mobile = false

function fixture (withStage = true): string {
  return `
    <div class="uplink-shell" data-controller="uplink-shell" data-members="open" data-drawer=""
         data-action="packet-log:state->uplink-shell#logState turbo:submit-end->uplink-shell#sent keydown@document->uplink-shell#hotkey">
      <aside data-uplink-shell-target="sidebar"><a href="/uplink?channel=ambient" id="first-channel">#ambient</a></aside>
      <div data-uplink-shell-target="main">
        <button type="button" data-uplink-shell-target="membersToggle" data-action="click->uplink-shell#toggleMembers" aria-pressed="true">[o]</button>
        <button type="button" id="sidebar-toggle" data-action="click->uplink-shell#toggleSidebar">[#]</button>
        ${withStage ? `
        <section class="uplink-stage" data-uplink-shell-target="stage">
          <button type="button" data-uplink-shell-target="stageToggle" data-action="click->uplink-shell#toggleStage">[-] HIDE VIDEO</button>
          <iframe data-src="https://www.youtube.com/embed/abc" data-uplink-shell-target="stageFrame"></iframe>
        </section>` : ''}
        <div id="uplink-log"></div>
        <button type="button" hidden data-uplink-shell-target="jump" data-action="click->uplink-shell#jump">[v] <span data-uplink-shell-target="jumpCount"></span></button>
        <form class="packet-input-form"><textarea class="packet-input-text"></textarea></form>
        <input id="other-field">
      </div>
      <aside data-uplink-shell-target="members"><button id="first-member">x</button></aside>
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
  })

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

  it('focuses the composer on "/" unless typing in a field', async () => {
    await start()
    composer().blur()
    document.getElementById('other-field')!.focus()
    expect(press('/', document.getElementById('other-field')!).defaultPrevented).toBe(false)

    document.getElementById('other-field')!.blur()
    expect(press('/').defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(composer())
  })
})
