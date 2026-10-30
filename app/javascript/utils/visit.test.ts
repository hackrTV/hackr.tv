import { describe, it, expect, afterEach, vi } from 'vitest'
import { visit } from './visit'

type TurboWindow = Window & { Turbo?: { visit: (url: string) => void } }

describe('visit', () => {
  const originalLocation = window.location

  afterEach(() => {
    delete (window as TurboWindow).Turbo
    Object.defineProperty(window, 'location', { configurable: true, value: originalLocation })
  })

  it('hands the URL to Turbo when Turbo is on the page', () => {
    const turboVisit = vi.fn()
    ;(window as TurboWindow).Turbo = { visit: turboVisit }
    const assign = vi.fn()
    Object.defineProperty(window, 'location', { configurable: true, value: { ...originalLocation, assign } })

    visit('/fm')

    expect(turboVisit).toHaveBeenCalledWith('/fm')
    expect(assign).not.toHaveBeenCalled()
  })

  it('does a full load without Turbo (the admin layout)', () => {
    const assign = vi.fn()
    Object.defineProperty(window, 'location', { configurable: true, value: { ...originalLocation, assign } })

    visit('/root/releases')

    expect(assign).toHaveBeenCalledWith('/root/releases')
  })
})
