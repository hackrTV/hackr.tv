import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PlayerController from './player_controller'
import TrackListController from './track_list_controller'

// Ported from AudioPlayer.test.tsx (14 base + playback-recovery cases),
// re-targeted at the Stimulus player + track-list pair. The DOM fixture
// mirrors shared/_player_bar.html.erb and shared/_track_table.html.erb —
// if a target is renamed there, rename it here.

const MEDIA_ERR_NETWORK = 2
const MEDIA_ERR_DECODE = 3

Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
})

const PLAYER_BAR_HTML = `
  <div id="player-bar" data-controller="player">
    <audio data-player-target="audio" id="audio-element" hidden></audio>
    <div class="player-bar" data-player-target="bar" hidden>
      <div class="player-cover" data-player-target="cover" hidden>
        <img data-player-target="coverImg">
      </div>
      <div class="player-cover-overlay" data-player-target="coverOverlay" hidden>
        <img data-player-target="coverOverlayImg">
      </div>
      <button id="play-pause-btn" data-player-target="playPause" data-action="player#togglePlayPause">► PLAY</button>
      <span data-player-target="controls">
        <button data-action="player#previous">⏮</button>
        <button data-action="player#next">⏭</button>
        <button data-player-target="shuffleButton" data-action="player#toggleShuffle">⤮</button>
      </span>
      <div data-player-target="station" hidden><span data-player-target="stationName"></span></div>
      <span id="track-title" data-player-target="title">No track loaded</span>
      <span id="track-artist" data-player-target="artist">-</span>
      <span data-player-target="currentTime">0:00</span>
      <input type="range" data-player-target="seekBar" min="0" max="100" value="0"
             data-action="mousedown->player#seekStart input->player#seekInput mouseup->player#seekEnd">
      <span data-player-target="duration">0:00</span>
      <input type="range" id="volume-control" min="0" max="100" value="70" data-action="player#volumeInput">
      <div data-player-target="queue">
        <button data-player-target="queueToggle" data-action="player#toggleQueue">☰ Queue<span data-player-target="queueCount"></span></button>
        <div data-player-target="queuePanel" hidden>
          <div data-player-target="queueList"></div>
          <div data-player-target="queueMore" hidden></div>
        </div>
      </div>
      <button id="close-player-btn" data-action="player#close">✕</button>
    </div>
    <template data-player-target="queueItemTemplate">
      <div class="player-queue-item" data-action="click->player#queueItemClicked">
        <img class="player-queue-item__cover">
        <div class="player-queue-item__info">
          <div class="player-queue-item__title-row">
            <span class="player-queue-item__marker" hidden>▶</span>
            <span class="player-queue-item__title"></span>
          </div>
          <div class="player-queue-item__artist"></div>
        </div>
        <span class="player-queue-item__badge-current" hidden>NOW PLAYING</span>
        <span class="player-queue-item__badge-next" hidden>UP NEXT</span>
      </div>
    </template>
  </div>
`

function trackRow (id: string, title: string, artist: string): string {
  return `
    <tr class="track-row" data-player-id="${id}" data-player-url="https://example.com/${id}.mp3"
        data-player-title="${title}" data-player-artist="${artist}" data-player-cover=""
        data-search-text="${title.toLowerCase()} ${artist.toLowerCase()}"
        data-action="click->track-list#rowClicked contextmenu->track-list#rowContextMenu">
      <td><strong class="track-row__title"><span class="track-row__marker" hidden>► </span>${title}</strong></td>
      <td><button class="play-track-btn">► PLAY</button></td>
    </tr>
  `
}

const TRACK_TABLE_HTML = `
  <div data-controller="track-list">
    <input type="text" data-track-list-target="filter" data-action="input->track-list#filterChanged">
    <table><tbody>
      ${trackRow('track-1', 'Track 1', 'Artist 1')}
      ${trackRow('track-2', 'Track 2', 'Artist 2')}
      ${trackRow('track-3', 'Track 3', 'Artist 3')}
    </tbody></table>
  </div>
`

let application: Application

async function mountPlayer (withTracks = true): Promise<void> {
  document.body.innerHTML = PLAYER_BAR_HTML + (withTracks ? TRACK_TABLE_HTML : '')
  application = Application.start()
  application.register('player', PlayerController)
  application.register('track-list', TrackListController)
  await Promise.resolve()
}

function audio (): HTMLAudioElement {
  return document.getElementById('audio-element') as HTMLAudioElement
}

function bar (): HTMLElement {
  return document.querySelector('.player-bar') as HTMLElement
}

function playPauseButton (): HTMLButtonElement {
  return document.getElementById('play-pause-btn') as HTMLButtonElement
}

function row (id: string): HTMLElement {
  return document.querySelector(`.track-row[data-player-id="${id}"]`) as HTMLElement
}

function loadTrackEvent (id: string): void {
  const rows = Array.from(document.querySelectorAll<HTMLElement>('.track-row'))
  const playlist = rows.map((r) => ({
    id: r.dataset.playerId || '',
    url: r.dataset.playerUrl || '',
    title: r.dataset.playerTitle || '',
    artist: r.dataset.playerArtist || '',
    coverUrl: '',
    coverThumbUrl: '',
    coverFullUrl: ''
  }))
  const track = playlist.find((t) => t.id === id)
  document.dispatchEvent(new CustomEvent('player:load-track', { detail: { track, playlist, station: null } }))
}

async function flushCanPlay (): Promise<void> {
  // setup.ts's load() mock dispatches canplay on a 0ms timeout.
  await new Promise((resolve) => setTimeout(resolve, 5))
}

describe('player controller', () => {
  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({})
    } as Response))
  })

  afterEach(() => {
    application?.stop()
    vi.unstubAllGlobals()
    vi.useRealTimers()
    document.body.innerHTML = ''
  })

  it('renders the audio element and hides the bar initially', async () => {
    await mountPlayer()
    expect(audio()).not.toBeNull()
    expect(bar().hidden).toBe(true)
  })

  it('loads a track, shows the bar, and sets track info', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    expect(bar().hidden).toBe(false)
    expect(audio().src).toBe('https://example.com/track-1.mp3')
    expect(document.getElementById('track-title')?.textContent).toBe('Track 1')
    expect(document.getElementById('track-artist')?.textContent).toBe('Artist 1')
  })

  it('POSTs overlay now-playing on load', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    expect(fetch).toHaveBeenCalledWith('/api/overlay/now-playing', expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({ track_id: 'track-1', paused: false })
    }))
  })

  it('toggles play/pause and reports paused state to the overlay', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()
    expect(playPauseButton().textContent).toBe('❚❚ PAUSE')

    playPauseButton().click()
    expect(playPauseButton().textContent).toBe('► PLAY')
    expect(fetch).toHaveBeenCalledWith('/api/overlay/now-playing', expect.objectContaining({
      body: JSON.stringify({ paused: true })
    }))

    playPauseButton().click()
    expect(playPauseButton().textContent).toBe('❚❚ PAUSE')
  })

  it('toggles playback on spacebar when a track is loaded', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()
    expect(playPauseButton().textContent).toBe('❚❚ PAUSE')

    document.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }))
    expect(playPauseButton().textContent).toBe('► PLAY')
  })

  it('ignores spacebar while typing in an input', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    const input = document.querySelector('[data-track-list-target="filter"]') as HTMLInputElement
    const event = new KeyboardEvent('keydown', { key: ' ', bubbles: true })
    Object.defineProperty(event, 'target', { value: input })
    document.dispatchEvent(event)
    expect(playPauseButton().textContent).toBe('❚❚ PAUSE')
  })

  it('does nothing on spacebar with no track loaded', async () => {
    await mountPlayer()
    document.dispatchEvent(new KeyboardEvent('keydown', { key: ' ' }))
    expect(bar().hidden).toBe(true)
  })

  it('sets initial volume to 70%', async () => {
    await mountPlayer()
    expect(audio().volume).toBeCloseTo(0.7)
  })

  it('changes volume from the slider', async () => {
    await mountPlayer()
    const slider = document.getElementById('volume-control') as HTMLInputElement
    slider.value = '30'
    slider.dispatchEvent(new Event('input', { bubbles: true }))
    expect(audio().volume).toBeCloseTo(0.3)
  })

  it('seeks relative to duration', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    Object.defineProperty(audio(), 'duration', { configurable: true, value: 200 })
    const seekBar = document.querySelector('[data-player-target="seekBar"]') as HTMLInputElement
    seekBar.value = '50'
    seekBar.dispatchEvent(new Event('input', { bubbles: true }))
    expect(audio().currentTime).toBe(100)
  })

  it('closes the player, hides the bar, and clears the overlay', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    ;(document.getElementById('close-player-btn') as HTMLButtonElement).click()
    expect(bar().hidden).toBe(true)
    expect(fetch).toHaveBeenCalledWith('/api/overlay/now-playing', expect.objectContaining({
      body: JSON.stringify({ clear: true })
    }))
  })

  it('repaints track-list highlights from player:state', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    expect(row('track-1').classList.contains('track-row--active')).toBe(true)
    expect(row('track-1').querySelector<HTMLElement>('.track-row__marker')?.hidden).toBe(false)
    expect(row('track-1').querySelector('.play-track-btn')?.textContent).toBe('❚❚ PAUSE')
    expect(row('track-2').classList.contains('track-row--active')).toBe(false)
  })

  it('auto-plays the next track on ended', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    audio().dispatchEvent(new Event('ended'))
    await flushCanPlay()
    expect(audio().src).toBe('https://example.com/track-2.mp3')
    expect(document.getElementById('track-title')?.textContent).toBe('Track 2')
  })

  it('wraps to the first track after the last', async () => {
    await mountPlayer()
    loadTrackEvent('track-3')
    await flushCanPlay()

    audio().dispatchEvent(new Event('ended'))
    await flushCanPlay()
    expect(audio().src).toBe('https://example.com/track-1.mp3')
  })

  it('builds the queue from visible rows only (filter respected)', async () => {
    await mountPlayer()
    // Hide track-2 the way the filter does, then click track-1's row.
    row('track-2').hidden = true
    row('track-1').click()
    await flushCanPlay()

    audio().dispatchEvent(new Event('ended'))
    await flushCanPlay()
    expect(audio().src).toBe('https://example.com/track-3.mp3')
  })

  it('row click on the playing track toggles instead of restarting', async () => {
    await mountPlayer()
    row('track-1').click()
    await flushCanPlay()
    expect(playPauseButton().textContent).toBe('❚❚ PAUSE')

    row('track-1').click()
    expect(playPauseButton().textContent).toBe('► PLAY')
    expect(audio().src).toBe('https://example.com/track-1.mp3')
  })

  it('awards play credit after 30s of accumulated playback', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    for (let i = 0; i <= 31; i++) {
      Object.defineProperty(audio(), 'currentTime', { configurable: true, value: i, writable: true })
      audio().dispatchEvent(new Event('timeupdate'))
    }

    expect(fetch).toHaveBeenCalledWith('/api/tracks/track-1/play_credit', { method: 'POST' })
  })

  it('does not award play credit for seeking past the mark', async () => {
    await mountPlayer()
    loadTrackEvent('track-1')
    await flushCanPlay()

    Object.defineProperty(audio(), 'currentTime', { configurable: true, value: 0, writable: true })
    audio().dispatchEvent(new Event('timeupdate'))
    Object.defineProperty(audio(), 'currentTime', { configurable: true, value: 45, writable: true })
    audio().dispatchEvent(new Event('timeupdate'))

    expect(fetch).not.toHaveBeenCalledWith('/api/tracks/track-1/play_credit', { method: 'POST' })
  })

  describe('station context', () => {
    it('disables seek and hides prev/next, and station queue items are inert', async () => {
      await mountPlayer()
      const rows = [{
        id: 'track-1',
        url: 'https://example.com/track-1.mp3',
        title: 'Track 1',
        artist: 'Artist 1',
        coverUrl: '',
        coverThumbUrl: '',
        coverFullUrl: ''
      }]
      document.dispatchEvent(new CustomEvent('player:load-track', {
        detail: { track: rows[0], playlist: rows, station: { id: 9, name: 'Night Static' } }
      }))
      await flushCanPlay()

      const seekBar = document.querySelector('[data-player-target="seekBar"]') as HTMLInputElement
      expect(seekBar.disabled).toBe(true)
      expect((document.querySelector('[data-player-target="controls"]') as HTMLElement).hidden).toBe(true)
      expect((document.querySelector('[data-player-target="station"]') as HTMLElement).hidden).toBe(false)
      expect(document.querySelector('[data-player-target="stationName"]')?.textContent).toBe('Night Static')
    })
  })

  describe('playback recovery', () => {
    it('recovers from a network error by reloading after a delay', async () => {
      await mountPlayer()
      loadTrackEvent('track-1')
      await flushCanPlay()

      vi.useFakeTimers()
      const loadSpy = vi.spyOn(audio(), 'load')
      Object.defineProperty(audio(), 'error', {
        configurable: true,
        value: { code: MEDIA_ERR_NETWORK, message: 'network error' }
      })
      audio().dispatchEvent(new Event('error'))

      expect(loadSpy).not.toHaveBeenCalled()
      vi.advanceTimersByTime(1100)
      expect(loadSpy).toHaveBeenCalled()
    })

    it('does not attempt recovery for non-network errors', async () => {
      await mountPlayer()
      loadTrackEvent('track-1')
      await flushCanPlay()

      vi.useFakeTimers()
      const loadSpy = vi.spyOn(audio(), 'load')
      Object.defineProperty(audio(), 'error', {
        configurable: true,
        value: { code: MEDIA_ERR_DECODE, message: 'decode error' }
      })
      audio().dispatchEvent(new Event('error'))
      vi.advanceTimersByTime(2000)
      expect(loadSpy).not.toHaveBeenCalled()
    })

    it('attempts to resume after an unexpected pause', async () => {
      await mountPlayer()
      loadTrackEvent('track-1')
      await flushCanPlay()

      vi.useFakeTimers()
      const playSpy = vi.spyOn(audio(), 'play')
      Object.defineProperty(audio(), 'paused', { configurable: true, value: true })
      audio().dispatchEvent(new Event('pause'))
      vi.advanceTimersByTime(150)
      expect(playSpy).toHaveBeenCalled()
    })

    // The watchdog interval starts when playback starts, so both tests
    // pause first, switch to fake timers, then unpause — the restarted
    // interval is then driven by advanceTimersByTime.
    it('watchdog reloads when playback stops advancing', async () => {
      await mountPlayer()
      loadTrackEvent('track-1')
      await flushCanPlay()

      playPauseButton().click()
      vi.useFakeTimers()
      const loadSpy = vi.spyOn(audio(), 'load')
      Object.defineProperty(audio(), 'paused', { configurable: true, value: false })
      Object.defineProperty(audio(), 'ended', { configurable: true, value: false })
      Object.defineProperty(audio(), 'duration', { configurable: true, value: 200 })
      Object.defineProperty(audio(), 'currentTime', { configurable: true, value: 10, writable: true })
      playPauseButton().click()

      // Baseline recorded at start; the tick sees no progress → reload.
      vi.advanceTimersByTime(5100)
      expect(loadSpy).toHaveBeenCalled()
    })

    it('watchdog stays quiet while playback progresses', async () => {
      await mountPlayer()
      loadTrackEvent('track-1')
      await flushCanPlay()

      playPauseButton().click()
      vi.useFakeTimers()
      const loadSpy = vi.spyOn(audio(), 'load')
      Object.defineProperty(audio(), 'paused', { configurable: true, value: false })
      Object.defineProperty(audio(), 'ended', { configurable: true, value: false })
      Object.defineProperty(audio(), 'duration', { configurable: true, value: 200 })

      let time = 10
      Object.defineProperty(audio(), 'currentTime', {
        configurable: true,
        get: () => { time += 5; return time },
        set: () => {}
      })
      playPauseButton().click()
      vi.advanceTimersByTime(5100)
      vi.advanceTimersByTime(5100)
      expect(loadSpy).not.toHaveBeenCalled()
    })
  })
})
