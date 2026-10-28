import { describe, it, expect, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import ComposerController from './composer_controller'

const FORM = `
  <form data-controller="composer" data-composer-limit-value="256" data-action="turbo:submit-end->composer#submitted">
    <input type="hidden" name="parent_pulse_id" value="7" data-composer-target="parent">
    <textarea class="wire-prompt-input" name="content" placeholder="Splice into @root's thread..." data-default-placeholder="Splice into @root's thread..." data-composer-target="input" data-action="input->composer#update keydown->composer#keydown"></textarea>
    <span class="char-count" data-composer-target="count"></span>
    <button type="submit" data-composer-target="submit" disabled>TX</button>
  </form>`

describe('ComposerController', () => {
  let application: Application

  async function start (): Promise<{ form: HTMLFormElement, input: HTMLTextAreaElement, count: HTMLElement, submit: HTMLButtonElement }> {
    document.body.innerHTML = FORM
    application = Application.start()
    application.register('composer', ComposerController)
    await Promise.resolve()
    const form = document.querySelector<HTMLFormElement>('form')!
    form.requestSubmit = vi.fn()
    return {
      form,
      input: form.querySelector<HTMLTextAreaElement>('textarea')!,
      count: form.querySelector<HTMLElement>('.char-count')!,
      submit: form.querySelector<HTMLButtonElement>('button')!
    }
  }

  function type (input: HTMLTextAreaElement, text: string): void {
    input.value = text
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }

  function key (input: HTMLTextAreaElement, init: KeyboardEventInit): KeyboardEvent {
    const event = new KeyboardEvent('keydown', { bubbles: true, cancelable: true, ...init })
    input.dispatchEvent(event)
    return event
  }

  afterEach(() => {
    application?.stop()
    document.body.innerHTML = ''
  })

  it('counts "remaining / limit" with warning and over-limit states and gates the submit', async () => {
    const { input, count, submit } = await start()
    expect(count.textContent).toBe('256 / 256')
    expect(submit.disabled).toBe(true)

    type(input, 'hello')
    expect(count.textContent).toBe('251 / 256')
    expect(submit.disabled).toBe(false)

    type(input, 'x'.repeat(240))
    expect(count.classList.contains('warning')).toBe(true)
    type(input, 'x'.repeat(300))
    expect(count.classList.contains('over-limit')).toBe(true)
    expect(submit.disabled).toBe(true)
  })

  it('Enter sends, Shift+Enter and a consumed Enter do not, Ctrl+Enter sends, Escape blurs', async () => {
    const { form, input } = await start()
    type(input, 'packet')

    expect(key(input, { key: 'Enter', shiftKey: true }).defaultPrevented).toBe(false)
    expect(form.requestSubmit).not.toHaveBeenCalled()

    const consumed = new KeyboardEvent('keydown', { key: 'Enter', bubbles: true, cancelable: true })
    consumed.preventDefault() // the emote picker picked
    input.dispatchEvent(consumed)
    expect(form.requestSubmit).not.toHaveBeenCalled()

    expect(key(input, { key: 'Enter' }).defaultPrevented).toBe(true)
    expect(form.requestSubmit).toHaveBeenCalledTimes(1)

    key(input, { key: 'Enter', ctrlKey: true })
    expect(form.requestSubmit).toHaveBeenCalledTimes(2)

    input.focus()
    key(input, { key: 'Escape' })
    expect(document.activeElement).not.toBe(input)
  })

  it('never sends an empty prompt on Enter', async () => {
    const { form, input } = await start()
    key(input, { key: 'Enter' })
    expect(form.requestSubmit).not.toHaveBeenCalled()
  })

  it('clears, reshrinks and re-aims the prompt at its root after a successful turbo submit', async () => {
    const { form, input, count } = await start()
    const parent = form.querySelector<HTMLInputElement>('input[name="parent_pulse_id"]')!
    type(input, 'sent')
    input.style.height = '80px'
    parent.value = '9' // wire-row aimed it at a reply
    input.placeholder = 'Reply to @someone...'

    form.dispatchEvent(new CustomEvent('turbo:submit-end', { detail: { success: true }, bubbles: true }))

    expect(input.value).toBe('')
    expect(count.textContent).toBe('256 / 256')
    expect(input.style.height).not.toBe('80px')
    expect(parent.value).toBe('7')
    expect(input.placeholder).toBe('Splice into @root\'s thread...')
  })
})
