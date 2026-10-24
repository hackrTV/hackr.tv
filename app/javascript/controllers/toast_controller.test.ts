import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import ToastController from './toast_controller'

// Fixture mirrors the layout's #toast-region with shared/_toast_* toasts
// appended by Turbo Stream broadcasts.

describe('ToastController', () => {
  let application: Application

  const region = (): HTMLElement => document.getElementById('toast-region')!

  function toast (channel?: string): string {
    return `<div class="toast" data-controller="toast" data-action="click->toast#dismiss"${channel ? ` data-channel="${channel}"` : ''}>t</div>`
  }

  beforeEach(async () => {
    vi.useFakeTimers()
    document.body.innerHTML = '<div id="toast-region"></div>'
    application = Application.start()
    application.register('toast', ToastController)
    await Promise.resolve()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    vi.useRealTimers()
  })

  it('announces itself with its channel on connect, auto-dismisses after 6s, dismisses on click', async () => {
    const seen: Array<string | null> = []
    document.addEventListener('toast:connected', event => seen.push((event as CustomEvent).detail.channel))

    region().insertAdjacentHTML('beforeend', toast('ambient'))
    region().insertAdjacentHTML('beforeend', toast())
    await vi.advanceTimersByTimeAsync(0)
    expect(seen).toEqual(['ambient', null])
    expect(region().children.length).toBe(2)

    ;(region().firstElementChild as HTMLElement).click()
    expect(region().children.length).toBe(1)

    await vi.advanceTimersByTimeAsync(6000)
    expect(region().children.length).toBe(0)
  })

  it('caps the stack at five, dropping the oldest', async () => {
    for (let i = 0; i < 7; i++) region().insertAdjacentHTML('beforeend', toast())
    await vi.advanceTimersByTimeAsync(0)
    expect(region().children.length).toBe(5)
  })
})
