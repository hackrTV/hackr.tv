import { describe, it, expect, afterEach } from 'vitest'
import { Application } from '@hotwired/stimulus'
import WireFeedController from './wire_feed_controller'

const DAY = 24 * 60 * 60 * 1000

function entry (id: number, at: number, inner = ''): string {
  return `<div id="pulse_${id}_entry" class="wire-entry" data-at="${at}"><div id="pulse_${id}" class="wire-row">p${id}</div>${inner}</div>`
}

const localNoon = (daysAgo: number): number => {
  const d = new Date()
  d.setHours(12, 0, 0, 0)
  return d.getTime() - daysAgo * DAY
}

describe('WireFeedController', () => {
  let application: Application

  async function start (rows: string): Promise<void> {
    document.body.innerHTML = `<div class="wire-page" data-controller="wire-feed"><div id="wire-feed">${rows}</div></div>`
    application = Application.start()
    application.register('wire-feed', WireFeedController)
    await Promise.resolve()
  }

  const labels = (): string[] => Array.from(document.querySelectorAll('.wire-day')).map(el => el.textContent ?? '')

  afterEach(() => {
    application?.stop()
    document.body.innerHTML = ''
  })

  it('inserts one separator per local day, TODAY first, in document order', async () => {
    await start(entry(1, localNoon(0)) + entry(2, localNoon(0)) + entry(3, localNoon(1)) + entry(4, localNoon(3)))

    const days = labels()
    expect(days).toHaveLength(3)
    expect(days[0]).toMatch(/^\/\/ TODAY · \d{4}-\d{2}-\d{2} \/\/$/)
    expect(days[1]).toMatch(/^\/\/ \d{4}-\d{2}-\d{2} \/\/$/)
    expect(document.querySelector('#wire-feed')!.children[0]!.className).toBe('wire-day')
    expect(document.getElementById('pulse_3_entry')!.previousElementSibling!.className).toBe('wire-day')
  })

  it('reconciles after a live prepend and never duplicates separators', async () => {
    await start(entry(3, localNoon(1)))
    expect(labels()).toHaveLength(1)

    document.getElementById('wire-feed')!.insertAdjacentHTML('afterbegin', entry(9, localNoon(0)))
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(labels()).toHaveLength(2)
    expect(labels()[0]).toContain('TODAY')
    expect(document.getElementById('pulse_9_entry')!.previousElementSibling!.className).toBe('wire-day')
  })

  it('ignores text churn that adds no entries (the prompt counter)', async () => {
    await start(entry(1, localNoon(0)))
    const first = document.querySelector('.wire-day')!
    const counter = document.createElement('span')
    document.querySelector('.wire-page')!.prepend(counter)
    await new Promise(resolve => setTimeout(resolve, 0))

    counter.textContent = '255 / 256'
    await new Promise(resolve => setTimeout(resolve, 0))

    expect(document.querySelector('.wire-day')).toBe(first) // not rebuilt
  })

  it('skips entries inside open threads', async () => {
    const threadRows = `<turbo-frame id="pulse_1_thread" class="wire-thread">${entry(2, localNoon(2))}</turbo-frame>`
    await start(entry(1, localNoon(0), threadRows))

    expect(labels()).toHaveLength(1)
    expect(document.querySelector('turbo-frame .wire-day')).toBeNull()
  })
})
