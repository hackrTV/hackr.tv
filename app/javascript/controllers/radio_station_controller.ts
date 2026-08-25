import { Controller } from '@hotwired/stimulus'
import type { PlayerTrack } from './player_controller'

// Playlist-backed radio station card (RadioPage.tsx "path 1"). Tune-in
// fetches the station's playlists, flattens their tracks, and hands the
// whole set to the permanent player as a shuffled station queue starting
// on a random track at a random position. Button label tracks player
// state; tune-credit fires once per station per page visit, only when
// audio is confirmed playing (setPlaylist alone proves nothing).

interface StationTrack {
  track_id: number
  audio_url: string | null
  title: string
  artist: { name: string }
  release?: { cover_url: string | null, cover_urls?: { thumbnail: string, standard: string, full: string } }
}

interface StationPlaylist {
  tracks?: StationTrack[]
}

interface PlayerState {
  trackId: string | null
  playing: boolean
  stationId: number | null
}

export default class extends Controller {
  static targets = ['button']
  static values = {
    stationId: Number,
    stationName: String
  }

  declare readonly buttonTarget: HTMLButtonElement
  declare stationIdValue: number
  declare stationNameValue: string

  private playing = false
  private isCurrent = false
  private credited = false

  connect (): void {
    document.addEventListener('player:state', this.onPlayerState as EventListener)
  }

  disconnect (): void {
    document.removeEventListener('player:state', this.onPlayerState as EventListener)
  }

  private readonly onPlayerState = (event: CustomEvent<PlayerState>): void => {
    this.isCurrent = event.detail.stationId === this.stationIdValue
    this.playing = this.isCurrent && event.detail.playing
    this.repaintButton()

    if (this.playing && !this.credited && this.loggedIn()) {
      this.credited = true
      fetch(`/api/radio_stations/${this.stationIdValue}/tune_in`, { method: 'POST' })
        .catch(() => { /* fire-and-forget */ })
    }
  }

  private loggedIn (): boolean {
    return document.querySelector('meta[name="current-hackr-id"]') !== null
  }

  private repaintButton (): void {
    if (this.isCurrent) {
      this.buttonTarget.textContent = this.playing ? '❚❚ PAUSE' : '▶ RESUME'
      this.buttonTarget.classList.add('tune-in-btn--current')
    } else {
      this.buttonTarget.textContent = '▶ PLAY STATION'
      this.buttonTarget.classList.remove('tune-in-btn--current')
    }
  }

  async play (): Promise<void> {
    if (this.isCurrent) {
      document.dispatchEvent(new CustomEvent('player:toggle'))
      return
    }

    try {
      const response = await fetch(`/api/radio_stations/${this.stationIdValue}/playlists`)
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const playlists = await response.json() as StationPlaylist[]

      const allTracks: PlayerTrack[] = []
      for (const playlist of playlists) {
        for (const track of playlist.tracks ?? []) {
          if (!track.audio_url) continue
          allTracks.push({
            id: String(track.track_id),
            url: track.audio_url,
            title: track.title,
            artist: track.artist.name,
            coverUrl: track.release?.cover_url || '',
            coverThumbUrl: track.release?.cover_urls?.thumbnail || '',
            coverFullUrl: track.release?.cover_urls?.full || ''
          })
        }
      }

      if (allTracks.length === 0) {
        alert('No playable tracks found in station playlists.')
        return
      }

      const randomTrack = allTracks[Math.floor(Math.random() * allTracks.length)]
      document.dispatchEvent(new CustomEvent('player:load-track', {
        detail: {
          track: randomTrack,
          playlist: allTracks,
          station: { id: this.stationIdValue, name: this.stationNameValue },
          randomStart: true
        }
      }))
    } catch (error) {
      console.error('Error loading station playlists:', error)
      alert('Failed to load station playlists. Please try again.')
    }
  }
}
