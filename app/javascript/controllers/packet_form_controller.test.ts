import { describe, it, expect, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PacketFormController from './packet_form_controller'

// Fixture mirrors the uplink packet composer form (PacketInput.tsx port):
// counter, TX button, slow-mode cooldown, server-error slot.

function fixture (opts: { slowMode?: number, limit?: number } = {}): string {
  return `
    <form data-controller="packet-form"
          data-packet-form-slow-mode-value="${opts.slowMode ?? 0}"
          data-packet-form-limit-value="${opts.limit ?? 20}">
      <div class="packet-input-field">
        <input data-packet-form-target="input" data-action="input->packet-form#update">
        <span data-packet-form-target="count"></span>
      </div>
      <button type="submit" data-packet-form-target="submit">TX</button>
      <div id="error-slot"></div>
    </form>`
}

describe('PacketFormController', () => {
  let application: Application

  const input = (): HTMLInputElement => document.querySelector('[data-packet-form-target="input"]')!
  const count = (): HTMLElement => document.querySelector('[data-packet-form-target="count"]')!
  const submit = (): HTMLButtonElement => document.querySelector('[data-packet-form-target="submit"]')!

  function type (value: string): void {
    input().value = value
    input().dispatchEvent(new Event('input'))
  }

  function controller (): PacketFormController & { submitted: (e: Event) => void } {
    return application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="packet-form"]')!, 'packet-form'
    ) as PacketFormController & { submitted: (e: Event) => void }
  }

  async function start (html: string): Promise<void> {
    document.body.innerHTML = html
    application = Application.start()
    application.register('packet-form', PacketFormController)
    await Promise.resolve()
  }

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
  })

  it('tracks the counter with warning and over-limit states', async () => {
    await start(fixture({ limit: 20 }))
    expect(count().textContent).toBe('0/20')
    expect(submit().disabled).toBe(true) // empty

    type('hello')
    expect(count().textContent).toBe('5/20')
    expect(submit().disabled).toBe(false)
    expect(count().classList.contains('warning')).toBe(false)

    type('x'.repeat(19)) // >90% of 20
    expect(count().classList.contains('warning')).toBe(true)
    expect(count().classList.contains('over-limit')).toBe(false)

    type('x'.repeat(21))
    expect(count().classList.contains('over-limit')).toBe(true)
    expect(count().classList.contains('warning')).toBe(false)
    expect(submit().disabled).toBe(true)
    expect(document.querySelector('.packet-input-field')!.classList.contains('packet-input-field--over')).toBe(true)
  })

  it('keeps whitespace-only input unsubmittable', async () => {
    await start(fixture())
    type('   ')
    expect(submit().disabled).toBe(true)
  })

  it('clears and refocuses on successful submit; keeps input on failure', async () => {
    await start(fixture())
    type('transmission')

    controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: false } }))
    expect(input().value).toBe('transmission')

    controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
    expect(input().value).toBe('')
    expect(count().textContent).toBe('0/20')
  })

  it('runs the slow-mode cooldown on the TX button after success', async () => {
    vi.useFakeTimers()
    await start(fixture({ slowMode: 3 }))
    type('msg')

    controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))

    expect(submit().textContent).toBe('3s')
    expect(submit().disabled).toBe(true)
    expect(input().disabled).toBe(true)
    expect(submit().classList.contains('packet-input-send--cooldown')).toBe(true)

    vi.advanceTimersByTime(1000)
    expect(submit().textContent).toBe('2s')

    vi.advanceTimersByTime(2000)
    expect(submit().textContent).toBe('TX')
    expect(input().disabled).toBe(false)
    expect(submit().classList.contains('packet-input-send--cooldown')).toBe(false)
  })

  it('starts a server-directed cooldown when an error slot target connects', async () => {
    vi.useFakeTimers()
    await start(fixture())
    type('msg')

    const error = document.createElement('div')
    error.setAttribute('data-packet-form-target', 'error')
    error.dataset.waitSeconds = '2'
    document.getElementById('error-slot')!.appendChild(error)
    await Promise.resolve()

    expect(submit().textContent).toBe('2s')
    expect(submit().disabled).toBe(true)

    vi.advanceTimersByTime(2000)
    expect(submit().textContent).toBe('TX')
    expect(submit().disabled).toBe(false)
  })
})
