import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
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

// The /uplink shell composer: textarea + multiline value, Enter sends;
// with `reply`, the hidden reply_to_id + reply bar and the document
// listener for packet:reply.
function textareaFixture (opts: { slowMode?: number, limit?: number, reply?: boolean, disabled?: boolean } = {}): string {
  return `
    <div data-controller="packet-form"
         data-packet-form-slow-mode-value="${opts.slowMode ?? 0}"
         data-packet-form-limit-value="${opts.limit ?? 20}"
         data-packet-form-multiline-value="true"${opts.reply ? ' data-action="packet:reply@document->packet-form#reply"' : ''}>
      ${opts.reply ? `
      <div class="packet-reply-bar" hidden data-packet-form-target="replyBar">
        REPLYING TO <span data-packet-form-target="replySender"></span>
        <button type="button" data-action="click->packet-form#cancelReply">[x]</button>
      </div>` : ''}
      <form>
        ${opts.reply ? '<input type="hidden" name="reply_to_id" data-packet-form-target="replyTo">' : ''}
        <div class="packet-input-field">
          <textarea data-packet-form-target="input" data-action="input->packet-form#update keydown->packet-form#keydown"${opts.disabled ? ' disabled' : ''}></textarea>
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

  // A test that starts twice must stop the first app, or its observers
  // keep binding every later fixture a second time (double actions).
  async function start (html: string): Promise<void> {
    application?.stop()
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

  describe('replies (shell composer)', () => {
    const replyTo = (): HTMLInputElement => document.querySelector('[data-packet-form-target="replyTo"]')!
    const bar = (): HTMLElement => document.querySelector('[data-packet-form-target="replyBar"]')!

    function armReply (id: string, sender = '@xeraen'): void {
      document.body.dispatchEvent(new CustomEvent('packet:reply', { bubbles: true, detail: { id, sender } }))
    }

    function escape (): KeyboardEvent {
      const event = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true })
      input().dispatchEvent(event)
      return event
    }

    it('arms the hidden reply_to_id and the bar from packet:reply, focuses the field; [x] disarms', async () => {
      await start(textareaFixture({ reply: true }))
      expect(bar().hidden).toBe(true)

      armReply('42')
      expect(replyTo().value).toBe('42')
      expect(bar().hidden).toBe(false)
      expect(bar().textContent).toContain('REPLYING TO @xeraen')
      expect(document.activeElement).toBe(input())

      armReply('7', 'TTV viewer') // re-arming swaps the target
      expect(replyTo().value).toBe('7')
      expect(bar().textContent).toContain('TTV viewer')

      ;(bar().querySelector('button') as HTMLButtonElement).click()
      expect(replyTo().value).toBe('')
      expect(bar().hidden).toBe(true)
    })

    it('ignores garbage ids and a role-gated (disabled) field, but still arms during a cooldown', async () => {
      vi.useFakeTimers()
      await start(textareaFixture({ reply: true, disabled: true }))
      armReply('42')
      expect(replyTo().value).toBe('')
      expect(bar().hidden).toBe(true)

      await start(textareaFixture({ reply: true, slowMode: 3 }))
      armReply('../etc')
      armReply('')
      expect(replyTo().value).toBe('')

      type('msg')
      controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
      expect(input().disabled).toBe(true) // cooling down
      armReply('42')
      expect(replyTo().value).toBe('42')
      expect(bar().hidden).toBe(false)
    })

    it('Escape disarms an armed reply and is otherwise left alone (an open emote menu gets it first)', async () => {
      await start(textareaFixture({ reply: true }))
      expect(escape().defaultPrevented).toBe(false) // nothing armed: the shell may use it

      armReply('42')
      const consumed = new KeyboardEvent('keydown', { key: 'Escape', bubbles: true, cancelable: true })
      consumed.preventDefault() // the emote picker closed its menu with this one
      input().dispatchEvent(consumed)
      expect(replyTo().value).toBe('42')

      expect(escape().defaultPrevented).toBe(true)
      expect(replyTo().value).toBe('')
      expect(bar().hidden).toBe(true)
    })

    it('disarms after a successful send, keeps the reply on failure', async () => {
      await start(textareaFixture({ reply: true }))
      armReply('42')
      type('reply text')

      controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: false } }))
      expect(replyTo().value).toBe('42')
      expect(input().value).toBe('reply text')

      controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
      expect(replyTo().value).toBe('')
      expect(bar().hidden).toBe(true)
      expect(input().value).toBe('')
    })

    it('is inert on a composer without reply targets (dock, popout)', async () => {
      await start(textareaFixture().replace('data-packet-form-multiline-value="true"', 'data-packet-form-multiline-value="true" data-action="packet:reply@document->packet-form#reply"'))
      armReply('42')
      expect(document.querySelector('[name="reply_to_id"]')).toBeNull()
      expect(escape().defaultPrevented).toBe(false)
    })
  })

  describe('typing (shell composer)', () => {
    let seen: string[]
    let aborter: AbortController

    beforeEach(() => {
      vi.useFakeTimers()
      seen = []
      aborter = new AbortController() // document listeners must not outlive the example
      document.addEventListener('packet-form:typing', () => seen.push('typing'), { signal: aborter.signal })
      document.addEventListener('packet-form:stop-typing', () => seen.push('stop'), { signal: aborter.signal })
    })

    afterEach(() => aborter.abort())

    it('dispatches typing on the first keystroke then at most every 3s, and stop-typing when the field empties, blurs or sends', async () => {
      await start(textareaFixture().replace('keydown->packet-form#keydown', 'keydown->packet-form#keydown blur->packet-form#blur'))
      expect(seen).toEqual([]) // connect's update() on an empty field says nothing

      type('h')
      type('he')
      expect(seen).toEqual(['typing'])
      vi.advanceTimersByTime(2999)
      type('hel')
      expect(seen).toEqual(['typing'])
      vi.advanceTimersByTime(1)
      type('hell')
      expect(seen).toEqual(['typing', 'typing'])

      type('')
      expect(seen).toEqual(['typing', 'typing', 'stop'])
      type('   ')
      expect(seen).toEqual(['typing', 'typing', 'stop']) // whitespace is not composing

      type('x')
      input().dispatchEvent(new Event('blur'))
      expect(seen).toEqual(['typing', 'typing', 'stop', 'typing', 'stop'])
      input().dispatchEvent(new Event('blur')) // already stopped: quiet
      expect(seen.length).toBe(5)

      type('y')
      controller().submitted(new CustomEvent('turbo:submit-end', { detail: { success: true } }))
      expect(seen).toEqual(['typing', 'typing', 'stop', 'typing', 'stop', 'typing', 'stop'])
      expect(input().value).toBe('')
    })

    it('never dispatches from the single-line composer (dock, popout)', async () => {
      await start(fixture())
      type('hello')
      input().dispatchEvent(new Event('blur'))
      expect(seen).toEqual([])
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
