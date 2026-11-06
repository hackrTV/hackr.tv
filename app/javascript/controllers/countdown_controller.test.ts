import { describe, it, expect, afterEach, beforeEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import CountdownController from './countdown_controller'

const NOW = new Date('2026-11-06T12:00:00Z')

describe('CountdownController', () => {
  let application: Application

  const label = (): HTMLElement => document.querySelector('[data-countdown-target="label"]') as HTMLElement
  const sweep = (): HTMLElement | null => document.querySelector('[data-countdown-target="sweep"]')

  async function mount (deadline: Date, withSweep: boolean): Promise<void> {
    document.body.innerHTML = `
      <div data-controller="countdown" data-countdown-deadline-value="${deadline.toISOString()}">
        ${withSweep ? '<div data-countdown-target="sweep" hidden></div>' : ''}
        <span data-countdown-target="label"></span>
      </div>`
    application = Application.start()
    application.register('countdown', CountdownController)
    await Promise.resolve()
  }

  beforeEach(() => {
    vi.useFakeTimers()
    vi.setSystemTime(NOW)
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    vi.useRealTimers()
  })

  it('counts days, hours and minutes past a day', async () => {
    await mount(new Date(NOW.getTime() + ((28 * 60 + 20) * 60 + 15) * 1000), true)

    expect(label().textContent).toBe('T-MINUS 1d 4h 20m')
  })

  it('counts hours, minutes and seconds under a day, ticking each second', async () => {
    await mount(new Date(NOW.getTime() + (5 * 60 + 30) * 1000), true)

    expect(label().textContent).toBe('T-MINUS 0h 5m 30s')
    vi.advanceTimersByTime(1000)
    expect(label().textContent).toBe('T-MINUS 0h 5m 29s')
  })

  it('flips to STARTING SOON! at the deadline and shows the sweep', async () => {
    await mount(new Date(NOW.getTime() + 2000), true)

    vi.advanceTimersByTime(2000)

    expect(label().textContent).toBe('STARTING SOON!')
    expect(label().classList.contains('scheduled-banner-soon')).toBe(true)
    expect(sweep()?.hidden).toBe(false)
  })

  it('flips without a sweep target (the schedule NEXT TX row)', async () => {
    const error = vi.spyOn(console, 'error').mockImplementation(() => {})
    await mount(new Date(NOW.getTime() - 60_000), false)

    expect(label().textContent).toBe('STARTING SOON!')
    expect(label().classList.contains('scheduled-banner-soon')).toBe(true)
    expect(error).not.toHaveBeenCalled()
    error.mockRestore()
  })
})
