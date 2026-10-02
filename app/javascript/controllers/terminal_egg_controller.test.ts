import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import TerminalEggController from './terminal_egg_controller'

// Terminal easter-egg openers: Konami code, Ctrl+`, typing "/terminal",
// window.hackr.terminal(), terminal:open event, [data-terminal-open].

const KONAMI = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'KeyB', 'KeyA']

const FIXTURE = `
  <div data-controller="terminal-egg">
    <div data-terminal-egg-target="backdrop" hidden></div>
    <div data-terminal-egg-target="panel" hidden>
      <iframe data-terminal-egg-target="frame"></iframe>
    </div>
  </div>
  <button id="nav-open" data-terminal-open>TERMINAL</button>
  <input id="field">`

describe('TerminalEggController', () => {
  let application: Application

  const panel = (): HTMLElement => document.querySelector('[data-terminal-egg-target="panel"]')!
  const backdrop = (): HTMLElement => document.querySelector('[data-terminal-egg-target="backdrop"]')!
  const frame = (): HTMLIFrameElement => document.querySelector('[data-terminal-egg-target="frame"]')!

  function pressKey (key: string, opts: KeyboardEventInit = {}, target: EventTarget = document.body): void {
    target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true, ...opts }))
  }

  function pressCode (code: string): void {
    document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'x', code, bubbles: true }))
  }

  beforeEach(async () => {
    vi.stubGlobal('requestAnimationFrame', (cb: FrameRequestCallback) => { cb(0); return 0 })
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('terminal-egg', TerminalEggController)
    await Promise.resolve()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application.stop()
    document.body.style.overflow = ''
    vi.unstubAllGlobals()
  })

  it('opens via the full Konami sequence, lazy-loading the iframe', () => {
    KONAMI.forEach(pressCode)

    expect(panel().hidden).toBe(false)
    expect(backdrop().hidden).toBe(false)
    expect(frame().src).toContain('/terminal')
    expect(document.body.style.overflow).toBe('hidden')
  })

  it('resets the Konami progress on a wrong key', () => {
    KONAMI.slice(0, 9).forEach(pressCode)
    pressCode('KeyQ')
    pressCode('KeyA')
    expect(panel().hidden).toBe(true)
  })

  it('toggles with Ctrl+` outside inputs only', () => {
    pressKey('`', { ctrlKey: true })
    expect(panel().hidden).toBe(false)

    pressKey('`', { ctrlKey: true })
    expect(panel().classList.contains('terminal-egg--open')).toBe(false)

    // From inside an input: ignored
    document.body.innerHTML = FIXTURE
    pressKey('`', { ctrlKey: true }, document.getElementById('field')!)
    expect(panel().hidden).toBe(true)
  })

  it('opens when "/terminal" is typed outside inputs', () => {
    for (const ch of '/terminal') pressKey(ch)
    expect(panel().hidden).toBe(false)
  })

  it('ignores typed trigger inside inputs', () => {
    const field = document.getElementById('field')!
    for (const ch of '/terminal') pressKey(ch, {}, field)
    expect(panel().hidden).toBe(true)
  })

  it('opens from window.hackr.terminal(), terminal:open, and [data-terminal-open] clicks', () => {
    expect(window.hackr!.terminal()).toBe('Accessing terminal…')
    expect(panel().hidden).toBe(false)

    panel().hidden = true
    window.dispatchEvent(new Event('terminal:open'))
    expect(panel().hidden).toBe(false)

    panel().hidden = true
    document.getElementById('nav-open')!.click()
    expect(panel().hidden).toBe(false)
  })

  it('closes on Escape and restores body scroll', () => {
    vi.useFakeTimers()
    pressKey('`', { ctrlKey: true })
    expect(panel().hidden).toBe(false)

    pressKey('Escape')
    vi.advanceTimersByTime(400)
    expect(panel().hidden).toBe(true)
    expect(backdrop().hidden).toBe(true)
    expect(document.body.style.overflow).toBe('')
    vi.useRealTimers()
  })

  it('removes window.hackr on disconnect', async () => {
    expect(window.hackr).toBeDefined()
    document.body.innerHTML = ''
    await Promise.resolve()
    expect(window.hackr).toBeUndefined()
  })
})
