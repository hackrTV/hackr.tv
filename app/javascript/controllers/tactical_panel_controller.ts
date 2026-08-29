import { Controller } from '@hotwired/stimulus'
import { trackEvent } from '~/utils/analyticsCollector'

interface FrameElementLike extends HTMLElement {
  src: string | null
}

// Slide-in panel orchestration (GridTacticalPage handle/panel
// conditionals port): one open panel at a time, handles hide while a
// panel is up, 300ms slide via class toggle, backdrop click closes.
// Panel frames lazy-load on first open (data-src); the refresh bus
// reloads whichever is open after each command. The whole region is
// replaced on movement, which resets everything closed.
export default class extends Controller<HTMLElement> {
  static targets = ['handle', 'panel', 'backdrop']

  declare readonly handleTargets: HTMLElement[]
  declare readonly panelTargets: HTMLElement[]
  declare readonly backdropTarget: HTMLElement
  declare readonly hasBackdropTarget: boolean

  private openPanel: string | null = null

  open (event: Event): void {
    const trigger = event.currentTarget as HTMLElement
    const name = trigger.dataset.panel
    if (!name) return

    const panel = this.panelTargets.find(p => p.dataset.panel === name)
    if (!panel) return

    const frame = panel.querySelector<FrameElementLike>('turbo-frame')
    if (frame && !frame.src) {
      const base = panel.dataset.src ?? (name === 'npc' ? `/grid/1337/panels/npc?mob_id=${trigger.dataset.mobId}` : null)
      if (base) frame.src = base
    } else if (frame && name === 'npc' && trigger.dataset.mobId) {
      frame.src = `/grid/1337/panels/npc?mob_id=${trigger.dataset.mobId}`
    }

    this.openPanel = name
    this.handleTargets.forEach(h => { h.hidden = true })
    if (this.hasBackdropTarget) this.backdropTarget.hidden = false
    this.panelTargets.forEach(p => {
      if (p.dataset.panel === name) {
        p.hidden = false
        requestAnimationFrame(() => requestAnimationFrame(() => p.classList.add('tactical-panel--open')))
      } else {
        p.hidden = true
        p.classList.remove('tactical-panel--open')
      }
    })
    trackEvent('panel_open', name)
  }

  close (): void {
    if (!this.openPanel) return
    const name = this.openPanel
    this.openPanel = null
    this.panelTargets.forEach(p => p.classList.remove('tactical-panel--open'))
    if (this.hasBackdropTarget) this.backdropTarget.hidden = true
    window.setTimeout(() => {
      this.panelTargets.forEach(p => { p.hidden = true })
      this.handleTargets.forEach(h => { h.hidden = false })
    }, 300)
    trackEvent('panel_close', name)
  }
}
