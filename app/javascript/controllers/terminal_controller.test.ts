import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import { Turbo } from '@hotwired/turbo-rails'
import TerminalController from './terminal_controller'

vi.mock('@hotwired/turbo-rails', () => ({ Turbo: { visit: vi.fn() } }))

// The home console: the server-rendered screen is revealed line by line
// (skippable), then the prompt runs commands off the rows' data-command.

const HTML = (boot = 'pending'): string => `
<div class="console" data-controller="terminal" data-boot="${boot}" data-action="keydown@document->terminal#skip click->terminal#skip">
  <a class="console-banner console-line" data-terminal-target="line" href="/">banner</a>
  <div class="console-line" data-terminal-target="line">HACKR.TV BROADCAST SYSTEM</div>
  <div class="console-rule console-line" data-terminal-target="line">// FEATURED ARTISTS //</div>
  <div class="console-row console-line" data-terminal-target="line"><a class="console-link" href="/thecyberpulse" data-command="0">TCP</a></div>
  <div class="console-row console-line" data-terminal-target="line"><a class="console-link" href="/fm" data-command="fm">hackr.fm</a></div>
  <div class="console-reply" data-terminal-target="reply" hidden></div>
  <div class="console-prompt" data-terminal-target="inputLine" hidden>
    <span class="console-typed" data-terminal-target="typed"></span>
    <input type="text" class="console-input" data-terminal-target="input" data-action="input->terminal#inputChanged keydown->terminal#inputKeydown">
  </div>
</div>`

describe('TerminalController', () => {
  let application: Application
  let mobile = false
  let reducedMotion = false

  const start = async (boot = 'pending'): Promise<void> => {
    document.body.innerHTML = HTML(boot)
    application = Application.start()
    application.register('terminal', TerminalController)
    await Promise.resolve()
  }
  const root = (): HTMLElement => document.querySelector('.console') as HTMLElement
  const revealed = (): number => document.querySelectorAll('.console-line--on').length
  const prompt = (): HTMLElement => document.querySelector('.console-prompt') as HTMLElement
  const reply = (): HTMLElement => document.querySelector('.console-reply') as HTMLElement
  const input = (): HTMLInputElement => document.querySelector('.console-input') as HTMLInputElement
  const type = (text: string): void => {
    input().value = text
    input().dispatchEvent(new Event('input', { bubbles: true }))
    input().dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }))
  }

  beforeEach(() => {
    vi.useFakeTimers()
    mobile = false
    reducedMotion = false
    vi.stubGlobal('matchMedia', (query: string) => ({
      matches: query.includes('max-width') ? mobile : reducedMotion,
      media: query,
      addEventListener: () => undefined,
      removeEventListener: () => undefined
    }))
    vi.stubGlobal('requestAnimationFrame', (callback: FrameRequestCallback) => { callback(0); return 0 })
    vi.mocked(Turbo.visit).mockClear()
  })

  afterEach(async () => {
    application.stop()
    document.body.innerHTML = ''
    vi.useRealTimers()
    vi.unstubAllGlobals()
    await Promise.resolve()
  })

  it('reveals the lines in order, pausing after the banner and before a rule, then shows the prompt', async () => {
    await start()
    expect(revealed()).toBe(1)
    expect(prompt().hidden).toBe(true)
    expect(root().dataset.boot).toBe('pending')

    vi.advanceTimersByTime(140)
    expect(revealed()).toBe(2)
    vi.advanceTimersByTime(30)
    expect(revealed()).toBe(2) // the rule waits the long pause
    vi.advanceTimersByTime(110)
    expect(revealed()).toBe(3)

    vi.runAllTimers()
    expect(revealed()).toBe(5)
    expect(root().dataset.boot).toBe('done')
    expect(prompt().hidden).toBe(false)
    expect(document.activeElement).toBe(input())
  })

  it('a keydown skips straight to the full screen', async () => {
    await start()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'x' }))
    expect(revealed()).toBe(5)
    expect(root().dataset.boot).toBe('done')
    expect(prompt().hidden).toBe(false)
  })

  it('renders at once on a phone, under reduced motion, and from a restored snapshot', async () => {
    mobile = true
    await start()
    expect(revealed()).toBe(5)
    expect(root().dataset.boot).toBe('done')
    application.stop()

    mobile = false
    reducedMotion = true
    await start()
    expect(revealed()).toBe(5)
    application.stop()

    reducedMotion = false
    await start('done')
    expect(revealed()).toBe(5)
    expect(prompt().hidden).toBe(false)
  })

  it('runs the prompt: a tag visits its row, ? lists the tags, unknown and clear reply', async () => {
    await start()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'x' }))

    type('xyzzy')
    expect(reply().hidden).toBe(false)
    expect(reply().textContent).toContain('> xyzzy')
    expect(reply().textContent).toContain('UNKNOWN COMMAND: xyzzy')
    expect(reply().querySelector('.console-err')?.textContent).toBe('UNKNOWN COMMAND: xyzzy')
    expect(input().value).toBe('')
    expect(Turbo.visit).not.toHaveBeenCalled()

    type('?')
    expect(reply().textContent).toContain('COMMANDS: 0 fm · clear')
    type('help')
    expect(reply().querySelectorAll('div').length).toBe(6)

    type('clear')
    expect(reply().hidden).toBe(true)
    expect(reply().children.length).toBe(0)

    type('FM')
    expect(reply().textContent).toContain('CONNECTING /fm ...')
    expect(Turbo.visit).toHaveBeenCalledWith('http://localhost:3000/fm')
  })
})
