import { Controller } from '@hotwired/stimulus'

// RestPodPanel.tsx allocation math: per-vital point inputs, FULL /
// FILL ALL shortcuts, live pts→CRED total, RESTORE disabled until
// affordable and non-zero. Submit composes the exact SPA command:
// "rest 5 health 10 energy 3 psyche".
export default class extends Controller<HTMLElement> {
  static targets = ['alloc', 'total', 'submit', 'command']
  static values = { rate: Number, balance: Number }

  declare readonly allocTargets: HTMLInputElement[]
  declare readonly totalTarget: HTMLElement
  declare readonly submitTarget: HTMLButtonElement
  declare readonly commandTarget: HTMLInputElement
  declare readonly rateValue: number
  declare readonly balanceValue: number

  connect (): void {
    this.recalc()
  }

  full (event: Event): void {
    const vital = (event.currentTarget as HTMLElement).dataset.vital
    const input = this.allocTargets.find(i => i.dataset.vital === vital)
    if (input) input.value = input.dataset.deficit ?? '0'
    this.recalc()
  }

  fillAll (): void {
    this.allocTargets.forEach(input => { input.value = input.dataset.deficit ?? '0' })
    this.recalc()
  }

  recalc (): void {
    const points = this.totalPoints()
    const cred = Math.ceil(points / Math.max(this.rateValue, 1))
    const affordable = cred <= this.balanceValue
    this.totalTarget.textContent = points > 0
      ? `Total: ${points} pts → ${cred} CRED${affordable ? '' : ' — Insufficient CRED'}`
      : 'Total: 0 pts → 0 CRED'
    this.totalTarget.classList.toggle('tab-warn', points > 0 && affordable)
    this.totalTarget.classList.toggle('tab-error', points > 0 && !affordable)
    this.totalTarget.classList.toggle('tab-faint', points === 0)
    this.submitTarget.disabled = points === 0 || !affordable
  }

  submit (event: Event): void {
    const parts: string[] = []
    for (const input of this.allocTargets) {
      const points = Math.max(0, parseInt(input.value, 10) || 0)
      if (points > 0) parts.push(`${points} ${input.dataset.vital}`)
    }
    if (parts.length === 0) {
      event.preventDefault()
      return
    }
    this.commandTarget.value = `rest ${parts.join(' ')}`
  }

  private totalPoints (): number {
    return this.allocTargets.reduce((sum, input) => {
      const deficit = parseInt(input.dataset.deficit ?? '0', 10)
      const points = Math.max(0, Math.min(deficit, parseInt(input.value, 10) || 0))
      return sum + points
    }, 0)
  }
}
