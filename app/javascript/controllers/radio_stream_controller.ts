import { Controller } from '@hotwired/stimulus'

// Raw-stream radio stations (RadioPage.tsx "path 2"): stations with a
// stream_url and no playlists play through a page-local <audio>, with
// their own fixed bottom bar (STOP / volume) — entirely separate from
// the permanent player. One controller instance wraps the whole radio
// page; each raw-stream TUNE IN button carries its station data.

export default class extends Controller {
  static targets = ['audio', 'bar', 'stationName', 'genre', 'volume']

  declare readonly audioTarget: HTMLAudioElement
  declare readonly barTarget: HTMLElement
  declare readonly stationNameTarget: HTMLElement
  declare readonly genreTarget: HTMLElement
  declare readonly volumeTarget: HTMLInputElement

  private credited = new Set<number>()

  tuneIn (event: Event): void {
    const button = event.currentTarget as HTMLElement
    const streamUrl = button.dataset.streamUrl || ''
    const stationId = Number(button.dataset.stationId)

    this.audioTarget.src = streamUrl
    this.audioTarget.volume = Number(this.volumeTarget.value) / 100
    this.stationNameTarget.textContent = button.dataset.stationName || ''
    this.genreTarget.textContent = button.dataset.stationGenre || ''
    this.barTarget.hidden = false

    this.audioTarget.play()
      .then(() => {
        // Credit only on confirmed playback, once per station per visit.
        if (!this.loggedIn() || this.credited.has(stationId)) return
        this.credited.add(stationId)
        fetch(`/api/radio_stations/${stationId}/tune_in`, { method: 'POST' })
          .catch(() => { /* fire-and-forget */ })
      })
      .catch((error) => {
        console.error('Error playing stream:', error)
        alert('Error: Unable to connect to radio stream. Please check the stream URL.')
      })
  }

  stop (): void {
    this.audioTarget.pause()
    this.audioTarget.currentTime = 0
    this.audioTarget.removeAttribute('src')
    this.barTarget.hidden = true
  }

  volumeChanged (): void {
    this.audioTarget.volume = Number(this.volumeTarget.value) / 100
  }

  private loggedIn (): boolean {
    return document.querySelector('meta[name="current-hackr-id"]') !== null
  }
}
