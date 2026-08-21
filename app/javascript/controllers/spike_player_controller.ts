import { Controller } from '@hotwired/stimulus'

// Phase 0 spike A: proves an <audio> inside a data-turbo-permanent element
// keeps playing across Turbo visits. Findings feed phase_4_player_music.md.
// Note: Stimulus re-fires connect() after every Turbo visit (the permanent
// element is transplanted into the new body), so one-time wiring is guarded.
export default class extends Controller {
  static targets = ['audio', 'time', 'status']

  declare readonly audioTarget: HTMLAudioElement
  declare readonly timeTarget: HTMLElement
  declare readonly statusTarget: HTMLElement

  connect (): void {
    if (this.element.hasAttribute('data-spike-wired')) return
    this.element.setAttribute('data-spike-wired', 'true')
    this.audioTarget.addEventListener('timeupdate', () => {
      this.timeTarget.textContent = this.audioTarget.currentTime.toFixed(1)
    })
  }

  async toggle (): Promise<void> {
    if (this.audioTarget.paused) {
      await this.audioTarget.play()
      this.statusTarget.textContent = 'playing'
    } else {
      this.audioTarget.pause()
      this.statusTarget.textContent = 'paused'
    }
  }
}
