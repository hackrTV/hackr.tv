import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PopoverController from './popover_controller'

// Fixture mirrors uplink/_shell: the popover controller on the shell root
// with its document-level actions, the hidden uplink-popover turbo-frame
// in the channel pane, packet author links carrying the profile URL as
// an action param, the packet's [...] + a roster row's [...] naming the
// second frame (uplink-modmenu, a grid child) in their frame param, the
// header's [◆] naming the third (uplink-pins, in the pane), and a
// further frame (the log's) whose loads must be ignored. jsdom has no
// layout: rects and offset sizes are stubbed, and the frames'
// offsetParent is null so the shell root stands in as the clamp box.

function fixture (): string {
  return `
    <div class="uplink-shell" data-controller="popover"
         data-action="turbo:frame-load->popover#loaded mousedown@document->popover#outside keydown@document->popover#keydown turbo:submit-end->popover#submitted">
      <div class="uplink-main">
        <h2 id="outside">#ambient</h2>
        <button id="pins" type="button" class="uplink-chanhead-pins" data-action="click->popover#open" data-popover-url-param="/uplink/pins?channel=ambient" data-popover-frame-param="uplink-pins" data-popover-align-param="end">[◆] 1</button>
        <turbo-frame id="uplink-log-frame"><div id="uplink-log">
          <div id="chat_message_1" class="packet">p1</div>
          <a id="a1" class="packet-author" href="/wire/xeraen" data-action="click->popover#open" data-popover-url-param="/uplink/profiles/xeraen">@xeraen</a>
          <button id="m1" type="button" class="packet-mod-button" data-action="click->popover#open" data-popover-url-param="/uplink/packets/1/menu" data-popover-frame-param="uplink-modmenu" data-popover-align-param="end">...</button>
          <a id="a2" class="packet-author" href="/wire/ghost" data-action="click->popover#open" data-popover-url-param="/uplink/profiles/ghost">@ghost</a>
          <a id="a3" class="packet-author" href="/wire/nobody" data-action="click->popover#open">@nobody</a>
          <button id="m9" type="button" data-action="click->popover#open" data-popover-url-param="/uplink/packets/9/menu" data-popover-frame-param="uplink-nowhere">…</button>
        </div></turbo-frame>
        <form id="composer" class="packet-input-form"></form>
        <turbo-frame id="uplink-popover" class="uplink-popover-frame" target="_top" hidden data-popover-target="frame"></turbo-frame>
        <turbo-frame id="uplink-pins" class="uplink-pins-frame" target="_top" hidden data-popover-target="frame"></turbo-frame>
      </div>
      <aside class="uplink-members-pane">
        <li class="uplink-member" data-callsign="A1B2C3"><button id="r1" type="button" class="uplink-member-mod" data-action="click->popover#open" data-popover-url-param="/uplink/operatives/a1b2c3/menu" data-popover-frame-param="uplink-modmenu" data-popover-align-param="end">...</button></li>
      </aside>
      <turbo-frame id="uplink-modmenu" class="uplink-modmenu-frame" target="_top" hidden data-popover-target="frame"></turbo-frame>
    </div>`
}

const CARD = '<div class="uplink-popover" tabindex="-1">@xeraen <button type="button" class="uplink-popover-close" data-action="click->popover#dismiss">[x]</button></div>'
const MENU = '<div class="uplink-modmenu" tabindex="-1"><form class="uplink-modmenu-form"><button type="submit" class="uplink-modmenu-item">SQUELCH 10M</button></form></div>'
const PINS = '<div class="uplink-pins" tabindex="-1"><div id="uplink-pins-list">' +
  '<a href="/uplink?around=1&channel=ambient" class="uplink-pin-jump" data-action="click->popover#jump" data-popover-id-param="1">jump 1</a>' +
  '<a href="/uplink?around=404&channel=ambient" class="uplink-pin-jump" data-action="click->popover#jump" data-popover-id-param="404">jump 404</a>' +
  '<form class="uplink-pin-unpin-form" data-popover-stay="true"><button type="submit">UNPIN</button></form></div></div>'

type Box = { left: number, top: number, width: number, height: number }

function rect (el: Element, { left, top, width, height }: Box): void {
  el.getBoundingClientRect = () => ({ left, top, width, height, right: left + width, bottom: top + height, x: left, y: top, toJSON: () => ({}) }) as DOMRect
}

function size (el: Element, props: Record<string, number>): void {
  for (const [key, value] of Object.entries(props)) Object.defineProperty(el, key, { value, configurable: true })
}

describe('PopoverController', () => {
  let application: Application

  const shell = (): HTMLElement => document.querySelector('.uplink-shell')!
  const frame = (): HTMLElement => document.getElementById('uplink-popover')!
  const menu = (): HTMLElement => document.getElementById('uplink-modmenu')!
  const pins = (): HTMLElement => document.getElementById('uplink-pins')!
  const author = (id: string): HTMLAnchorElement => document.getElementById(id) as HTMLAnchorElement
  const trigger = (id: string): HTMLButtonElement => document.getElementById(id) as HTMLButtonElement

  function click (el: Element, init: MouseEventInit = {}): MouseEvent {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, button: 0, ...init })
    el.dispatchEvent(event)
    return event
  }

  function mousedown (el: Element): void {
    el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true }))
  }

  function press (key: string, target: EventTarget = document.body, prevented = false): KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true })
    if (prevented) event.preventDefault()
    target.dispatchEvent(event)
    return event
  }

  // Loads the card the way Turbo would: content in, turbo:frame-load up.
  function load (el: HTMLElement = frame(), html = CARD): void {
    el.innerHTML = html
    el.dispatchEvent(new CustomEvent('turbo:frame-load', { bubbles: true }))
  }

  beforeEach(async () => {
    document.body.innerHTML = fixture()
    size(shell(), { clientWidth: 800, clientHeight: 600 })
    rect(shell(), { left: 0, top: 0, width: 800, height: 600 })
    size(frame(), { offsetWidth: 320, offsetHeight: 0 })
    size(menu(), { offsetWidth: 240, offsetHeight: 0 })
    size(pins(), { offsetWidth: 440, offsetHeight: 0 })
    rect(trigger('pins'), { left: 600, top: 10, width: 120, height: 24 })
    rect(author('a1'), { left: 100, top: 300, width: 60, height: 16 })
    rect(author('a2'), { left: 700, top: 560, width: 60, height: 16 })
    rect(trigger('m1'), { left: 760, top: 300, width: 16, height: 16 })
    rect(trigger('r1'), { left: 990, top: 120, width: 16, height: 16 }) // in the roster pane, right of the clamp box
    application = Application.start()
    application.register('popover', PopoverController)
    await Promise.resolve()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
  })

  it('opens from an author click: swallows the visit, shows the frame with the profile src, parks it under the author', () => {
    const event = click(author('a1'))

    expect(event.defaultPrevented).toBe(true)
    expect(frame().hidden).toBe(false)
    expect(frame().getAttribute('src')).toBe('/uplink/profiles/xeraen')
    expect(frame().style.left).toBe('100px')
    expect(frame().style.top).toBe('320px') // anchor bottom (316) + 4
  })

  it('lets modified clicks and links without a url through to the WIRE profile', () => {
    expect(click(author('a1'), { ctrlKey: true }).defaultPrevented).toBe(false)
    expect(click(author('a1'), { metaKey: true }).defaultPrevented).toBe(false)
    expect(click(author('a1'), { shiftKey: true }).defaultPrevented).toBe(false)
    expect(click(author('a1'), { button: 1 }).defaultPrevented).toBe(false)
    expect(click(author('a3')).defaultPrevented).toBe(false)
    expect(frame().hidden).toBe(true)
    expect(frame().hasAttribute('src')).toBe(false)
  })

  it('clamps to the pane and flips above the author when there is no room below, settling once the card has a height', () => {
    click(author('a2'))
    expect(frame().style.left).toBe('472px') // 800 - 320 - 8
    expect(frame().style.top).toBe('580px') // no height yet: still below

    size(frame(), { offsetWidth: 320, offsetHeight: 200 })
    load()
    expect(frame().style.top).toBe('356px') // 560 - 200 - 4: above the author

    rect(author('a1'), { left: 2, top: 2, width: 60, height: 16 })
    click(author('a1'))
    expect(frame().style.left).toBe('8px')
    expect(frame().style.top).toBe('22px')
  })

  it('focuses the card once its own frame loads and ignores other frames', () => {
    click(author('a1'))
    load(document.getElementById('uplink-log-frame')!, '<div class="uplink-popover" id="decoy" tabindex="-1"></div>')
    expect(document.activeElement).not.toBe(document.getElementById('decoy'))

    load()
    expect(document.activeElement).toBe(frame().querySelector('.uplink-popover'))
  })

  it('closes on Escape or [x] handing focus back to the author, and on an outside mousedown — not one inside or on the author', async () => {
    click(author('a1'))
    load()
    mousedown(frame().querySelector('.uplink-popover')!)
    mousedown(author('a1'))
    expect(frame().hidden).toBe(false)

    expect(press('Escape', frame().querySelector('.uplink-popover')!).defaultPrevented).toBe(true)
    expect(frame().hidden).toBe(true)
    expect(frame().hasAttribute('src')).toBe(false)
    expect(frame().innerHTML).toBe('')
    expect(document.activeElement).toBe(author('a1'))

    click(author('a2'))
    load()
    await Promise.resolve() // Stimulus binds the card's [x] action on the mutation microtask
    frame().querySelector<HTMLButtonElement>('.uplink-popover-close')!.click()
    expect(frame().hidden).toBe(true)
    expect(document.activeElement).toBe(author('a2'))

    click(author('a1'))
    mousedown(document.getElementById('outside')!)
    expect(frame().hidden).toBe(true)
  })

  it('toggles shut on a second click of the same author and re-targets on another', () => {
    click(author('a1'))
    click(author('a1'))
    expect(frame().hidden).toBe(true)

    click(author('a1'))
    click(author('a2'))
    expect(frame().hidden).toBe(false)
    expect(frame().getAttribute('src')).toBe('/uplink/profiles/ghost')
  })

  it('routes a trigger naming a frame to that frame — one popover open at a time — and places/focuses on that frame\'s own load', () => {
    click(author('a1'))
    expect(frame().hidden).toBe(false)

    const event = click(trigger('m1'))
    expect(event.defaultPrevented).toBe(true)
    expect(frame().hidden).toBe(true) // the card gave way
    expect(frame().hasAttribute('src')).toBe(false)
    expect(menu().hidden).toBe(false)
    expect(menu().getAttribute('src')).toBe('/uplink/packets/1/menu')
    expect(menu().style.left).toBe('536px') // align end: the trigger's right edge (776) - 240
    expect(menu().style.top).toBe('320px')

    load(frame(), CARD) // the other frame loading is not ours
    expect(document.activeElement).not.toBe(frame().querySelector('.uplink-popover'))

    load(menu(), MENU)
    expect(document.activeElement).toBe(menu().querySelector('.uplink-modmenu'))

    click(author('a2')) // and back: the menu gives way to the card
    expect(menu().hidden).toBe(true)
    expect(menu().innerHTML).toBe('')
    expect(frame().hidden).toBe(false)
    expect(frame().getAttribute('src')).toBe('/uplink/profiles/ghost')
  })

  it('opens the menu from a roster row (clamped into the shell), toggles it on the same row, and ignores a trigger naming an unknown frame', () => {
    click(trigger('r1'))
    expect(menu().hidden).toBe(false)
    expect(menu().getAttribute('src')).toBe('/uplink/operatives/a1b2c3/menu')
    expect(menu().style.left).toBe('552px') // 1006 - 240 = 766, clamped to 800 - 240 - 8
    expect(menu().style.top).toBe('140px')

    click(trigger('r1'))
    expect(menu().hidden).toBe(true)

    expect(click(trigger('m9')).defaultPrevented).toBe(false)
    expect(menu().hidden).toBe(true)
    expect(frame().hidden).toBe(true)
  })

  it('closes the open frame when a form inside it finishes submitting, handing focus back to its trigger; other forms are none of its business', () => {
    click(trigger('m1'))
    load(menu(), MENU)
    document.getElementById('composer')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(menu().hidden).toBe(false)

    menu().querySelector('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(menu().hidden).toBe(true)
    expect(menu().hasAttribute('src')).toBe(false)
    expect(document.activeElement).toBe(trigger('m1'))

    click(trigger('r1'))
    load(menu(), MENU)
    expect(press('Escape', menu().querySelector('.uplink-modmenu')!).defaultPrevented).toBe(true)
    expect(menu().hidden).toBe(true)
    expect(document.activeElement).toBe(trigger('r1'))
  })

  it('opens the pins panel from the header button into its own frame (align end), stays open when a data-popover-stay form inside finishes — a plain form still closes — and gives way to the next popover', () => {
    click(trigger('pins'))
    expect(pins().hidden).toBe(false)
    expect(pins().getAttribute('src')).toBe('/uplink/pins?channel=ambient')
    expect(pins().style.left).toBe('280px') // the button's right edge (720) - 440
    expect(pins().style.top).toBe('38px') // 34 + 4
    load(pins(), PINS)
    expect(document.activeElement).toBe(pins().querySelector('.uplink-pins'))

    pins().querySelector('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(pins().hidden).toBe(false) // UNPIN's reply re-renders the list in place

    click(trigger('m1'))
    expect(pins().hidden).toBe(true) // one popover at a time
    expect(pins().innerHTML).toBe('')
    load(menu(), MENU)
    menu().querySelector('form')!.dispatchEvent(new CustomEvent('turbo:submit-end', { bubbles: true, detail: { success: true } }))
    expect(menu().hidden).toBe(true)
  })

  it('jumps from a pins-panel row: scrolls to + flashes the packet and closes the panel, swallowing the visit; a pin that is not in the log lets its link go and leaves the panel open', async () => {
    const scrollIntoView = vi.fn()
    Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', { value: scrollIntoView, configurable: true })
    const outcomes: boolean[] = []
    const guard = new AbortController() // jsdom cannot navigate: record the controller's verdict, then swallow the click
    document.addEventListener('click', event => { outcomes.push(event.defaultPrevented); event.preventDefault() }, { signal: guard.signal })
    click(trigger('pins'))
    load(pins(), PINS)
    await Promise.resolve() // Stimulus binds the injected rows' actions on the mutation microtask
    const rows = pins().querySelectorAll<HTMLAnchorElement>('.uplink-pin-jump')

    rows[1].click() // id 404: beyond the loaded history — /uplink?around=404 opens the log on it
    expect(outcomes.at(-1)).toBe(false)
    expect(pins().hidden).toBe(false)
    expect(scrollIntoView).not.toHaveBeenCalled()
    expect(document.querySelector('.packet--flash')).toBeNull()

    rows[0].click()
    expect(outcomes.at(-1)).toBe(true)
    expect(scrollIntoView).toHaveBeenCalledWith({ block: 'center' })
    expect(scrollIntoView.mock.instances[0]).toBe(document.getElementById('chat_message_1'))
    expect(document.getElementById('chat_message_1')!.classList.contains('packet--flash')).toBe(true)
    expect(pins().hidden).toBe(true)
    expect(pins().innerHTML).toBe('')
    guard.abort()
  })

  it('leaves an Escape another layer already handled alone, and closes before the page is cached', () => {
    click(author('a1'))
    expect(press('Escape', document.body, true).defaultPrevented).toBe(true)
    expect(frame().hidden).toBe(false)

    press('Escape') // closed state: not claimed either
    expect(frame().hidden).toBe(true)
    expect(press('Escape').defaultPrevented).toBe(false)

    click(author('a1'))
    document.dispatchEvent(new Event('turbo:before-cache'))
    expect(frame().hidden).toBe(true)
  })
})
