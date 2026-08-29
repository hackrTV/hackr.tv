import { Controller } from '@hotwired/stimulus'

// TacticalStatusPanel.tsx port: tab bar over lazily-loaded turbo
// frames. Frames carry loading="lazy", so a hidden panel's frame
// doesn't fetch until first shown; the refresh bus reloads only the
// visible frame after each command (dataRefreshToken parity).
export default class extends Controller<HTMLElement> {
  static targets = ['button', 'panel']

  declare readonly buttonTargets: HTMLButtonElement[]
  declare readonly panelTargets: HTMLElement[]

  select (event: Event): void {
    const tab = (event.currentTarget as HTMLElement).dataset.tab
    if (!tab) return
    this.buttonTargets.forEach(btn => {
      btn.classList.toggle('tactical-tab-button--active', btn.dataset.tab === tab)
    })
    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.tab !== tab
    })
  }
}
