import { Controller } from '@hotwired/stimulus'

// Client-side search + language filter for the server-rendered code index
// (CodeIndexPage.tsx behavior: language buttons toggle, search matches
// name/description). Cards carry data-language + a data-search haystack.
export default class extends Controller {
  static targets = ['search', 'card', 'langButton', 'empty', 'grid']

  declare readonly searchTarget: HTMLInputElement
  declare readonly cardTargets: HTMLElement[]
  declare readonly langButtonTargets: HTMLElement[]
  declare readonly emptyTarget: HTMLElement
  declare readonly gridTarget: HTMLElement

  private language: string | null = null

  setLanguage (event: MouseEvent): void {
    const button = event.currentTarget as HTMLElement
    const lang = button.dataset.language || null
    // Clicking the active language clears it (SPA toggle behavior)
    this.language = this.language === lang ? null : lang
    this.langButtonTargets.forEach(b => {
      b.classList.toggle('active', (b.dataset.language || null) === this.language)
    })
    this.filter()
  }

  filter (): void {
    const query = this.searchTarget.value.trim().toLowerCase()
    let shown = 0

    this.cardTargets.forEach(card => {
      const matchesLang = this.language === null || card.dataset.language === this.language
      const matchesQuery = query === '' || (card.dataset.search || '').includes(query)
      const show = matchesLang && matchesQuery
      card.style.display = show ? '' : 'none'
      if (show) shown++
    })

    this.emptyTarget.style.display = shown === 0 ? '' : 'none'
    this.gridTarget.style.display = shown === 0 ? 'none' : ''
  }
}
