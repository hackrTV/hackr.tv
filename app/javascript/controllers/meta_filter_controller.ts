import { Controller } from '@hotwired/stimulus'

// Client-side category/status tabs for the grid meta pages: buttons
// carry data-filter, items carry data-filter; 'all' shows everything.
// Server renders every card; this only toggles visibility (the SPA
// filtered in-memory the same way).
export default class extends Controller<HTMLElement> {
  static targets = ['button', 'item']

  declare readonly buttonTargets: HTMLButtonElement[]
  declare readonly itemTargets: HTMLElement[]

  select (event: Event): void {
    const key = (event.currentTarget as HTMLElement).dataset.filter
    if (!key) return
    this.buttonTargets.forEach(btn => {
      btn.classList.toggle('grid-meta-tab--active', btn.dataset.filter === key)
    })
    this.itemTargets.forEach(item => {
      item.hidden = key !== 'all' && item.dataset.filter !== key
    })
  }
}
