import { describe, it, expect, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WireKeysController from './wire_keys_controller'

function row (id: number, opts: { own?: boolean, dropped?: boolean } = {}): string {
  return `
    <div id="pulse_${id}" class="wire-row${opts.dropped ? ' wire-row--dropped' : ''}" data-pulse-id="${id}">
      <a class="wire-author" href="/wire/ghost">@ghost</a>
      <p class="wire-text">pulse ${id}</p>
      <button class="echo-button">↻</button>
      <a class="splice-button" href="/wire/pulse/${id}">↩</a>
      <form class="wire-inline-form"${opts.own ? '' : ' hidden'}><button type="button" class="delete-button">×</button></form>
    </div>`
}

const page = (rows: string, pane = '', view = ''): string => `
  <div class="wire-page"${view ? ` data-view="${view}"` : ''} data-controller="wire-keys" data-action="keydown@document->wire-keys#key click->wire-keys#click">
    <form><textarea class="wire-prompt-input"></textarea></form>
    <div id="wire-feed">${rows}</div>
    <aside class="wire-pane"><turbo-frame id="wire-pane">${pane}</turbo-frame></aside>
    <div class="wire-legend" hidden data-wire-keys-target="legend">keys</div>
  </div>`

describe('WireKeysController', () => {
  let application: Application

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('wire-keys', WireKeysController)
    await Promise.resolve()
    Element.prototype.scrollIntoView = vi.fn()
  }

  function press (key: string, target: Element = document.body): void {
    target.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, cancelable: true }))
  }

  const cursor = (): string | undefined => document.querySelector('.wire-row--cursor')?.id

  afterEach(() => {
    application?.stop()
    document.body.innerHTML = ''
    vi.useRealTimers()
  })

  it('moves the cursor with j/k, clamps at the ends, jumps with g/G, skips dropped rows', async () => {
    await start(page(row(1) + row(2, { dropped: true }) + row(3)))

    press('j')
    expect(cursor()).toBe('pulse_1')
    press('j')
    expect(cursor()).toBe('pulse_3')
    press('j')
    expect(cursor()).toBe('pulse_3')
    press('k')
    expect(cursor()).toBe('pulse_1')
    press('k')
    expect(cursor()).toBe('pulse_1')
    press('G')
    expect(cursor()).toBe('pulse_3')
    press('g')
    expect(cursor()).toBe('pulse_1')
  })

  it('keeps the cursor by id when the row is replaced (a drop broadcast)', async () => {
    await start(page(row(1) + row(2)))
    press('j')
    press('j')

    const fresh = document.createElement('div')
    fresh.id = 'pulse_2'
    fresh.className = 'wire-row'
    document.getElementById('pulse_2')!.replaceWith(fresh)
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(cursor()).toBe('pulse_2')
    press('k')
    expect(cursor()).toBe('pulse_1')
  })

  it('e echoes, o and r dispatch wire:open / wire:reply on the cursor row', async () => {
    await start(page(row(1)))
    const echo = vi.fn()
    const opened = vi.fn()
    const replied = vi.fn()
    document.querySelector('.echo-button')!.addEventListener('click', echo)
    document.getElementById('pulse_1')!.addEventListener('wire:open', opened)
    document.getElementById('pulse_1')!.addEventListener('wire:reply', replied)

    press('e')
    expect(echo).not.toHaveBeenCalled() // no cursor yet
    press('j')
    press('e')
    press('o')
    const reply = new KeyboardEvent('keydown', { key: 'r', bubbles: true, cancelable: true })
    document.body.dispatchEvent(reply)
    expect(echo).toHaveBeenCalledTimes(1)
    expect(opened).toHaveBeenCalledTimes(1)
    expect(replied).toHaveBeenCalledTimes(1)
    expect(reply.defaultPrevented).toBe(true) // the prompt it focuses must not receive the "r"
  })

  it('x arms the owner\'s row and deletes on the second press; disarms after 1.5s or on another key', async () => {
    vi.useFakeTimers()
    await start(page(row(1, { own: true }) + row(2)))
    const del = vi.fn()
    document.querySelector('#pulse_1 .delete-button')!.addEventListener('click', del)

    press('j')
    press('x')
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--armed')).toBe(true)
    vi.advanceTimersByTime(1600)
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--armed')).toBe(false)
    expect(del).not.toHaveBeenCalled()

    press('x')
    press('k')
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--armed')).toBe(false)

    press('x')
    press('x')
    expect(del).toHaveBeenCalledTimes(1)

    press('j')
    press('x')
    press('x')
    expect(document.getElementById('pulse_2')!.classList.contains('wire-row--armed')).toBe(false) // not the owner
  })

  it('clears snapshot leftovers on connect (a Turbo cache restore)', async () => {
    await start(page(row(1) + row(2)).replace('class="wire-row"', 'class="wire-row wire-row--cursor wire-row--armed"').replace('class="wire-legend" hidden', 'class="wire-legend"'))

    expect(document.querySelector('.wire-row--cursor, .wire-row--armed')).toBeNull()
    expect(document.querySelector<HTMLElement>('.wire-legend')!.hidden).toBe(true)
  })

  it('ignores keys while typing and with modifiers; / focuses the prompt; ? and Escape toggle the legend', async () => {
    await start(page(row(1)))
    const input = document.querySelector<HTMLTextAreaElement>('.wire-prompt-input')!
    const legend = document.querySelector<HTMLElement>('.wire-legend')!

    press('j', input)
    expect(cursor()).toBeUndefined()
    document.body.dispatchEvent(new KeyboardEvent('keydown', { key: 'j', ctrlKey: true, bubbles: true }))
    expect(cursor()).toBeUndefined()

    const slash = new KeyboardEvent('keydown', { key: '/', bubbles: true, cancelable: true })
    document.body.dispatchEvent(slash)
    expect(slash.defaultPrevented).toBe(true)
    expect(document.activeElement).toBe(input)
    input.blur()

    press('?')
    expect(legend.hidden).toBe(false)
    press('j')
    press('Escape')
    expect(legend.hidden).toBe(true)
    expect(cursor()).toBeUndefined()
  })

  it('announces cursor moves (wire:cursor), c asks for the pane (wire-keys:pane), a clicks the author link, and pane rows are never walked', async () => {
    await start(page(row(1) + row(2), row(9)))
    const pageEl = document.querySelector<HTMLElement>('.wire-page')!
    const moved = vi.fn()
    const pane = vi.fn()
    const author = vi.fn()
    pageEl.addEventListener('wire:cursor', moved)
    pageEl.addEventListener('wire-keys:pane', pane)
    document.querySelector('#pulse_1 .wire-author')!.addEventListener('click', e => { e.preventDefault(); author() })

    press('j')
    expect(moved).toHaveBeenCalledTimes(1)
    expect((moved.mock.calls[0]![0] as Event).target).toBe(document.getElementById('pulse_1'))
    press('Escape')
    expect(moved).toHaveBeenCalledTimes(2) // the cleared cursor, announced from the page
    expect((moved.mock.calls[1]![0] as Event).target).toBe(pageEl)
    press('j')
    press('a')
    expect(author).toHaveBeenCalledTimes(1)
    press('c')
    expect(pane).toHaveBeenCalledTimes(1)

    press('G')
    expect(cursor()).toBe('pulse_2')
    press('j')
    expect(cursor()).toBe('pulse_2')
  })

  it('v asks for the view switch (wire-keys:view); Enter opens the cursor row only with nothing focused', async () => {
    await start(page(row(1)))
    const pageEl = document.querySelector<HTMLElement>('.wire-page')!
    const view = vi.fn()
    const opened = vi.fn()
    pageEl.addEventListener('wire-keys:view', view)
    document.getElementById('pulse_1')!.addEventListener('wire:open', opened)

    press('v')
    expect(view).toHaveBeenCalledTimes(1)

    press('j')
    press('Enter', document.querySelector('.echo-button')!)
    expect(opened).not.toHaveBeenCalled()
    press('Enter')
    expect(opened).toHaveBeenCalledTimes(1)
  })

  it('a plain click on a row\'s own surface makes it the cursor; links, buttons, modified clicks, pane rows and a text selection are left alone', async () => {
    await start(page(row(1, { own: true }) + row(2), row(9)))
    const moved = vi.fn()
    document.querySelector('.wire-page')!.addEventListener('wire:cursor', moved)
    document.querySelector('#pulse_1 .wire-author')!.addEventListener('click', e => e.preventDefault())
    const click = (el: Element, init: MouseEventInit = {}): void => {
      el.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, button: 0, ...init }))
    }

    click(document.querySelector('#pulse_2 .wire-text')!)
    expect(cursor()).toBe('pulse_2')
    expect(moved).toHaveBeenCalledTimes(1)
    expect((moved.mock.calls[0]![0] as Event).target).toBe(document.getElementById('pulse_2'))

    click(document.querySelector('#pulse_1 .wire-author')!)
    click(document.querySelector('#pulse_1 .echo-button')!)
    click(document.querySelector('#pulse_1 .wire-text')!, { shiftKey: true })
    click(document.querySelector('#pulse_1 .wire-text')!, { button: 1 })
    click(document.querySelector('#pulse_9 .wire-text')!)
    expect(cursor()).toBe('pulse_2')

    const range = document.createRange()
    range.selectNodeContents(document.querySelector('#pulse_1 .wire-text')!)
    document.getSelection()!.addRange(range)
    click(document.querySelector('#pulse_1 .wire-text')!)
    expect(cursor()).toBe('pulse_2')
    document.getSelection()!.removeAllRanges()

    press('k') // onto pulse_1, then arm it
    press('x')
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--armed')).toBe(true)
    click(document.querySelector('#pulse_2 .wire-text')!) // a click elsewhere disarms like any other key
    expect(cursor()).toBe('pulse_2')
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--armed')).toBe(false)
    expect(moved).toHaveBeenCalledTimes(3)
  })

  it('opens MUTT mode with the cursor on the first row, a tick after connect', async () => {
    vi.useFakeTimers()
    await start(page(row(1) + row(2), '', 'mutt'))
    const moved = vi.fn()
    document.querySelector('.wire-page')!.addEventListener('wire:cursor', moved)
    expect(cursor()).toBeUndefined()

    vi.advanceTimersByTime(1)
    expect(cursor()).toBe('pulse_1')
    expect(moved).toHaveBeenCalledTimes(1)
  })
})
