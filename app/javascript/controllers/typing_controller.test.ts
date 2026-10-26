import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import TypingController, { typingLabel } from './typing_controller'

// Fixture mirrors uplink/_typing: the strip carries the composing
// hackrs' aliases as a JSON array; the text is this controller's.

function line (aliases: string[], ttl = 5000): string {
  const json = JSON.stringify(aliases).replace(/"/g, '&quot;')
  return `<div id="uplink-typing" class="uplink-typing" data-controller="typing" data-typing-aliases-value="${json}" data-typing-ttl-value="${ttl}"></div>`
}

describe('typingLabel', () => {
  it('names one, two or three aliases and counts beyond', () => {
    expect(typingLabel([])).toBe('')
    expect(typingLabel(['xeraen'])).toBe('@xeraen is transmitting...')
    expect(typingLabel(['xeraen', 'ghost_op'])).toBe('@xeraen and @ghost_op are transmitting...')
    expect(typingLabel(['a', 'b', 'c'])).toBe('@a, @b and @c are transmitting...')
    expect(typingLabel(['a', 'b', 'c', 'd'])).toBe('4 operatives are transmitting...')
  })
})

describe('TypingController', () => {
  let application: Application
  const metas: HTMLMetaElement[] = []

  function meta (name: string, content: string): void {
    const m = document.createElement('meta')
    m.name = name
    m.content = content
    document.head.appendChild(m)
    metas.push(m)
  }

  const strip = (): HTMLElement => document.getElementById('uplink-typing')!

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('typing', TypingController)
    await Promise.resolve()
  }

  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    metas.splice(0).forEach(m => m.remove())
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
  })

  it('renders the others, never the viewer (alias compared case-insensitively), and clears after the ttl', async () => {
    meta('current-hackr-alias', 'XERAEN')
    await start(line(['xeraen', 'ghost_op']))

    expect(strip().textContent).toBe('@ghost_op is transmitting...')
    expect(strip().classList.contains('uplink-typing--active')).toBe(true)

    vi.advanceTimersByTime(4999)
    expect(strip().textContent).toBe('@ghost_op is transmitting...')
    vi.advanceTimersByTime(1)
    expect(strip().textContent).toBe('')
    expect(strip().classList.contains('uplink-typing--active')).toBe(false)
  })

  it('stays blank when only the viewer is composing, or nobody is', async () => {
    meta('current-hackr-alias', 'xeraen')
    await start(line(['xeraen']))
    expect(strip().textContent).toBe('')
    expect(strip().classList.contains('uplink-typing--active')).toBe(false)

    application.stop()
    await start(line([]))
    expect(strip().textContent).toBe('')
  })

  it('re-renders from a Turbo Stream replace and re-arms the clear', async () => {
    meta('current-hackr-alias', 'xeraen')
    await start(line(['ghost_op']))
    vi.advanceTimersByTime(4000)

    const fresh = document.createElement('template')
    fresh.innerHTML = line(['ghost_op', 'node_op'])
    strip().replaceWith(fresh.content.firstElementChild!)
    await Promise.resolve()
    await Promise.resolve()

    expect(strip().textContent).toBe('@ghost_op and @node_op are transmitting...')
    vi.advanceTimersByTime(4000) // the old element's timer died with it
    expect(strip().textContent).toBe('@ghost_op and @node_op are transmitting...')
    vi.advanceTimersByTime(1000)
    expect(strip().textContent).toBe('')
  })
})
