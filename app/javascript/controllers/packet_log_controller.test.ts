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

  it('never collapses a reply (data-reply-to) under the previous packet, but groups its follower', async () => {
    await start(fixture([
      packet(1, 'h1', T0),
      packet(2, 'h1', T0 + 1000).replace('class="packet"', 'class="packet" data-reply-to="1"'),
      packet(3, 'h1', T0 + 2000)
    ]))
    expect(cont(1)).toBe(false)
    expect(cont(2)).toBe(false) // the quote line needs the author line above it
    expect(cont(3)).toBe(true)

    append(packet(4, 'h1', T0 + 3000).replace('class="packet"', 'class="packet" data-reply-to="3"'))
    await flush()
    expect(cont(4)).toBe(false)
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
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 0, mentions: 0 })

    append(packet(2, 'h2', T0 + 1000, 8)) // someone else
    append(packet(3, 'h1', T0 + 2000, 7)) // own packet: not unread
    await flush()
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 1, mentions: 0 })

    Object.defineProperty(log(), 'scrollTop', { value: 700, configurable: true, writable: true })
    log().dispatchEvent(new Event('scroll'))
    expect(states.at(-1)).toEqual({ atBottom: true, unread: 0, mentions: 0 })
  })

  it('counts unread packets that @mention the viewer (case-insensitive, never own packets) and clears with unread', async () => {
    const id = document.createElement('meta')
    id.name = 'current-hackr-id'
    id.content = '7'
    const alias = document.createElement('meta')
    alias.name = 'current-hackr-alias'
    alias.content = 'XERAEN'
    document.head.append(id, alias)
    await start(fixture([packet(1, 'h1', T0)]))
    scrolledUp()

    const mention = (idn: number, owner: number, who: string): string =>
      packet(idn, `h${owner}`, T0 + idn * 1000, owner).replace(`p${idn}`, `<a class="uplink-mention" data-alias="${who}">@${who}</a>`)
    append(mention(2, 8, 'xeraen')) // someone else, mentions me
    append(mention(3, 8, 'other')) // someone else, mentions someone else
    append(mention(4, 7, 'XERAEN')) // my own packet: neither unread nor a mention
    await flush()
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 2, mentions: 1 })

    Object.defineProperty(log(), 'scrollTop', { value: 700, configurable: true, writable: true })
    log().dispatchEvent(new Event('scroll'))
    expect(states.at(-1)).toEqual({ atBottom: true, unread: 0, mentions: 0 })
    document.head.querySelector('meta[name="current-hackr-alias"]')?.remove()
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
    expect(states.at(-1)).toEqual({ atBottom: false, unread: 0, mentions: 0 })
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
  describe('scrollback', () => {
    let intersect: (() => void) | null
    let observe: ReturnType<typeof vi.fn>
    let unobserve: ReturnType<typeof vi.fn>
    let fetchMock: ReturnType<typeof vi.fn>

    const sentinel = (): HTMLElement => document.querySelector('.uplink-log-top')!
    const ids = (): string[] => Array.from(log().querySelectorAll('.packet'), node => node.id)

    function shellFixture (packets: string[], more = 'true'): string {
      return `
        <div id="uplink-log" data-controller="packet-log" data-packet-log-group-value="true">
          <div class="uplink-empty"><p>No packets yet.</p></div>
          <div class="uplink-log-top" data-packet-log-target="top" data-more="${more}" data-src="/uplink/log?channel=ambient"></div>
          ${packets.join('\n')}
        </div>`
    }

    function respond (html: string): void {
      fetchMock.mockResolvedValue({ ok: true, text: async () => html })
    }

    async function settle (): Promise<void> {
      for (let i = 0; i < 4; i++) await flush()
    }

    // jsdom has no layout: the log is 100px per packet, scrollTop is a
    // plain stored number, so the anchoring math is observable.
    function layout (): void {
      Object.defineProperty(log(), 'scrollHeight', { configurable: true, get: () => log().querySelectorAll('.packet').length * 100 })
      Object.defineProperty(log(), 'clientHeight', { value: 100, configurable: true })
      Object.defineProperty(log(), 'scrollTop', { value: 0, configurable: true, writable: true })
    }

    // Reading history: the viewer is at the top, so the log is not pinned.
    function scrollToTop (): void {
      log().scrollTop = 0
      log().dispatchEvent(new Event('scroll'))
    }

    beforeEach(() => {
      intersect = null
      observe = vi.fn()
      unobserve = vi.fn()
      fetchMock = vi.fn()
      vi.stubGlobal('fetch', fetchMock)
      vi.stubGlobal('IntersectionObserver', class {
        constructor (callback: IntersectionObserverCallback) {
          intersect = () => callback([{ isIntersecting: true } as IntersectionObserverEntry], this as unknown as IntersectionObserver)
        }

        observe = observe
        unobserve = unobserve
        disconnect (): void { /* jsdom stub */ }
      })
    })

    it('fetches the page before the first packet, splices it after the sentinel, anchors the viewport and regroups the boundary', async () => {
      await start(shellFixture([packet(41, 'h1', T0 + 1000), packet(42, 'h1', T0 + 2000)]))
      layout()
      scrollToTop()
      expect(observe).toHaveBeenCalledWith(sentinel())
      respond(packet(39, 'h2', T0 - 1000) + packet(40, 'h1', T0))

      intersect!()
      await settle()

      expect(fetchMock).toHaveBeenCalledTimes(1)
      expect(String(fetchMock.mock.calls[0][0])).toContain('/uplink/log?channel=ambient&before=41')
      expect(ids()).toEqual(['chat_message_39', 'chat_message_40', 'chat_message_41', 'chat_message_42'])
      expect(sentinel().nextElementSibling!.id).toBe('chat_message_39')
      expect(log().scrollTop).toBe(200) // two packets of height landed above the viewport; no re-pin
      expect(cont(40)).toBe(false) // author changed from 39
      expect(cont(41)).toBe(true) // old first packet now continues 40
      expect(sentinel().dataset.more).toBe('true')
      expect(sentinel().dataset.loading).toBeUndefined()
      expect(unobserve).toHaveBeenCalledTimes(1) // re-observed: a short page may leave it in view
      expect(observe).toHaveBeenCalledTimes(2)
    })

    it('reads the end marker: beginning of channel, no further fetches', async () => {
      await start(shellFixture([packet(2, 'h1', T0)]))
      layout()
      respond(packet(1, 'h1', T0 - 1000) + '<template data-log-end></template>')

      intersect!()
      await settle()
      expect(ids()).toEqual(['chat_message_1', 'chat_message_2'])
      expect(sentinel().dataset.more).toBe('false')
      expect(log().querySelector('template[data-log-end]')).toBeNull()
      expect(observe).toHaveBeenCalledTimes(1) // nothing left to watch for

      intersect!()
      await settle()
      expect(fetchMock).toHaveBeenCalledTimes(1)
    })

    it('fetches one page at a time', async () => {
      await start(shellFixture([packet(5, 'h1', T0)]))
      layout()
      let release: (value: { ok: boolean, text: () => Promise<string> }) => void = () => {}
      fetchMock.mockReturnValue(new Promise(resolve => { release = resolve }))

      intersect!()
      intersect!()
      await flush()
      expect(fetchMock).toHaveBeenCalledTimes(1)
      expect(sentinel().dataset.loading).toBe('true')

      release({ ok: true, text: async () => packet(4, 'h1', T0 - 1000) })
      await settle()
      expect(ids()).toEqual(['chat_message_4', 'chat_message_5'])
      expect(sentinel().dataset.loading).toBeUndefined()
    })

    it('never counts spliced history as unread and leaves data-more alone on a failed page', async () => {
      const meta = document.createElement('meta')
      meta.name = 'current-hackr-id'
      meta.content = '7'
      document.head.appendChild(meta)
      await start(shellFixture([packet(3, 'h2', T0, 8)]))
      layout()
      scrolledUp()
      respond(packet(1, 'h2', T0 - 2000, 8) + packet(2, 'h2', T0 - 1000, 8))

      intersect!()
      await settle()
      expect(ids()).toEqual(['chat_message_1', 'chat_message_2', 'chat_message_3'])
      expect(states.at(-1)).toEqual({ atBottom: false, unread: 0, mentions: 0 })

      fetchMock.mockResolvedValue({ ok: false, text: async () => '' })
      intersect!()
      await settle()
      expect(ids().length).toBe(3)
      expect(sentinel().dataset.more).toBe('true') // retried next time it scrolls into view
      expect(sentinel().dataset.loading).toBeUndefined()
    })

    it('does nothing when the sentinel says there is no history', async () => {
      await start(shellFixture([packet(1, 'h1', T0)], 'false'))
      layout()

      intersect!()
      await settle()
      expect(fetchMock).not.toHaveBeenCalled()
    })

    it('is inert without a sentinel (dock, popout, grid log)', async () => {
      await start(fixture([packet(1, 'h1', T0)]))

      expect(observe).not.toHaveBeenCalled()
      expect(fetchMock).not.toHaveBeenCalled()
    })
  })
})
