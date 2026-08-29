import { Controller } from '@hotwired/stimulus'

// BreachPanel TargetSelector port: one controller spans the action bar,
// so only one target menu is open at a time (the SPA's activeSelector).
// Trigger click toggles its anchor's menu; outside click / Escape /
// picking a target closes everything. The per-command meta replace
// rebuilds the bar closed anyway — closeAll on submit just covers the
// request latency gap.
export default class extends Controller<HTMLElement> {
  static targets = ['menu']

  declare readonly menuTargets: HTMLElement[]

  toggle (event: Event): void {
    const anchor = (event.currentTarget as HTMLElement).closest('.target-menu-anchor')
    const menu = anchor?.querySelector<HTMLElement>('[data-target-menu-target="menu"]')
    if (!menu) return
    const wasHidden = menu.hidden
    this.closeAll()
    if (wasHidden) menu.hidden = false
  }

  outside (event: Event): void {
    if (!this.element.contains(event.target as Node)) this.closeAll()
  }

  closeAll (): void {
    this.menuTargets.forEach(menu => { menu.hidden = true })
  }
}
