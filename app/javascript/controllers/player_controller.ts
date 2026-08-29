import { Controller } from '@hotwired/stimulus'

// Permanent audio player (Phase 4). Lives on the layout's
// #player-bar[data-turbo-permanent] element so the <audio> keeps playing
// across Turbo visits (proven by the Phase 0 spike A). Because the element
// survives visits, Stimulus reuses this controller instance and re-fires
// connect() after every transplant — wiring is idempotent: handlers are
// instance-bound arrows and every add is preceded by a remove.
//
// Pages talk to the player only through document events:
//   player:load-track  { track, playlist?, station? }  — play a track; the
//     playlist (visible rows at click time) becomes the queue, exactly like
//     the React TrackTable's setPlaylist-at-click behavior. The queue is
//     NOT rebuilt on navigation — it persists until another list plays.
//   player:toggle — toggle play/pause (row click on the current track).
// The player answers with:
//   player:state { trackId, playing, stationId } — on every state change
//     and after each turbo:load, so track lists can repaint highlights.

export interface PlayerTrack {
  id: string
  url: string
  title: string
  artist: string
  coverUrl: string
  coverThumbUrl: string
  coverFullUrl: string
}

interface StationContext {
  id: number
  name: string
}

interface LoadTrackDetail {
  track: PlayerTrack
  playlist?: PlayerTrack[]
  station?: StationContext | null
  // Radio: seek to a random position (0–70% of duration) once metadata
  // loads, simulating tuning into an in-progress broadcast.
  randomStart?: boolean
}

const PLAY_CREDIT_SECONDS = 30
const WATCHDOG_INTERVAL_MS = 5000

export default class extends Controller {
  static targets = [
    'audio', 'bar', 'cover', 'coverImg', 'coverOverlay', 'coverOverlayImg',
    'controls', 'shuffleButton', 'playPause', 'station', 'stationName',
    'title', 'artist', 'seekBar', 'currentTime', 'duration',
    'queue', 'queueToggle', 'queueCount', 'queuePanel', 'queueList',
    'queueMore', 'queueItemTemplate', 'addToPlaylist'
  ]

  declare readonly audioTarget: HTMLAudioElement
  declare readonly barTarget: HTMLElement
  declare readonly coverTarget: HTMLElement
  declare readonly coverImgTarget: HTMLImageElement
  declare readonly coverOverlayTarget: HTMLElement
  declare readonly coverOverlayImgTarget: HTMLImageElement
  declare readonly controlsTarget: HTMLElement
  declare readonly shuffleButtonTarget: HTMLButtonElement
  declare readonly playPauseTarget: HTMLButtonElement
  declare readonly stationTarget: HTMLElement
  declare readonly stationNameTarget: HTMLElement
  declare readonly titleTarget: HTMLElement
  declare readonly artistTarget: HTMLElement
  declare readonly seekBarTarget: HTMLInputElement
  declare readonly currentTimeTarget: HTMLElement
  declare readonly durationTarget: HTMLElement
  declare readonly queueTarget: HTMLElement
  declare readonly queueToggleTarget: HTMLButtonElement
  declare readonly queueCountTarget: HTMLElement
  declare readonly queuePanelTarget: HTMLElement
  declare readonly queueListTarget: HTMLElement
  declare readonly queueMoreTarget: HTMLElement
  declare readonly queueItemTemplateTarget: HTMLTemplateElement
  declare readonly hasAddToPlaylistTarget: boolean
  declare readonly addToPlaylistTarget: HTMLElement

  private currentTrack: PlayerTrack | null = null
  private playing = false
  private seeking = false
  private shuffle = false
  private station: StationContext | null = null
  private playlist: PlayerTrack[] = []
  private shuffledPlaylist: PlayerTrack[] = []
  private creditedTrackIds = new Set<string>()
  private playedSecondsByTrack = new Map<string, number>()
  private lastPlaybackPos: { id: string, time: number } | null = null
  private lastWatchdogTime = 0
  private watchdogTimer: number | null = null
  private pendingCanPlay: (() => void) | null = null
  private pageTitle: string | null = null
  private randomStartPending = false

  connect (): void {
    this.wire()
    if (this.audioTarget.volume === 1 && !this.currentTrack) {
      this.audioTarget.volume = 0.7
    }
  }

  // Every add is remove-then-add so connect() re-firing after a Turbo
  // transplant can never stack duplicate handlers.
  private wire (): void {
    const audio = this.audioTarget
    audio.removeEventListener('timeupdate', this.onTimeUpdate)
    audio.addEventListener('timeupdate', this.onTimeUpdate)
    audio.removeEventListener('loadedmetadata', this.onLoadedMetadata)
    audio.addEventListener('loadedmetadata', this.onLoadedMetadata)
    audio.removeEventListener('ended', this.onEnded)
    audio.addEventListener('ended', this.onEnded)
    audio.removeEventListener('stalled', this.onStalled)
    audio.addEventListener('stalled', this.onStalled)
    audio.removeEventListener('waiting', this.onWaiting)
    audio.addEventListener('waiting', this.onWaiting)
    audio.removeEventListener('error', this.onError)
    audio.addEventListener('error', this.onError)
    audio.removeEventListener('pause', this.onPause)
    audio.addEventListener('pause', this.onPause)

    document.removeEventListener('keydown', this.onKeyDown)
    document.addEventListener('keydown', this.onKeyDown)
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
    document.addEventListener('mousedown', this.onDocumentMouseDown)
    document.removeEventListener('player:load-track', this.onLoadTrackEvent as EventListener)
    document.addEventListener('player:load-track', this.onLoadTrackEvent as EventListener)
    document.removeEventListener('player:toggle', this.onToggleEvent)
    document.addEventListener('player:toggle', this.onToggleEvent)
    document.removeEventListener('turbo:load', this.onTurboLoad)
    document.addEventListener('turbo:load', this.onTurboLoad)
  }

  // --- inbound events ------------------------------------------------

  private readonly onLoadTrackEvent = (event: CustomEvent<LoadTrackDetail>): void => {
    const { track, playlist, station, randomStart } = event.detail
    if (playlist) this.playlist = playlist
    // Switching from a radio station back to on-demand tracks turns
    // shuffle off (ported from TrackTable's wasPlayingRadio check);
    // stations themselves always play shuffled (RadioPage behavior).
    if (this.station && !station && this.shuffle) this.shuffle = false
    if (station) this.shuffle = true
    this.updateShuffleButton()
    this.station = station ?? null
    this.randomStartPending = randomStart === true
    this.loadTrack(track)
  }

  private readonly onToggleEvent = (): void => {
    this.togglePlayPause()
  }

  private readonly onTurboLoad = (): void => {
    // The new page replaced document.title; adopt it as the restore
    // point, reassert the playing title, and let freshly-rendered track
    // lists repaint their highlights.
    this.pageTitle = null
    this.updateDocumentTitle()
    this.dispatchState()
  }

  // --- core playback -------------------------------------------------

  loadTrack (track: PlayerTrack): void {
    const audio = this.audioTarget

    audio.pause()
    this.setPlaying(false)

    this.currentTrack = track
    this.barTarget.hidden = false
    this.updateNowPlaying(track.id)
    this.renderTrackInfo()

    if (this.shuffle) this.shuffledPlaylist = this.generateShuffledPlaylist()

    if (this.pendingCanPlay) audio.removeEventListener('canplay', this.pendingCanPlay)
    audio.src = track.url
    audio.load()

    const onCanPlay = (): void => {
      audio.removeEventListener('canplay', onCanPlay)
      this.pendingCanPlay = null
      audio.play()
        .then(() => this.setPlaying(true))
        .catch((error) => {
          console.error('Playback failed:', error)
          this.setPlaying(false)
        })
    }
    this.pendingCanPlay = onCanPlay
    audio.addEventListener('canplay', onCanPlay)

    this.renderQueue()
  }

  togglePlayPause (): void {
    if (!this.currentTrack) return
    const audio = this.audioTarget

    if (this.playing) {
      audio.pause()
      this.setPlaying(false)
      this.updateOverlayPaused(true)
    } else {
      audio.play().catch((error) => {
        console.error('Playback failed:', error)
        this.setPlaying(false)
      })
      this.setPlaying(true)
      this.updateOverlayPaused(false)
    }
  }

  next (): void {
    this.step(1)
  }

  previous (): void {
    this.step(-1)
  }

  private step (direction: 1 | -1): void {
    const playlist = this.effectivePlaylist()
    if (playlist.length === 0) return

    const currentIndex = playlist.findIndex((t) => t.id === this.currentTrack?.id)
    let index: number
    if (direction === 1) {
      index = (currentIndex + 1) % playlist.length
    } else {
      index = currentIndex <= 0 ? playlist.length - 1 : currentIndex - 1
    }
    const next = playlist[index]
    if (next) this.loadTrack(next)
  }

  toggleShuffle (): void {
    this.shuffle = !this.shuffle
    if (this.shuffle) this.shuffledPlaylist = this.generateShuffledPlaylist()
    this.updateShuffleButton()
    this.renderQueue()
  }

  private updateShuffleButton (): void {
    this.shuffleButtonTarget.classList.toggle('player-btn--active', this.shuffle)
    this.shuffleButtonTarget.title = this.shuffle ? 'Shuffle: On' : 'Shuffle: Off'
  }

  close (): void {
    this.audioTarget.pause()
    this.stopWatchdog()
    this.barTarget.hidden = true
    this.setPlaying(false)
    this.currentTrack = null
    this.updateNowPlaying(null)
    this.dispatchState()
  }

  private effectivePlaylist (): PlayerTrack[] {
    return this.shuffle ? this.shuffledPlaylist : this.playlist
  }

  private generateShuffledPlaylist (): PlayerTrack[] {
    const playlist = this.playlist
    if (playlist.length === 0) return []
    if (!this.currentTrack) return this.shuffleArray(playlist)

    const current = playlist.find((t) => t.id === this.currentTrack?.id)
    if (!current) return this.shuffleArray(playlist)

    const others = playlist.filter((t) => t.id !== current.id)
    return [current, ...this.shuffleArray(others)]
  }

  private shuffleArray (array: PlayerTrack[]): PlayerTrack[] {
    const shuffled = [...array]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const a = shuffled[i]
      const b = shuffled[j]
      if (a !== undefined && b !== undefined) {
        shuffled[i] = b
        shuffled[j] = a
      }
    }
    return shuffled
  }

  private setPlaying (playing: boolean): void {
    this.playing = playing
    this.playPauseTarget.textContent = playing ? '❚❚ PAUSE' : '► PLAY'
    this.playPauseTarget.dataset.playing = playing ? 'true' : 'false'
    if (playing) this.startWatchdog(); else this.stopWatchdog()
    this.updateDocumentTitle()
    this.dispatchState()
  }

  private dispatchState (): void {
    document.dispatchEvent(new CustomEvent('player:state', {
      detail: {
        trackId: this.currentTrack?.id ?? null,
        playing: this.playing,
        stationId: this.station?.id ?? null
      }
    }))
  }

  // Unlike the SPA (one global title), each Hotwire page owns its <title>.
  // While playing we override it with the track; on pause/close we restore
  // the page's own title instead of the SPA's static 'hackr.tv'.
  private updateDocumentTitle (): void {
    if (this.playing && this.currentTrack) {
      if (this.pageTitle === null) this.pageTitle = document.title
      document.title = this.station
        ? `${this.station.name} | hackr.tv`
        : `${this.currentTrack.title} — ${this.currentTrack.artist} | hackr.tv`
    } else if (this.pageTitle !== null) {
      document.title = this.pageTitle
      this.pageTitle = null
    }
  }

  // --- bar rendering -------------------------------------------------

  private renderTrackInfo (): void {
    const track = this.currentTrack
    if (!track) return

    this.titleTarget.textContent = track.title
    this.artistTarget.textContent = track.artist

    if (track.coverUrl) {
      this.coverTarget.hidden = false
      this.coverImgTarget.src = track.coverThumbUrl || track.coverUrl
      this.coverOverlayImgTarget.src = track.coverFullUrl || track.coverUrl
    } else {
      this.coverTarget.hidden = true
    }

    const inStation = this.station !== null
    this.stationTarget.hidden = !inStation
    this.stationNameTarget.textContent = this.station?.name ?? ''
    this.controlsTarget.hidden = inStation
    this.seekBarTarget.disabled = inStation
    this.seekBarTarget.classList.toggle('player-seek--disabled', inStation)

    if (this.hasAddToPlaylistTarget) {
      this.addToPlaylistTarget.setAttribute('data-add-to-playlist-track-id-value', track.id)
      this.addToPlaylistTarget.setAttribute('data-add-to-playlist-track-title-value', track.title)
    }
  }

  showCoverOverlay (): void {
    this.coverOverlayTarget.hidden = false
  }

  hideCoverOverlay (): void {
    this.coverOverlayTarget.hidden = true
  }

  // --- seek / volume -------------------------------------------------

  seekStart (): void {
    if (this.station) return
    this.seeking = true
  }

  seekInput (): void {
    if (this.station) return
    const audio = this.audioTarget
    const time = (Number(this.seekBarTarget.value) / 100) * (audio.duration || 0)
    audio.currentTime = time
    this.currentTimeTarget.textContent = this.formatTime(time)
  }

  seekEnd (): void {
    if (this.station) return
    this.seeking = false
  }

  volumeInput (event: Event): void {
    const input = event.currentTarget as HTMLInputElement
    this.audioTarget.volume = Number(input.value) / 100
  }

  private formatTime (seconds: number): string {
    if (!seconds || isNaN(seconds)) return '0:00'
    const mins = Math.floor(seconds / 60)
    const secs = Math.floor(seconds % 60)
    return `${mins}:${secs.toString().padStart(2, '0')}`
  }

  // --- queue panel ---------------------------------------------------

  toggleQueue (): void {
    this.queuePanelTarget.hidden = !this.queuePanelTarget.hidden
    this.queueToggleTarget.classList.toggle('player-btn--active', !this.queuePanelTarget.hidden)
    if (!this.queuePanelTarget.hidden) this.renderQueue()
  }

  closeQueue (): void {
    this.queuePanelTarget.hidden = true
    this.queueToggleTarget.classList.remove('player-btn--active')
  }

  private readonly onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.queuePanelTarget.hidden) return
    if (!this.queueTarget.contains(event.target as Node)) this.closeQueue()
  }

  queueItemClicked (event: Event): void {
    if (this.station) return
    const item = (event.currentTarget as HTMLElement)
    const index = Number(item.dataset.queueIndex)
    const track = this.effectivePlaylist()[index]
    if (track) this.loadTrack(track)
  }

  // Current track + up to the next 3, cloned from the item template —
  // replaces PlayerBar's 500ms getEffectivePlaylist() polling.
  private renderQueue (): void {
    const playlist = this.effectivePlaylist()
    this.queueCountTarget.textContent = this.station ? '' : ` (${playlist.length})`

    const list = this.queueListTarget
    list.textContent = ''

    if (playlist.length === 0) {
      this.queueMoreTarget.hidden = true
      list.innerHTML = '<div class="player-queue-empty">No tracks in queue</div>'
      return
    }

    const currentIndex = playlist.findIndex((t) => t.id === this.currentTrack?.id)
    const entries: Array<{ track: PlayerTrack, index: number, current: boolean }> = []
    const current = playlist[currentIndex]

    if (current) {
      entries.push({ track: current, index: currentIndex, current: true })
      for (let i = 1; i <= 3; i++) {
        const nextIndex = (currentIndex + i) % playlist.length
        const next = playlist[nextIndex]
        if (next && (nextIndex !== currentIndex || playlist.length === 1)) {
          entries.push({ track: next, index: nextIndex, current: false })
        }
        if (nextIndex === currentIndex) break
      }
    }

    for (const entry of entries) {
      const node = this.queueItemTemplateTarget.content.cloneNode(true) as DocumentFragment
      const item = node.querySelector('.player-queue-item') as HTMLElement
      item.dataset.queueIndex = String(entry.index)
      item.classList.toggle('player-queue-item--current', entry.current)
      item.classList.toggle('player-queue-item--station', this.station !== null && !entry.current)

      const img = item.querySelector('.player-queue-item__cover') as HTMLImageElement
      if (entry.track.coverUrl) {
        img.src = entry.track.coverThumbUrl || entry.track.coverUrl
        img.alt = entry.track.title
      } else {
        img.remove()
      }

      ;(item.querySelector('.player-queue-item__title') as HTMLElement).textContent = entry.track.title
      ;(item.querySelector('.player-queue-item__artist') as HTMLElement).textContent = entry.track.artist
      ;(item.querySelector('.player-queue-item__marker') as HTMLElement).hidden = !entry.current
      ;(item.querySelector('.player-queue-item__badge-current') as HTMLElement).hidden = !entry.current
      ;(item.querySelector('.player-queue-item__badge-next') as HTMLElement).hidden = entry.current || this.station !== null

      list.appendChild(node)
    }

    const remaining = playlist.length - Math.min(4, entries.length)
    this.queueMoreTarget.hidden = this.station !== null || playlist.length <= 4
    if (remaining > 0) {
      this.queueMoreTarget.textContent = `+ ${remaining} more tracks in queue`
    }
  }

  // --- audio element handlers ----------------------------------------

  private readonly onTimeUpdate = (): void => {
    const audio = this.audioTarget
    if (!this.seeking) {
      this.currentTimeTarget.textContent = this.formatTime(audio.currentTime)
      if (audio.duration > 0) {
        this.seekBarTarget.value = String((audio.currentTime / audio.duration) * 100)
      }
    }

    // Play credit: accumulate only small forward steps (< 2s between
    // samples) so seeking past the 30s mark never awards credit.
    const track = this.currentTrack
    if (track && !this.creditedTrackIds.has(track.id)) {
      const last = this.lastPlaybackPos
      const now = audio.currentTime
      if (last && last.id === track.id) {
        const delta = now - last.time
        if (delta > 0 && delta < 2) {
          const accumulated = (this.playedSecondsByTrack.get(track.id) || 0) + delta
          this.playedSecondsByTrack.set(track.id, accumulated)
          if (accumulated >= PLAY_CREDIT_SECONDS) {
            this.creditedTrackIds.add(track.id)
            fetch(`/api/tracks/${encodeURIComponent(track.id)}/play_credit`, { method: 'POST' })
              .catch((err) => console.warn('play_credit failed:', err))
          }
        }
      }
      this.lastPlaybackPos = { id: track.id, time: now }
    }
  }

  private readonly onLoadedMetadata = (): void => {
    const audio = this.audioTarget
    this.durationTarget.textContent = this.formatTime(audio.duration)
    if (this.randomStartPending) {
      this.randomStartPending = false
      if (audio.duration && !isNaN(audio.duration)) {
        audio.currentTime = Math.random() * audio.duration * 0.7
      }
    }
  }

  private readonly onEnded = (): void => {
    this.setPlaying(false)
    const playlist = this.effectivePlaylist()
    if (playlist.length === 0) return

    const currentIndex = playlist.findIndex((t) => t.id === this.currentTrack?.id)
    const next = playlist[(currentIndex + 1) % playlist.length]
    if (next) this.loadTrack(next)
  }

  // Normal during buffering; the watchdog handles truly stuck playback.
  private readonly onStalled = (): void => {
    console.warn('Audio playback stalled — browser is rebuffering, waiting for data...')
  }

  private readonly onWaiting = (): void => {
    console.log('Audio waiting for data...')
  }

  private readonly onError = (): void => {
    const audio = this.audioTarget
    const error = audio.error
    if (!error) return
    console.error('Audio error:', error.code, error.message)
    // MEDIA_ERR_NETWORK: reload and resume from the same position.
    if (error.code === 2) {
      const currentPos = audio.currentTime
      setTimeout(() => {
        console.log('Attempting to recover from network error...')
        audio.load()
        audio.currentTime = currentPos
        if (this.playing) {
          audio.play().catch((err) => {
            console.error('Failed to resume after network error:', err)
          })
        }
      }, 1000)
    }
  }

  // Browser-intervention pauses (tab backgrounded): try to resume.
  private readonly onPause = (): void => {
    const audio = this.audioTarget
    if (this.playing && !audio.ended) {
      setTimeout(() => {
        if (this.playing && audio.paused && !audio.ended) {
          console.log('Detected unexpected pause, attempting to resume...')
          audio.play().catch((error) => {
            console.warn('Could not auto-resume:', error)
            this.setPlaying(false)
          })
        }
      }, 100)
    }
  }

  private readonly onKeyDown = (event: KeyboardEvent): void => {
    if (
      event.key === ' ' &&
      this.currentTrack &&
      !(event.target instanceof HTMLInputElement) &&
      !(event.target instanceof HTMLTextAreaElement)
    ) {
      event.preventDefault()
      this.togglePlayPause()
    }
  }

  // --- stall watchdog ------------------------------------------------

  // Catches silently-stuck playback (connection timeouts that fire no
  // events). The timer intentionally survives Turbo visits — disconnect()
  // does not clear it; only pause/close/ended do.
  private startWatchdog (): void {
    if (this.watchdogTimer !== null) return
    this.lastWatchdogTime = this.audioTarget.currentTime
    this.watchdogTimer = window.setInterval(() => {
      const audio = this.audioTarget
      if (this.playing && !audio.paused && !audio.ended) {
        const currentPos = audio.currentTime
        const timeDiff = currentPos - this.lastWatchdogTime
        if (timeDiff <= 0 && currentPos < (audio.duration || 0) - 1) {
          console.warn('Watchdog: Playback appears stalled, attempting recovery...')
          audio.load()
          audio.currentTime = currentPos
          audio.play().catch((error) => {
            console.error('Watchdog: Failed to resume playback:', error)
            this.setPlaying(false)
          })
        }
        this.lastWatchdogTime = currentPos
      }
    }, WATCHDOG_INTERVAL_MS)
  }

  private stopWatchdog (): void {
    if (this.watchdogTimer !== null) {
      window.clearInterval(this.watchdogTimer)
      this.watchdogTimer = null
    }
  }

  // --- overlay integration (unchanged contract — HUD/OBS depend on it)

  private updateNowPlaying (trackId: string | null, paused = false): void {
    const body = trackId ? { track_id: trackId, paused } : { clear: true }
    fetch('/api/overlay/now-playing', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).catch((err) => console.warn('Failed to update overlay now playing:', err))
  }

  private updateOverlayPaused (paused: boolean): void {
    fetch('/api/overlay/now-playing', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ paused })
    }).catch((err) => console.warn('Failed to update overlay paused state:', err))
  }
}
