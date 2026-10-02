import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import RadioStationController from './radio_station_controller'

// Fixture mirrors radio/_station_card.html.erb's playlist-backed card.

const FIXTURE = `
  <div data-controller="radio-station"
       data-radio-station-station-id-value="3"
       data-radio-station-station-name-value="PULSE FM">
    <button data-radio-station-target="button" data-action="radio-station#play">▶ PLAY STATION</button>
  </div>`

const PLAYLISTS = [
  {
    tracks: [
      { track_id: 1, audio_url: '/a1.mp3', title: 'One', artist: { name: 'A' }, release: { cover_url: '/c1.jpg' } },
      { track_id: 2, audio_url: null, title: 'Broken', artist: { name: 'A' } }
    ]
  },
  { tracks: [{ track_id: 3, audio_url: '/a3.mp3', title: 'Three', artist: { name: 'B' } }] },
  {}
]

describe('RadioStationController', () => {
  let application: Application
  let fetchMock: ReturnType<typeof vi.fn>
  let loads: CustomEvent[]
  let toggles: number
  const onLoad = ((e: CustomEvent) => loads.push(e)) as unknown as EventListener
  const onToggle = (() => { toggles++ }) as EventListener

  const button = (): HTMLButtonElement => document.querySelector('[data-radio-station-target="button"]')!

  function playerState (detail: { trackId: string | null, playing: boolean, stationId: number | null }): void {
    document.dispatchEvent(new CustomEvent('player:state', { detail }))
  }

  async function settle (): Promise<void> {
    await Promise.resolve()
    await Promise.resolve()
  }

  beforeEach(async () => {
    loads = []
    toggles = 0
    fetchMock = vi.fn().mockResolvedValue({ ok: true, json: async () => PLAYLISTS })
    vi.stubGlobal('fetch', fetchMock)
    document.addEventListener('player:load-track', onLoad)
    document.addEventListener('player:toggle', onToggle)
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('radio-station', RadioStationController)
    await settle()
  })

  afterEach(async () => {
    document.removeEventListener('player:load-track', onLoad)
    document.removeEventListener('player:toggle', onToggle)
    document.body.innerHTML = ''
    await Promise.resolve()
    application.stop()
    document.head.querySelector('meta[name="current-hackr-id"]')?.remove()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('flattens station playlists into a queue, skipping unplayable tracks', async () => {
    button().click()
    await settle()

    expect(fetchMock).toHaveBeenCalledWith('/api/radio_stations/3/playlists')
    expect(loads).toHaveLength(1)
    const detail = loads[0]!.detail
    expect(detail.playlist.map((t: { id: string }) => t.id)).toEqual(['1', '3'])
    expect(detail.station).toEqual({ id: 3, name: 'PULSE FM' })
    expect(detail.randomStart).toBe(true)
    expect(['1', '3']).toContain(detail.track.id)
  })

  it('toggles the player instead of re-fetching when already the current station', async () => {
    playerState({ trackId: '1', playing: true, stationId: 3 })
    button().click()
    await settle()

    expect(toggles).toBe(1)
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('repaints the button from player state', () => {
    playerState({ trackId: '1', playing: true, stationId: 3 })
    expect(button().textContent).toBe('❚❚ PAUSE')
    expect(button().classList.contains('tune-in-btn--current')).toBe(true)

    playerState({ trackId: '1', playing: false, stationId: 3 })
    expect(button().textContent).toBe('▶ RESUME')

    playerState({ trackId: '9', playing: true, stationId: 8 })
    expect(button().textContent).toBe('▶ PLAY STATION')
    expect(button().classList.contains('tune-in-btn--current')).toBe(false)
  })

  it('credits the tune-in once, only when logged in and confirmed playing', () => {
    // Logged out: no credit
    playerState({ trackId: '1', playing: true, stationId: 3 })
    expect(fetchMock).not.toHaveBeenCalled()

    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    document.head.appendChild(meta)

    // Current but paused: no credit
    playerState({ trackId: '1', playing: false, stationId: 3 })
    expect(fetchMock).not.toHaveBeenCalled()

    playerState({ trackId: '1', playing: true, stationId: 3 })
    expect(fetchMock).toHaveBeenCalledWith('/api/radio_stations/3/tune_in', { method: 'POST' })

    // Replays don't re-credit
    playerState({ trackId: '2', playing: true, stationId: 3 })
    expect(fetchMock).toHaveBeenCalledTimes(1)
  })

  it('alerts when the station has no playable tracks', async () => {
    fetchMock.mockResolvedValue({ ok: true, json: async () => [{ tracks: [] }] })
    const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})

    button().click()
    await settle()

    expect(alertSpy).toHaveBeenCalledWith('No playable tracks found in station playlists.')
    expect(loads).toHaveLength(0)
  })
})
