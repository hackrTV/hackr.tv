import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PacketLogController from './packet_log_controller'

// Fixture mirrors uplink/_log_frame: #uplink-log with .packet children
// carrying the grouping attrs uplink/_packet emits (data-author-key,
// data-at, data-packet-owner-id-value). jsdom has no layout, so the
// scroll metrics are stubbed per example.

const T0 = 1_700_000_000_000

function packet (id: number, author: string, at: number, owner = 7): string {
  return `<div id="chat_message_${id}" class="packet" data-author-key="${author}" data-at="${at}" data-packet-owner-id-value="${owner}">p${id}</div>`
}

function fixture (packets: string[], group = true): string {
  return `
    <div id="uplink-log" data-controller="packet-log"${group ? ' data-packet-log-group-value="true"' : ''}>
      <div class="uplink-empty"><p>No packets yet.</p></div>
      ${packets.join('\n')}
    </div>`
}

describe('PacketLogController', () => {
  let application: Application
  let states: Array<{ atBottom: boolean, unread: number }>

  const log = (): HTMLElement => document.getElementById('uplink-log')!
  const cont = (id: number): boolean => document.getElementById(`chat_message_${id}`)!.classList.contains('packet--cont')

  function append (html: string): void {
    log().insertAdjacentHTML('beforeend', html)
  }

  async function flush (): Promise<void> {
    await Promise.resolve()
    await new Promise(resolve => setTimeout(resolve, 0))
  }

  function scrolledUp (): void {
    Object.defineProperty(log(), 'scrollHeight', { value: 1000, configurable: true })
    Object.defineProperty(log(), 'clientHeight', { value: 300, configurable: true })
    log().scrollTop = 0
    log().dispatchEvent(new Event('scroll'))
  }

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    states = []
    document.addEventListener('packet-log:state', (event) => {
      states.push((event as CustomEvent).detail)
    })
    application = Application.start()
    application.register('packet-log', PacketLogController)
    await Promise.resolve()
  }

  beforeEach(() => {
    vi.stubGlobal('ResizeObserver', class {
      observe (): void { /* jsdom stub */ }
      disconnect (): void { /* jsdom stub */ }
    })
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    document.head.querySelector('meta[name="current-hackr-id"]')?.remove()
    await Promise.resolve()
    application?.stop()
    vi.unstubAllGlobals()
  })

  it('groups consecutive packets by the same author within five minutes on connect', async () => {
    await start(fixture([
      packet(1, 'h1', T0),
      packet(2, 'h1', T0 + 60_000),
      packet(3, 'h2', T0 + 90_000),
      packet(4, 'h2', T0 + 90_000 + 5 * 60_000),
      packet(5, 'TTV:viewer', T0 + 11 * 60_000),
      packet(6, 'TTV:other', T0 + 11 * 60_000 + 1000)
    ]))

    expect(cont(1)).toBe(false) // first packet; previous sibling is the empty-state div
    expect(cont(2)).toBe(true)
    expect(cont(3)).toBe(false) // author changed
    expect(cont(4)).toBe(false) // exactly the window is outside it
    expect(cont(5)).toBe(false)
    expect(cont(6)).toBe(false) // bridged users differ by username, not platform
  })

  it('groups appended packets and regroups the follower after a replace', async () => {
    await start(fixture([packet(1, 'h1', T0)]))

    append(packet(2, 'h1', T0 + 1000))
    await flush()
    expect(cont(2)).toBe(true)

    // Drop/restore = Turbo replace: a different author swapped into slot 1
    // must un-group packet 2.
    document.getElementById('chat_message_1')!.outerHTML = packet(1, 'h9', T0)
    await flush()
    expect(cont(2)).toBe(false)
  })

  it('leaves grouping off without the group value', async () => {
    await start(fixture([packet(1, 'h1', T0), packet(2, 'h1', T0 + 1000)], false))

    expect(cont(2)).toBe(false)
    append(packet(3, 'h1', T0 + 2000))
    await flush()
    expect(cont(3)).toBe(false)
  })

  it('counts foreign packets that arrive while scrolled up and clears on return to bottom', async () => {
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    meta.content = '7'
    document.head.appendChild(meta)
    await start(fixture([packet(1, 'h1', T0)]))
    scrolledUp()
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 0 })

    append(packet(2, 'h2', T0 + 1000, 8)) // someone else
    append(packet(3, 'h1', T0 + 2000, 7)) // own packet: not unread
    await flush()
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 1 })

    Object.defineProperty(log(), 'scrollTop', { value: 700, configurable: true, writable: true })
    log().dispatchEvent(new Event('scroll'))
    expect(states.at(-1)).toEqual({ atBottom: true, unread: 0 })
  })

  it('does not count a replaced (dropped/restored) packet as new', async () => {
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    meta.content = '7'
    document.head.appendChild(meta)
    await start(fixture([packet(1, 'h2', T0, 8), packet(2, 'h2', T0 + 1000, 8)]))
    scrolledUp()

    document.getElementById('chat_message_1')!.outerHTML = packet(1, 'h2', T0, 8).replace('p1', '[PACKET DROPPED]')
    await flush()
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 0 })
    expect(cont(2)).toBe(true) // still grouped behind the replaced row
  })

  it('trims to the cap when one is set', async () => {
    document.body.innerHTML = `<div id="uplink-log" data-controller="packet-log" data-packet-log-cap-value="2">${packet(1, 'h1', T0)}${packet(2, 'h1', T0)}</div>`
    application = Application.start()
    application.register('packet-log', PacketLogController)
    await Promise.resolve()

    append(packet(3, 'h1', T0))
    await flush()
    expect(log().children.length).toBe(2)
    expect(document.getElementById('chat_message_1')).toBeNull()
  })
})
