import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { Application } from '@hotwired/stimulus'
import GridCommandController from './grid_command_controller'

// Fixture mirrors the grid game command form (grid/game/show): turbo
// form with log pane, input, and submit button. Turbo submit lifecycle
// is simulated via turbo:submit-start / turbo:submit-end dispatches.

const HISTORY_KEY = 'grid_command_history'

const FIXTURE = `
  <div data-controller="grid-command">
    <div id="grid-log" data-grid-command-target="log"></div>
    <div id="breach-log" hidden></div>
    <form data-action="submit->grid-command#submit">
      <input data-grid-command-target="input"
             data-action="keydown->grid-command#keydown">
      <button type="submit" data-grid-command-target="submit">EXEC</button>
    </form>
  </div>`

describe('GridCommandController', () => {
  let application: Application

  const input = (): HTMLInputElement => document.querySelector('[data-grid-command-target="input"]')!
  const log = (): HTMLElement => document.querySelector('[data-grid-command-target="log"]')!
  const form = (): HTMLFormElement => document.querySelector('form')!

  function type (value: string): void {
    input().value = value
  }

  function submit (): Event {
    const event = new Event('submit', { bubbles: true, cancelable: true })
    form().dispatchEvent(event)
    return event
  }

  function key (k: string): void {
    input().dispatchEvent(new KeyboardEvent('keydown', { key: k, bubbles: true, cancelable: true }))
  }

  async function start (): Promise<void> {
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('grid-command', GridCommandController)
    await Promise.resolve()
  }

  beforeEach(() => {
    sessionStorage.clear()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    sessionStorage.clear()
  })

  it('echoes the command into the log with separator and prompt', async () => {
    await start()
    type('look')
    submit()

    expect(log().querySelector('.grid-echo-separator')).not.toBeNull()
    expect(log().querySelector('.grid-echo')!.textContent).toBe('> look')
  })

  it('routes the echo to a visible breach log', async () => {
    await start()
    const breach = document.getElementById('breach-log')!
    breach.hidden = false
    // jsdom has no layout: fake offsetParent so the controller sees it on-screen
    Object.defineProperty(breach, 'offsetParent', { value: document.body })

    type('hack node')
    submit()

    expect(breach.querySelector('.grid-echo')!.textContent).toBe('> hack node')
    expect(log().querySelector('.grid-echo')).toBeNull()
  })

  it('handles clear/cls/cl locally: wipes the log, keeps the round-trip from firing', async () => {
    await start()
    type('look')
    submit()
    expect(log().children.length).toBeGreaterThan(0)

    type('CLS')
    const event = submit()

    expect(event.defaultPrevented).toBe(true)
    expect(log().innerHTML).toBe('')
    expect(input().value).toBe('')
  })

  it('blocks empty submissions', async () => {
    await start()
    type('   ')
    const event = submit()

    expect(event.defaultPrevented).toBe(true)
    expect(log().children).toHaveLength(0)
  })

  it('persists history to sessionStorage with dedup-last and walks it with arrows', async () => {
    await start()
    type('north'); submit()
    type('scan'); submit()
    type('scan'); submit() // dedup: not stored twice

    expect(JSON.parse(sessionStorage.getItem(HISTORY_KEY)!)).toEqual(['north', 'scan'])

    type('dra') // draft in progress
    key('ArrowUp')
    expect(input().value).toBe('scan')
    key('ArrowUp')
    expect(input().value).toBe('north')
    key('ArrowUp') // clamps at oldest
    expect(input().value).toBe('north')
    key('ArrowDown')
    expect(input().value).toBe('scan')
    key('ArrowDown') // past newest → draft restored
    expect(input().value).toBe('dra')
  })

  it('restores persisted history on connect', async () => {
    sessionStorage.setItem(HISTORY_KEY, JSON.stringify(['warp 7']))
    await start()

    key('ArrowUp')
    expect(input().value).toBe('warp 7')
  })

  it('clears the input on success and appends an error line on failure', async () => {
    await start()
    // The real form carries turbo lifecycle actions; call the handlers
    // through a registered controller instance.
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="grid-command"]')!, 'grid-command'
    ) as GridCommandController & { started: () => void, submitted: (e: Event) => void }

    type('look')
    controller.started()
    expect(input().disabled).toBe(true)

    controller.submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
    expect(input().disabled).toBe(false)
    expect(input().value).toBe('')

    type('scan')
    controller.started()
    controller.submitted(new CustomEvent('turbo:submit-end', { detail: { success: false } }))
    expect(input().value).toBe('scan')
    expect(log().querySelector('.grid-error-line')!.textContent).toBe('Error: Network error. Please try again.')
  })
})
