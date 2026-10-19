import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import UplinkDockController from './uplink_dock_controller'

// The popout window (popout_heartbeat controller) stamps
// localStorage['uplink_popout_heartbeat'] every 500ms and removes it on
// close; other windows see those writes as storage events. Fake timers
// drive Date.now() and the controller's poll.

const KEY = 'uplink_popout_heartbeat'
const FIXTURE = `
  <div class="live-embed" data-controller="uplink-dock">
    <div class="live-side-panel live-side-panel--uplink"></div>
  </div>`

describe('UplinkDockController', () => {
  let application: Application

  const embed = (): HTMLElement => document.querySelector('.live-embed')!
  const popped = (): boolean => embed().classList.contains('uplink-popped')
  const stamp = (): void => { localStorage.setItem(KEY, String(Date.now())) }
  const unstamp = (): void => { localStorage.removeItem(KEY) }
  const storageEvent = (newValue: string | null): void => {
    window.dispatchEvent(new StorageEvent('storage', { key: KEY, newValue }))
  }

  async function start (): Promise<void> {
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('uplink-dock', UplinkDockController)
    await Promise.resolve()
  }

  beforeEach(() => {
    vi.useFakeTimers()
    localStorage.removeItem(KEY)
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
    localStorage.removeItem(KEY)
  })

  it('leaves the dock in place when no popout heartbeat is stored', async () => {
    await start()
    expect(popped()).toBe(false)
  })

  it('hides the dock on connect when a fresh heartbeat is already stored', async () => {
    stamp()
    await start()
    expect(popped()).toBe(true)
  })

  it('ignores a stale stored heartbeat on connect', async () => {
    stamp()
    vi.advanceTimersByTime(5000)
    await start()
    expect(popped()).toBe(false)
  })

  it('hides the dock when the popout starts stamping', async () => {
    await start()
    stamp()
    storageEvent(localStorage.getItem(KEY))
    expect(popped()).toBe(true)
  })

  it('stays hidden while the popout keeps stamping', async () => {
    stamp()
    await start()
    for (let i = 0; i < 6; i++) {
      vi.advanceTimersByTime(500)
      stamp()
      storageEvent(localStorage.getItem(KEY))
    }
    vi.advanceTimersByTime(500)
    expect(popped()).toBe(true)
  })

  it('restores the dock shortly after the popout removes its stamp', async () => {
    stamp()
    await start()
    expect(popped()).toBe(true)

    unstamp()
    storageEvent(null)
    expect(popped()).toBe(true) // grace: not yet

    vi.advanceTimersByTime(300)
    expect(popped()).toBe(false)
  })

  it('does not flicker on the popout\'s own Turbo visit (remove, then re-stamp)', async () => {
    stamp()
    await start()

    unstamp()
    storageEvent(null)
    vi.advanceTimersByTime(20)
    stamp()
    storageEvent(localStorage.getItem(KEY))
    vi.advanceTimersByTime(300)

    expect(popped()).toBe(true)
  })

  it('restores the dock when the stamp goes stale without a storage event', async () => {
    stamp()
    await start()
    expect(popped()).toBe(true)

    vi.advanceTimersByTime(1000)
    expect(popped()).toBe(true)
    vi.advanceTimersByTime(1000)
    expect(popped()).toBe(false)
  })

  it('picks up a same-window stamp via the poll (no storage event)', async () => {
    await start()
    stamp()
    expect(popped()).toBe(false)
    vi.advanceTimersByTime(500)
    expect(popped()).toBe(true)
  })

  it('clears the class and stops polling on disconnect', async () => {
    stamp()
    await start()
    const el = embed()
    expect(el.classList.contains('uplink-popped')).toBe(true)

    document.body.innerHTML = ''
    await Promise.resolve()

    expect(el.classList.contains('uplink-popped')).toBe(false)
    expect(vi.getTimerCount()).toBe(0)
  })
})
