import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import UplinkController from './uplink_controller'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'

// Cable singleton is mocked: tests drive the subscription callbacks
// (connected/disconnected/rejected/received) directly.

vi.mock('~/lib/actionCableConsumer', () => {
  const subscriptions: Array<Record<string, (...args: unknown[]) => void>> = []
  const create = vi.fn((_params: unknown, callbacks: Record<string, (...args: unknown[]) => void>) => {
    subscriptions.push(callbacks)
    return { unsubscribe: vi.fn(), ...callbacks }
  })
  return {
    getActionCableConsumer: vi.fn(() => ({ subscriptions: { create } })),
    __subscriptions: subscriptions,
    __create: create
  }
})

const FIXTURE = `
  <div data-controller="uplink"
       data-uplink-channel-value="main"
       data-uplink-log-src-value="/uplink/log">
    <div data-uplink-target="banner" hidden></div>
    <span data-uplink-target="presenceDot"></span>
    <span data-uplink-target="presenceText"></span>
    <turbo-frame data-uplink-target="logFrame"></turbo-frame>
  </div>`

interface CableMockModule {
  __subscriptions: Array<Record<string, (...args: unknown[]) => void>>
  __create: ReturnType<typeof vi.fn>
}

describe('UplinkController', () => {
  let application: Application
  let cableMock: CableMockModule

  const banner = (): HTMLElement => document.querySelector('[data-uplink-target="banner"]')!
  const dot = (): HTMLElement => document.querySelector('[data-uplink-target="presenceDot"]')!
  const text = (): HTMLElement => document.querySelector('[data-uplink-target="presenceText"]')!
  const callbacks = (): Record<string, (...args: unknown[]) => void> =>
    cableMock.__subscriptions[cableMock.__subscriptions.length - 1]!

  async function start (html = FIXTURE): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('uplink', UplinkController)
    await Promise.resolve()
  }

  beforeEach(async () => {
    cableMock = await import('~/lib/actionCableConsumer') as unknown as CableMockModule
    cableMock.__subscriptions.length = 0
    cableMock.__create.mockClear()
    vi.mocked(getActionCableConsumer).mockClear()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
  })

  it('subscribes to LiveChatChannel with the channel value', async () => {
    await start()

    expect(cableMock.__create).toHaveBeenCalledWith(
      { channel: 'LiveChatChannel', chat_channel: 'main' },
      expect.any(Object)
    )
  })

  it('renders presence from initial_packets and presence_update messages', async () => {
    await start()
    callbacks().connected!()
    callbacks().received!({ type: 'initial_packets', presence_count: 1 })

    expect(dot().classList.contains('presence-dot--connected')).toBe(true)
    expect(text().textContent).toBe('1 operative connected')

    callbacks().received!({ type: 'presence_update', count: 5 })
    expect(text().textContent).toBe('5 operatives connected')
  })

  it('shows the reconnecting banner and disconnected presence on drop', async () => {
    await start()
    callbacks().connected!()
    callbacks().disconnected!()

    expect(banner().hidden).toBe(false)
    expect(banner().textContent).toBe('Reconnecting to uplink...')
    expect(banner().classList.contains('uplink-banner--disconnected')).toBe(false)
    expect(text().textContent).toBe('Disconnected')
    expect(dot().classList.contains('presence-dot--connected')).toBe(false)
  })

  it('marks a rejected subscription as terminal', async () => {
    await start()
    callbacks().rejected!()

    expect(banner().textContent).toBe('Uplink disconnected')
    expect(banner().classList.contains('uplink-banner--disconnected')).toBe(true)
  })

  it('reloads the log frame only on re-connects, recovering missed packets', async () => {
    await start()
    const frame = document.querySelector('turbo-frame') as HTMLElement & { src: string | null, reload: () => void }
    const reload = vi.fn()
    frame.reload = reload
    ;(frame as { src: string | null }).src = null

    callbacks().connected!() // first connect: no reload
    expect(reload).not.toHaveBeenCalled()
    expect(banner().hidden).toBe(true)

    callbacks().disconnected!()
    callbacks().connected!() // reconnect: frame had no src → set it
    expect((frame as { src: string | null }).src).toBe('/uplink/log')

    callbacks().disconnected!()
    callbacks().connected!() // reconnect with src present → reload()
    expect(reload).toHaveBeenCalledTimes(1)
  })

  it('renders disconnected without subscribing when no channel value', async () => {
    await start(`
      <div data-controller="uplink" data-uplink-channel-value="">
        <span data-uplink-target="presenceDot"></span>
        <span data-uplink-target="presenceText"></span>
      </div>`)

    expect(cableMock.__create).not.toHaveBeenCalled()
    expect(text().textContent).toBe('Disconnected')
  })

  it('unsubscribes on disconnect', async () => {
    await start()
    const sub = cableMock.__create.mock.results[0]!.value as { unsubscribe: ReturnType<typeof vi.fn> }

    document.body.innerHTML = ''
    await Promise.resolve()

    expect(sub.unsubscribe).toHaveBeenCalled()
  })
})
