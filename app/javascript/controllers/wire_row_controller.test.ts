import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WireRowController from './wire_row_controller'

// Fixture mirrors wire/_pulse_entry: a root row with its sibling thread
// frame (data-thread-frame), the hidden owner-only delete form, a
// datetime stamp; plus a thread row inside a loaded frame whose ↩ aims
// the thread's prompt at that pulse. Thread opens and author clicks are
// offered to a context pane first (wire-row:pane): a listener that
// cancels the event stands in for a claiming pane.

function root (id: number, owner: number, loaded = false): string {
  return `
    <div id="pulse_${id}_entry" class="wire-entry">
      <div id="pulse_${id}" class="wire-row" data-controller="wire-row" data-wire-row-owner-id-value="${owner}" data-pulse-id="${id}" data-thread-frame="pulse_${id}_thread"
           data-action="wire:open->wire-row#openThread wire:reply->wire-row#reply">
        <time class="wire-time" datetime="2026-10-26T14:03:00Z" data-wire-row-target="time">14:03</time>
        <a class="wire-author wire-author--operative" href="/wire/ghost" data-action="click->wire-row#author">@ghost</a>
        <a class="splice-button" href="/wire/pulse/${id}" data-turbo-frame="pulse_${id}_thread" data-action="click->wire-row#toggleThread" aria-expanded="false">↩</a>
        <form class="wire-inline-form" hidden data-wire-row-target="ownerOnly"><input type="hidden" name="authenticity_token" value="stale"><button class="delete-button">×</button></form>
      </div>
      <turbo-frame id="pulse_${id}_thread" class="wire-thread">${loaded ? thread(id) : ''}</turbo-frame>
    </div>`
}

function thread (rootId: number): string {
  return `
    <div id="pulse_${rootId}_thread_list">
      <div id="pulse_${rootId + 1}_entry" class="wire-entry">
        <div id="pulse_${rootId + 1}" class="wire-row" data-controller="wire-row" data-wire-row-owner-id-value="9" data-pulse-id="${rootId + 1}">
          <a class="wire-author wire-author--admin" href="/wire/xeraen">@xeraen</a>
          <button type="button" class="splice-button" data-action="click->wire-row#reply">↩</button>
        </div>
      </div>
    </div>
    <form class="wire-prompt"><input type="hidden" name="parent_pulse_id" value="${rootId}"><textarea class="wire-prompt-input" placeholder="Splice into @ghost's thread..." data-default-placeholder="Splice into @ghost's thread..."></textarea></form>`
}

describe('WireRowController', () => {
  let application: Application
  const metas: HTMLMetaElement[] = []
  let listeners = new AbortController()

  function meta (name: string, content: string): void {
    const m = document.createElement('meta')
    m.name = name
    m.content = content
    document.head.appendChild(m)
    metas.push(m)
  }

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('wire-row', WireRowController)
    await Promise.resolve()
  }

  beforeEach(() => {
    meta('csrf-token', 'fresh-token')
  })

  afterEach(() => {
    application?.stop()
    document.body.innerHTML = ''
    metas.splice(0).forEach(m => m.remove())
    listeners.abort()
    listeners = new AbortController()
  })

  const click = (el: Element, init: MouseEventInit = {}): MouseEvent => {
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, ...init })
    el.dispatchEvent(event)
    return event
  }

  it('reveals the delete form for the owner only and rewrites broadcast CSRF tokens', async () => {
    meta('current-hackr-id', '7')
    await start(root(1, 7) + root(2, 8))

    expect(document.querySelector<HTMLElement>('#pulse_1 form')!.hidden).toBe(false)
    expect(document.getElementById('pulse_1')!.classList.contains('wire-row--own')).toBe(true) // MUTT's F flag
    expect(document.querySelector<HTMLElement>('#pulse_2 form')!.hidden).toBe(true)
    expect(document.getElementById('pulse_2')!.classList.contains('wire-row--own')).toBe(false)
    expect(document.querySelector<HTMLInputElement>('#pulse_1 input[name="authenticity_token"]')!.value).toBe('fresh-token')
  })

  it('reveals nothing for a logged-out viewer', async () => {
    await start(root(1, 7))

    expect(document.querySelector<HTMLElement>('#pulse_1 form')!.hidden).toBe(true)
  })

  it('localizes the stamp and gives it a full-date title', async () => {
    await start(root(1, 7))
    const time = document.querySelector<HTMLTimeElement>('#pulse_1 .wire-time')!

    expect(time.textContent).toMatch(/^\d{2}:\d{2}$/)
    expect(time.title).toMatch(/^\d{4}-\d{2}-\d{2}/)
  })

  it('lets the first ↩ click through to Turbo (empty frame), then folds and unfolds a loaded frame', async () => {
    await start(root(1, 7))
    const link = document.querySelector<HTMLAnchorElement>('#pulse_1 .splice-button')!
    const frame = document.getElementById('pulse_1_thread') as HTMLElement

    const first = new MouseEvent('click', { bubbles: true, cancelable: true })
    link.dispatchEvent(first)
    expect(first.defaultPrevented).toBe(false)

    frame.innerHTML = thread(1)
    frame.dispatchEvent(new Event('turbo:frame-load', { bubbles: true }))
    await Promise.resolve()
    expect(link.getAttribute('aria-expanded')).toBe('true')

    const second = new MouseEvent('click', { bubbles: true, cancelable: true })
    link.dispatchEvent(second)
    expect(second.defaultPrevented).toBe(true)
    expect(frame.hidden).toBe(true)
    expect(link.getAttribute('aria-expanded')).toBe('false')

    link.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true }))
    expect(frame.hidden).toBe(false)
    expect(link.getAttribute('aria-expanded')).toBe('true')
  })

  it('syncs aria-expanded from the frame when the row reconnects (a drop replace)', async () => {
    await start(root(1, 7, true))

    expect(document.querySelector('#pulse_1 .splice-button')!.getAttribute('aria-expanded')).toBe('true')
  })

  it('wire:open clicks ↩ on an empty frame and folds a loaded one', async () => {
    await start(root(1, 7, true))
    const row = document.getElementById('pulse_1')!
    const frame = document.getElementById('pulse_1_thread') as HTMLElement

    row.dispatchEvent(new CustomEvent('wire:open'))
    expect(frame.hidden).toBe(true)
    row.dispatchEvent(new CustomEvent('wire:open'))
    expect(frame.hidden).toBe(false)

    document.body.innerHTML = root(3, 7)
    await Promise.resolve()
    const click = vi.fn()
    document.querySelector<HTMLAnchorElement>('#pulse_3 .splice-button')!.addEventListener('click', e => { e.preventDefault(); click() })
    document.getElementById('pulse_3')!.dispatchEvent(new CustomEvent('wire:open'))
    expect(click).toHaveBeenCalledTimes(1)
  })

  it('aims the thread prompt: a thread row at itself, the root row (wire:reply) back at the root', async () => {
    await start(root(1, 7, true))
    const parent = document.querySelector<HTMLInputElement>('input[name="parent_pulse_id"]')!
    const input = document.querySelector<HTMLTextAreaElement>('.wire-prompt-input')!

    document.querySelector<HTMLButtonElement>('#pulse_2 .splice-button')!.click()
    expect(parent.value).toBe('2')
    expect(input.placeholder).toBe('Reply to @xeraen...')
    expect(document.activeElement).toBe(input)

    input.blur()
    document.getElementById('pulse_1')!.dispatchEvent(new CustomEvent('wire:reply'))
    expect(parent.value).toBe('1')
    expect(input.placeholder).toBe('Splice into @ghost\'s thread...')
    expect(document.activeElement).toBe(input)
  })

  it('offers thread opens and plain author clicks to a claiming pane first, leaving the frame and the profile visit alone', async () => {
    await start(root(1, 7))
    const offers: unknown[] = []
    document.addEventListener('wire-row:pane', event => {
      offers.push((event as CustomEvent).detail)
      event.preventDefault()
    }, { signal: listeners.signal })
    const row = document.getElementById('pulse_1')!
    const frame = document.getElementById('pulse_1_thread') as HTMLElement

    expect(click(row.querySelector('.splice-button')!).defaultPrevented).toBe(true)
    row.dispatchEvent(new CustomEvent('wire:open'))
    row.dispatchEvent(new CustomEvent('wire:reply'))
    expect(offers).toEqual([
      { url: '/wire/pulse/1', select: '1', focus: false },
      { url: '/wire/pulse/1', select: '1', focus: false },
      { url: '/wire/pulse/1', select: '1', focus: true }
    ])
    expect(frame.innerHTML).toBe('')

    const author = row.querySelector('.wire-author')!
    expect(click(author).defaultPrevented).toBe(true)
    expect(offers[3]).toEqual({ url: '/wire/ghost' })
    expect(click(author, { metaKey: true }).defaultPrevented).toBe(false)
    expect(click(author, { button: 1 }).defaultPrevented).toBe(false)
    expect(offers).toHaveLength(4)
  })

  it('runs its own behavior when nobody claims the offer, and never offers a reply row\'s thread', async () => {
    await start(root(1, 7, true))
    const offers = vi.fn()
    document.addEventListener('wire-row:pane', offers, { signal: listeners.signal })
    const frame = document.getElementById('pulse_1_thread') as HTMLElement

    click(document.querySelector('#pulse_1 .splice-button')!)
    expect(frame.hidden).toBe(true) // folded, as without a pane
    expect(offers).toHaveBeenCalledTimes(1)

    document.getElementById('pulse_2')!.dispatchEvent(new CustomEvent('wire:open'))
    expect(offers).toHaveBeenCalledTimes(1)
    expect(click(document.querySelector('#pulse_1 .wire-author')!).defaultPrevented).toBe(false)
    expect(offers).toHaveBeenCalledTimes(2)
  })
})
