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

// The /uplink shell composer: textarea + multiline value, Enter sends.
function textareaFixture (opts: { slowMode?: number, limit?: number } = {}): string {
  return `
    <div data-controller="packet-form"
         data-packet-form-slow-mode-value="${opts.slowMode ?? 0}"
         data-packet-form-limit-value="${opts.limit ?? 20}"
         data-packet-form-multiline-value="true">
      <form>
        <div class="packet-input-field">
          <textarea data-packet-form-target="input" data-action="input->packet-form#update keydown->packet-form#keydown"></textarea>
          <ul class="emote-menu" hidden></ul>
          <span data-packet-form-target="count"></span>
        </div>
        <button type="submit" data-packet-form-target="submit">TX</button>
      </form>
    </div>`
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

  function enter (init: KeyboardEventInit = {}): KeyboardEvent {
    const event = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true, ...init })
    input().dispatchEvent(event)
    return event
  }

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  describe('multiline (shell textarea)', () => {
    it('sends on Enter, keeps Shift+Enter and picker-consumed Enters, never sends empty', async () => {
      const requestSubmit = vi.spyOn(HTMLFormElement.prototype, 'requestSubmit').mockImplementation(() => {})
      await start(textareaFixture())

      expect(enter().defaultPrevented).toBe(true) // empty: swallowed, not sent
      expect(requestSubmit).not.toHaveBeenCalled()

      type('line one')
      expect(enter({ shiftKey: true }).defaultPrevented).toBe(false) // newline stays with the field
      expect(requestSubmit).not.toHaveBeenCalled()

      const consumed = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true })
      consumed.preventDefault() // the emote picker picked an emote
      input().dispatchEvent(consumed)
      expect(requestSubmit).not.toHaveBeenCalled()

      document.querySelector('.emote-menu')!.hidden = false // menu open: Enter belongs to the picker
      expect(enter().defaultPrevented).toBe(false)
      expect(requestSubmit).not.toHaveBeenCalled()
      document.querySelector('.emote-menu')!.hidden = true

      expect(enter().defaultPrevented).toBe(true)
      expect(requestSubmit).toHaveBeenCalledTimes(1)
    })

    it('leaves Enter alone on the single-line input', async () => {
      const requestSubmit = vi.spyOn(HTMLFormElement.prototype, 'requestSubmit').mockImplementation(() => {})
      await start(fixture().replace('data-action="input->packet-form#update"', 'data-action="input->packet-form#update keydown->packet-form#keydown"'))
      type('msg')

      expect(enter().defaultPrevented).toBe(false)
      expect(requestSubmit).not.toHaveBeenCalled()
    })

    it('hands focus back to the field when a cooldown that disabled it ends', async () => {
      vi.useFakeTimers()
      await start(textareaFixture({ slowMode: 2 }))
      type('msg')

      controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
      expect(input().disabled).toBe(true)
      expect(document.activeElement).toBe(document.body) // disabled: focus() was a no-op

      vi.advanceTimersByTime(2000)
      expect(input().disabled).toBe(false)
      expect(document.activeElement).toBe(input())
    })
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
