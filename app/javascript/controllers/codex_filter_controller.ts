import { Controller } from '@hotwired/stimulus'

// Client-side type filter + search over the server-rendered Codex index —
// same behavior as CodexIndexPage.tsx, which filtered its fetched list in
// memory. Cards carry data-entry-type and a prebuilt data-search haystack
// (name + summary + metadata incl. search_tags, downcased).
export default class extends Controller {
  static targets = ['search', 'card', 'count', 'typeButton', 'empty', 'grid']

  declare readonly searchTarget: HTMLInputElement
  declare readonly cardTargets: HTMLElement[]
  declare readonly countTarget: HTMLElement
  declare readonly typeButtonTargets: HTMLElement[]
  declare readonly emptyTarget: HTMLElement
  declare readonly gridTarget: HTMLElement

  private selectedType = 'all'

  setType (event: MouseEvent): void {
    const button = event.currentTarget as HTMLElement
    this.selectedType = button.dataset.type || 'all'
    this.typeButtonTargets.forEach(b => {
      const active = b === button
      b.classList.toggle('cyan-168', active)
      b.classList.toggle('grey-168', !active)
    })
    this.filter()
  }

  filter (): void {
    const query = this.searchTarget.value.trim().toLowerCase()
    let shown = 0

    this.cardTargets.forEach(card => {
      const matchesType = this.selectedType === 'all' || card.dataset.entryType === this.selectedType
      const matchesQuery = query === '' || (card.dataset.search || '').includes(query)
      const show = matchesType && matchesQuery
      card.style.display = show ? '' : 'none'
      if (show) shown++
    })

    this.countTarget.textContent = `Showing ${shown} of ${this.cardTargets.length} entries`
    this.emptyTarget.style.display = shown === 0 ? '' : 'none'
    this.gridTarget.style.display = shown === 0 ? 'none' : ''
  }
}
