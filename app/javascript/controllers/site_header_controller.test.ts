import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import SiteHeaderController from './site_header_controller'

// The header publishes its rendered height as --site-header-h on <html>
// (nav rows + notices vary) and re-publishes when it resizes.

describe('SiteHeaderController', () => {
  let application: Application
  let resize: (() => void) | undefined
  let height: number

  const published = (): string => document.documentElement.style.getPropertyValue('--site-header-h')

  beforeEach(async () => {
    height = 44
    resize = undefined
    vi.stubGlobal('ResizeObserver', class {
      constructor (callback: () => void) { resize = callback }
      observe (): void { /* jsdom stub */ }
      disconnect (): void { /* jsdom stub */ }
    })
    vi.spyOn(HTMLElement.prototype, 'getBoundingClientRect').mockImplementation(() => ({ height } as unknown as DOMRect))
    document.body.innerHTML = '<header class="site-header" data-controller="site-header"><nav>nav</nav></header>'
    application = Application.start()
    application.register('site-header', SiteHeaderController)
    await Promise.resolve()
  })

  afterEach(async () => {
    application.stop()
    document.body.innerHTML = ''
    document.documentElement.style.removeProperty('--site-header-h')
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
    await Promise.resolve()
  })

  it('publishes the header height on connect', () => {
    expect(published()).toBe('44px')
  })

  it('re-publishes when the header resizes', () => {
    height = 110
    resize?.()
    expect(published()).toBe('110px')
  })
})
