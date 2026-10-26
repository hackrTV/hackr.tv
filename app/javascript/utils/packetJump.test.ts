import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { jumpToPacket } from './packetJump'

describe('jumpToPacket', () => {
  const scrollIntoView = vi.fn()

  beforeEach(() => {
    vi.useFakeTimers()
    document.body.innerHTML = '<div id="uplink-log"><div id="chat_message_7" class="packet"></div></div>'
    Object.defineProperty(HTMLElement.prototype, 'scrollIntoView', { value: scrollIntoView, configurable: true })
  })

  afterEach(() => {
    scrollIntoView.mockClear()
    document.body.innerHTML = ''
    vi.useRealTimers()
  })

  it('scrolls the packet into view, flashes it for 1.2s and reports the hit — from a string or a number id', () => {
    const packet = document.getElementById('chat_message_7')!

    expect(jumpToPacket('7')).toBe(true)
    expect(scrollIntoView).toHaveBeenCalledWith({ block: 'center' })
    expect(scrollIntoView.mock.instances[0]).toBe(packet)
    expect(packet.classList.contains('packet--flash')).toBe(true)

    vi.advanceTimersByTime(1200)
    expect(packet.classList.contains('packet--flash')).toBe(false)

    expect(jumpToPacket(7)).toBe(true)
    expect(scrollIntoView).toHaveBeenCalledTimes(2)
  })

  it('flashes for as long as the caller asks (a located log lingers on its focus)', () => {
    const packet = document.getElementById('chat_message_7')!

    expect(jumpToPacket(7, 2400)).toBe(true)
    vi.advanceTimersByTime(1200)
    expect(packet.classList.contains('packet--flash')).toBe(true)
    vi.advanceTimersByTime(1200)
    expect(packet.classList.contains('packet--flash')).toBe(false)
  })

  it('does nothing for a packet that is not in the log, or for anything that is not an id', () => {
    expect(jumpToPacket('999')).toBe(false)
    expect(jumpToPacket('7abc')).toBe(false)
    expect(jumpToPacket('')).toBe(false)
    expect(jumpToPacket(null)).toBe(false)
    expect(jumpToPacket(undefined)).toBe(false)
    expect(scrollIntoView).not.toHaveBeenCalled()
    expect(document.querySelector('.packet--flash')).toBeNull()
  })
})
