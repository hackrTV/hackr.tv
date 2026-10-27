import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PacketController from './packet_controller'

// Fixture mirrors uplink/_packet rows: a parent and a reply carrying
// data-reply-to + the quote line, each with the hover reply control and
// the four hidden per-viewer controls (drop / restore / pin forms, the […]
// packet-menu button) the controller reveals from the current-hackr
// metas + the author's role value ("bridge" on bridged/bot packets).

function packet (id: number, opts: { replyTo?: number, sender?: string, owner?: number, role?: string, dropped?: boolean } = {}): string {
  return `
    <div id="chat_message_${id}" class="packet${opts.dropped ? ' packet--dropped' : ''}" data-controller="packet" data-packet-owner-id-value="${opts.owner ?? 7}" data-packet-author-role-value="${opts.role ?? 'operative'}"${opts.replyTo ? ` data-reply-to="${opts.replyTo}"` : ''}>
      ${opts.replyTo ? '<button type="button" class="packet-reply-quote" data-action="click->packet#jumpToParent">[&gt;]</button>' : ''}
      <span class="packet-content">p${id}</span>
      <button type="button" class="packet-reply-button" data-action="click->packet#reply" data-reply-sender="${opts.sender ?? '@someone'}">↩</button>
      <form class="uplink-inline-form" hidden data-packet-target="dropControl"><button>×</button></form>
      <form class="uplink-inline-form" hidden data-packet-target="restoreControl"><button>↺</button></form>
      <form class="uplink-inline-form uplink-pin-form" hidden data-packet-target="pinControl"><button>◆</button></form>
      <button type="button" class="packet-mod-button" hidden data-packet-target="modControl">…</button>
    </div>`
}

describe('PacketController', () => {
  let application: Application

  const el = (id: number): HTMLElement => document.getElementById(`chat_message_${id}`)!
  const metas: HTMLMetaElement[] = []

  function meta (name: string, content: string): void {
    const m = document.createElement('meta')
    m.name = name
    m.content = content
    document.head.appendChild(m)
    metas.push(m)
  }

  // The viewer: hackr 1; packets by 7 (operative), 8 (operator), 9 (admin),
  // their own (live, then dropped) and a bridged one (50, role "bridge").
  async function start (html = `${packet(1, { sender: '@xeraen' })}${packet(2, { replyTo: 1 })}${packet(3, { replyTo: 999 })}`): Promise<void> {
    document.body.innerHTML = `<div id="uplink-log">${html}</div>`
    application = Application.start()
    application.register('packet', PacketController)
    await Promise.resolve()
  }

  const ROSTER = `${packet(1, { owner: 7, role: 'operative' })}${packet(2, { owner: 8, role: 'operator' })}${packet(3, { owner: 9, role: 'admin' })}${packet(4, { owner: 1, role: 'operator' })}${packet(5, { owner: 1, role: 'operator', dropped: true })}${packet(6, { owner: 50, role: 'bridge' })}`

  function revealed (id: number, control: 'dropControl' | 'restoreControl' | 'pinControl' | 'modControl'): boolean {
    return !el(id).querySelector<HTMLElement>(`[data-packet-target="${control}"]`)!.hidden
  }

  beforeEach(async () => {
    vi.useFakeTimers()
    await start()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    metas.splice(0).forEach(m => m.remove())
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
  })

  it('reveals nothing to a logged-out viewer; to an operative only the own drop control and the packet menu on their own live packet — never pin, never a dropped own packet', async () => {
    expect(revealed(1, 'dropControl')).toBe(false)
    expect(revealed(1, 'pinControl')).toBe(false)
    expect(revealed(1, 'modControl')).toBe(false)

    application.stop()
    meta('current-hackr-id', '1')
    meta('current-hackr-role', 'operative')
    await start(ROSTER)

    expect([1, 2, 3, 6].map(id => revealed(id, 'dropControl'))).toEqual([false, false, false, false])
    expect(revealed(4, 'dropControl')).toBe(true) // own packet (the dock/popout's control; the shell hides it)
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'restoreControl'))).toEqual([false, false, false, false, false, false])
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'pinControl'))).toEqual([false, false, false, false, false, false])
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'modControl'))).toEqual([false, false, false, true, false, false])
  })

  it('reveals drop + restore + pin everywhere to an operator (pinning is curation: their own packet too), and the packet menu on their own packets (dropped included: they can restore), on operatives they outrank and on bridged packets — never on peers or admins', async () => {
    application.stop()
    meta('current-hackr-id', '1')
    meta('current-hackr-role', 'operator')
    await start(ROSTER)

    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'dropControl'))).toEqual([true, true, true, true, true, true])
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'restoreControl'))).toEqual([true, true, true, true, true, true])
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'pinControl'))).toEqual([true, true, true, true, true, true])
    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'modControl'))).toEqual([true, false, false, true, true, true])
  })

  it('reveals the packet menu to an admin on operators, operatives, bridged packets and their own — not on other admins', async () => {
    application.stop()
    meta('current-hackr-id', '1')
    meta('current-hackr-role', 'admin')
    await start(ROSTER)

    expect([1, 2, 3, 4, 5, 6].map(id => revealed(id, 'modControl'))).toEqual([true, true, false, true, true, true])
  })

  it('dispatches packet:reply with the packet id and sender label from the hover control', () => {
    const seen: Array<{ id: string, sender: string }> = []
    document.addEventListener('packet:reply', event => seen.push((event as CustomEvent).detail))

    el(1).querySelector<HTMLButtonElement>('.packet-reply-button')!.click()
    el(2).querySelector<HTMLButtonElement>('.packet-reply-button')!.click()

    expect(seen).toEqual([{ id: '1', sender: '@xeraen' }, { id: '2', sender: '@someone' }])
  })

  it('jumps to the parent from the quote line: scrolls it into view and flashes it; no-op when it is not in the log', () => {
    const scrollIntoView = vi.fn()
    Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', { value: scrollIntoView, configurable: true })

    el(2).querySelector<HTMLButtonElement>('.packet-reply-quote')!.click()
    expect(scrollIntoView).toHaveBeenCalledWith({ block: 'center' })
    expect(scrollIntoView.mock.instances[0]).toBe(el(1))
    expect(el(1).classList.contains('packet--flash')).toBe(true)

    vi.advanceTimersByTime(1200)
    expect(el(1).classList.contains('packet--flash')).toBe(false)

    el(3).querySelector<HTMLButtonElement>('.packet-reply-quote')!.click() // parent above the loaded history
    expect(scrollIntoView).toHaveBeenCalledTimes(1)
    expect(document.querySelector('.packet--flash')).toBeNull()
  })
})
