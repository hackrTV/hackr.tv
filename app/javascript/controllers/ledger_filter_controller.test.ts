import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { Application } from '@hotwired/stimulus'
import LedgerFilterController from './ledger_filter_controller'

// The /root tracks ledger's FILTER row: rows match on data-search, a
// group with no visible rows hides, the count reads shown / total.

const HTML = `
<div data-controller="ledger-filter">
  <input data-ledger-filter-target="input" data-action="input->ledger-filter#filter" value="">
  <span data-ledger-filter-target="count">3 / 3</span>
  <section data-ledger-filter-target="group">
    <div data-ledger-filter-target="row" data-search="xordium xeraen omniwave">Xordium</div>
    <div data-ledger-filter-target="row" data-search="encrypted shroud xeraen omniwave">Encrypted Shroud</div>
  </section>
  <section data-ledger-filter-target="group">
    <div data-ledger-filter-target="row" data-search="signal lock the.cyberpul.se">Signal Lock</div>
  </section>
</div>`

describe('LedgerFilterController', () => {
  let application: Application

  const input = (): HTMLInputElement => document.querySelector('input') as HTMLInputElement
  const rows = (): HTMLElement[] => Array.from(document.querySelectorAll<HTMLElement>('[data-ledger-filter-target="row"]'))
  const groups = (): HTMLElement[] => Array.from(document.querySelectorAll<HTMLElement>('section'))
  const count = (): string => (document.querySelector('[data-ledger-filter-target="count"]') as HTMLElement).textContent ?? ''
  const type = (text: string): void => {
    input().value = text
    input().dispatchEvent(new Event('input', { bubbles: true }))
  }

  beforeEach(async () => {
    document.body.innerHTML = HTML
    application = Application.start()
    application.register('ledger-filter', LedgerFilterController)
    await Promise.resolve()
  })

  afterEach(async () => {
    application.stop()
    document.body.innerHTML = ''
    await Promise.resolve()
  })

  it('hides the rows that miss the query, and a group whose rows all miss', () => {
    type('xeraen')
    expect(rows().map(row => row.hidden)).toEqual([false, false, true])
    expect(groups().map(group => group.hidden)).toEqual([false, true])
    expect(count()).toBe('2 / 3')
  })

  it('matches case-insensitively on the haystack and restores everything on an empty query', () => {
    type('SIGNAL')
    expect(rows().map(row => row.hidden)).toEqual([true, true, false])
    type('')
    expect(rows().every(row => !row.hidden)).toBe(true)
    expect(groups().every(group => !group.hidden)).toBe(true)
    expect(count()).toBe('3 / 3')
  })
})
