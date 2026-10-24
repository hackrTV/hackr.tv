import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PacketController from './packet_controller'

// Fixture mirrors two uplink/_packet rows: a parent and a reply carrying
// data-reply-to + the quote line, each with the hover reply control.

function packet (id: number, opts: { replyTo?: number, sender?: string } = {}): string {
  return `
    <div id="chat_message_${id}" class="packet" data-controller="packet" data-packet-owner-id-value="7"${opts.replyTo ? ` data-reply-to="${opts.replyTo}"` : ''}>
      ${opts.replyTo ? '<button type="button" class="packet-reply-quote" data-action="click->packet#jumpToParent">[&gt;]</button>' : ''}
      <span class="packet-content">p${id}</span>
      <button type="button" class="packet-reply-button" data-action="click->packet#reply" data-reply-sender="${opts.sender ?? '@someone'}">↩</button>
    </div>`
}

describe('PacketController', () => {
  let application: Application

  const el = (id: number): HTMLElement => document.getElementById(`chat_message_${id}`)!

  beforeEach(async () => {
    vi.useFakeTimers()
    document.body.innerHTML = `<div id="uplink-log">${packet(1, { sender: '@xeraen' })}${packet(2, { replyTo: 1 })}${packet(3, { replyTo: 999 })}</div>`
    application = Application.start()
    application.register('packet', PacketController)
    await Promise.resolve()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
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
