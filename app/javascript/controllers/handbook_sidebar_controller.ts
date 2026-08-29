import { Controller } from '@hotwired/stimulus'

// Port of HandbookSidebar.tsx: collapsible sections + live search filter.
// Server renders initial open/closed state (open when no current section,
// or when the section is current). Searching shows only matching articles
// with their sections forced open; clearing restores toggle state.
export default class extends Controller {
  static targets = ['search', 'section', 'articles', 'article', 'caret', 'empty']

  declare readonly searchTarget: HTMLInputElement
  declare readonly sectionTargets: HTMLElement[]
  declare readonly articleTargets: HTMLElement[]
  declare readonly emptyTarget: HTMLElement

  toggle (event: MouseEvent): void {
    const section = (event.currentTarget as HTMLElement).closest('[data-handbook-sidebar-target~="section"]') as HTMLElement | null
    if (!section || this.searching()) return
    section.dataset.open = section.dataset.open === 'true' ? 'false' : 'true'
    this.applySection(section)
  }

  filter (): void {
    const query = this.searchTarget.value.trim().toLowerCase()
    let anyMatch = false

    this.sectionTargets.forEach(section => {
      let sectionMatches = 0
      this.articlesIn(section).forEach(article => {
        const match = query === '' || (article.dataset.search || '').includes(query)
        article.parentElement!.style.display = match ? '' : 'none'
        if (match) sectionMatches++
      })

      if (query === '') {
        section.style.display = ''
        this.applySection(section)
      } else {
        section.style.display = sectionMatches > 0 ? '' : 'none'
        this.setOpen(section, true)
        if (sectionMatches > 0) anyMatch = true
      }
    })

    this.emptyTarget.style.display = query !== '' && !anyMatch ? '' : 'none'
    if (query === '') this.emptyTarget.style.display = 'none'
  }

  private searching (): boolean {
    return this.searchTarget.value.trim() !== ''
  }

  private articlesIn (section: HTMLElement): HTMLElement[] {
    return this.articleTargets.filter(a => section.contains(a))
  }

  private applySection (section: HTMLElement): void {
    this.setOpen(section, section.dataset.open === 'true')
  }

  private setOpen (section: HTMLElement, open: boolean): void {
    const list = section.querySelector('[data-handbook-sidebar-target~="articles"]') as HTMLElement | null
    const caret = section.querySelector('[data-handbook-sidebar-target~="caret"]') as HTMLElement | null
    if (list) list.style.display = open ? '' : 'none'
    if (caret) caret.textContent = open ? '▾' : '▸'
  }
}
