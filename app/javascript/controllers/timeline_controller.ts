import { Controller } from '@hotwired/stimulus'

// TimelinePage.tsx interaction port: IntersectionObserver-driven active-era
// tracking for the nav, smooth scroll-to-era, and #hash deep linking.
export default class extends Controller {
  static targets = ['era', 'navButton']

  declare readonly eraTargets: HTMLElement[]
  declare readonly navButtonTargets: HTMLElement[]

  private observer: IntersectionObserver | null = null
  private visible = new Map<string, IntersectionObserverEntry>()

  connect (): void {
    this.observer = new IntersectionObserver(
      entries => {
        for (const entry of entries) {
          const id = entry.target.id
          if (entry.isIntersecting) {
            this.visible.set(id, entry)
          } else {
            this.visible.delete(id)
          }
        }
        // The section whose top is closest to (but below) the margin top
        // edge is the one being read (same heuristic as the SPA).
        let best: string | null = null
        let bestTop = -Infinity
        for (const [id, entry] of this.visible) {
          if (entry.boundingClientRect.top > bestTop) {
            bestTop = entry.boundingClientRect.top
            best = id
          }
        }
        if (best) this.setActive(best)
      },
      { rootMargin: '-80px 0px -70% 0px', threshold: [0, 0.1, 0.3] }
    )
    this.eraTargets.forEach(el => this.observer!.observe(el))

    const hash = window.location.hash.replace('#', '')
    if (hash) {
      setTimeout(() => this.scrollToKey(hash.replace(/-/g, '_')), 100)
    }
  }

  disconnect (): void {
    this.observer?.disconnect()
    this.visible.clear()
  }

  scrollTo (event: MouseEvent): void {
    const key = (event.currentTarget as HTMLElement).dataset.era
    if (key) this.scrollToKey(key)
  }

  private scrollToKey (key: string): void {
    const el = this.eraTargets.find(e => e.id === key)
    if (!el) return
    const offset = window.innerWidth < 768 ? 50 : 0
    const top = el.getBoundingClientRect().top + window.scrollY - offset
    window.scrollTo({ top, behavior: 'smooth' })
  }

  private setActive (key: string): void {
    this.navButtonTargets.forEach(b => b.classList.toggle('active', b.dataset.era === key))
  }
}
