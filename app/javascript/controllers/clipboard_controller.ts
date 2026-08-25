import { Controller } from '@hotwired/stimulus'

// ProfileHeader.tsx share button: copies the vanity profile URL and
// flashes COPIED ✓ for two seconds.
export default class extends Controller<HTMLElement> {
  static targets = ['button']
  static values = { text: String, copiedLabel: String }

  declare readonly buttonTarget: HTMLElement
  declare readonly textValue: string
  declare readonly copiedLabelValue: string

  copy (): void {
    const original = this.buttonTarget.textContent
    navigator.clipboard.writeText(this.textValue).then(() => {
      this.buttonTarget.textContent = this.copiedLabelValue || 'COPIED ✓'
      window.setTimeout(() => { this.buttonTarget.textContent = original }, 2000)
    })
  }
}
