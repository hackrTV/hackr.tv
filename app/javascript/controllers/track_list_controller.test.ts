import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import TrackListController from './track_list_controller'

// Fixture mirrors shared/_track_table.html.erb rows (PlayerHelper
// #player_track_attrs data-* contract). Player interplay is covered by
// player_controller.test.ts; this suite covers the list's own logic:
// filtering, queue assembly, repaint, and the context menu.

let matchMediaMatches = false
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query: string) => ({
    matches: matchMediaMatches,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
})

function row (id: string, title: string, opts: { set?: string, url?: string | null, search?: string } = {}): string {
  const url = opts.url === null ? '' : `data-player-url="${opts.url ?? `/audio/${id}.mp3`}"`
  const set = opts.set ? `data-track-set="${opts.set}"` : ''
  return `
    <tr class="track-row" data-player-id="${id}" ${url} data-player-title="${title}"
        data-player-artist="Artist" data-search-text="${opts.search ?? title.toLowerCase()}" ${set}
        data-action="click->track-list#rowClicked contextmenu->track-list#rowContextMenu">
      <td><span class="track-row__marker" hidden>▶</span>${title}
        <button class="play-track-btn">► PLAY</button></td>
    </tr>`
}

const FIXTURE = `
  <div data-controller="track-list">
    <input data-track-list-target="filter" data-action="input->track-list#filterChanged">
    <span data-track-list-target="count">3</span>
    <button id="play-all" data-action="track-list#playAll">▶ Play</button>
    <table><tbody>
      ${row('1', 'Alpha Signal')}
      ${row('2', 'Beta Signal')}
      ${row('3', 'Gamma Noise')}
      ${row('4', 'No Audio', { url: null })}
    </tbody></table>
  </div>`

describe('TrackListController', () => {
  let application: Application
  let events: CustomEvent[]
  const capture = ((e: CustomEvent) => events.push(e)) as unknown as EventListener

  function start (html = FIXTURE): void {
    document.body.innerHTML = html
    application = Application.start()
    application.register('track-list', TrackListController)
  }

  function rows (): HTMLElement[] {
    return Array.from(document.querySelectorAll<HTMLElement>('.track-row'))
  }

  beforeEach(() => {
    matchMediaMatches = false
    events = []
    document.addEventListener('player:load-track', capture)
    document.addEventListener('player:toggle', capture)
  })

  afterEach(async () => {
    document.removeEventListener('player:load-track', capture)
    document.removeEventListener('player:toggle', capture)
    document.body.innerHTML = ''
    await Promise.resolve()
    application?.stop()
    document.head.querySelector('meta[name="current-hackr-id"]')?.remove()
    document.querySelectorAll('.track-context-menu').forEach((m) => m.remove())
    vi.restoreAllMocks()
  })

  it('filters rows by search text and updates the count', async () => {
    start()
    await Promise.resolve()

    const filter = document.querySelector<HTMLInputElement>('[data-track-list-target="filter"]')!
    filter.value = 'signal'
    filter.dispatchEvent(new Event('input'))

    expect(rows().map((r) => r.hidden)).toEqual([false, false, true, true])
    expect(document.querySelector('[data-track-list-target="count"]')!.textContent).toBe('2')

    filter.value = ''
    filter.dispatchEvent(new Event('input'))
    expect(rows().every((r) => !r.hidden)).toBe(true)
  })

  it('loads a clicked track with the visible playable rows as queue', async () => {
    start()
    await Promise.resolve()

    rows()[0]!.click()

    expect(events).toHaveLength(1)
    const detail = events[0]!.detail
    expect(detail.track.id).toBe('1')
    expect(detail.station).toBeNull()
    // Row 4 has no audio url — excluded from the queue
    expect(detail.playlist.map((t: { id: string }) => t.id)).toEqual(['1', '2', '3'])
  })

  it('scopes the queue to rows passing the active filter', async () => {
    start()
    await Promise.resolve()

    const filter = document.querySelector<HTMLInputElement>('[data-track-list-target="filter"]')!
    filter.value = 'signal'
    filter.dispatchEvent(new Event('input'))
    rows()[0]!.click()

    expect(events[0]!.detail.playlist.map((t: { id: string }) => t.id)).toEqual(['1', '2'])
  })

  it('toggles instead of reloading when the current track row is clicked', async () => {
    start()
    await Promise.resolve()

    document.dispatchEvent(new CustomEvent('player:state', {
      detail: { trackId: '2', playing: true, stationId: null }
    }))
    rows()[1]!.click()

    expect(events).toHaveLength(1)
    expect(events[0]!.type).toBe('player:toggle')
  })

  it('selects the desktop/mobile row set for the queue', async () => {
    start(`
      <div data-controller="track-list">
        <table><tbody>
          ${row('1', 'Desktop One', { set: 'desktop' })}
          ${row('1m', 'Mobile One', { set: 'mobile' })}
          ${row('2', 'Unmarked')}
        </tbody></table>
      </div>`)
    await Promise.resolve()

    rows()[2]!.click()
    expect(events[0]!.detail.playlist.map((t: { id: string }) => t.id)).toEqual(['1', '2'])

    matchMediaMatches = true
    rows()[2]!.click()
    expect(events[1]!.detail.playlist.map((t: { id: string }) => t.id)).toEqual(['1m', '2'])
  })

  it('playAll queues visible rows starting on the first; alerts when none', async () => {
    start()
    await Promise.resolve()

    document.getElementById('play-all')!.click()
    expect(events[0]!.detail.track.id).toBe('1')

    const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
    const filter = document.querySelector<HTMLInputElement>('[data-track-list-target="filter"]')!
    filter.value = 'zzz-no-match'
    filter.dispatchEvent(new Event('input'))
    document.getElementById('play-all')!.click()

    expect(alertSpy).toHaveBeenCalledWith('No playable tracks in this playlist')
    expect(events).toHaveLength(1)
  })

  it('repaints highlights and buttons from player:state events', async () => {
    start()
    await Promise.resolve()

    document.dispatchEvent(new CustomEvent('player:state', {
      detail: { trackId: '1', playing: true, stationId: null }
    }))

    const first = rows()[0]!
    expect(first.classList.contains('track-row--active')).toBe(true)
    expect(first.querySelector<HTMLElement>('.track-row__marker')!.hidden).toBe(false)
    expect(first.querySelector('.play-track-btn')!.textContent).toBe('❚❚ PAUSE')
    expect(rows()[1]!.classList.contains('track-row--active')).toBe(false)

    document.dispatchEvent(new CustomEvent('player:state', {
      detail: { trackId: '1', playing: false, stationId: null }
    }))
    expect(first.classList.contains('track-row--active')).toBe(false)
    expect(first.querySelector('.play-track-btn')!.textContent).toBe('► PLAY')
  })

  it('opens a context menu with play/artist/copy items, no playlist section logged out', async () => {
    start()
    await Promise.resolve()

    rows()[0]!.dispatchEvent(new MouseEvent('contextmenu', { bubbles: true, clientX: 10, clientY: 10 }))

    const menu = document.querySelector('.track-context-menu')!
    const labels = Array.from(menu.querySelectorAll('.track-context-menu__item')).map((i) => i.textContent)
    expect(labels).toEqual([expect.stringContaining('Play "Alpha Signal"'), expect.stringContaining('Go to Artist'), expect.stringContaining('Copy Track Title')])
    expect(menu.querySelector('.track-context-menu__header')).toBeNull()
  })

  it('shows the playlist section when logged in and closes on outside mousedown', async () => {
    const meta = document.createElement('meta')
    meta.name = 'current-hackr-id'
    document.head.appendChild(meta)
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => [{ id: 7, name: 'Mix' }]
    })
    vi.stubGlobal('fetch', fetchMock)

    start()
    await Promise.resolve()

    rows()[0]!.dispatchEvent(new MouseEvent('contextmenu', { bubbles: true, clientX: 10, clientY: 10 }))
    await Promise.resolve()
    await Promise.resolve()

    const menu = document.querySelector('.track-context-menu')!
    expect(fetchMock).toHaveBeenCalledWith('/api/playlists')
    expect(menu.querySelector('.track-context-menu__header')!.textContent).toBe('Add to Playlist')
    expect(menu.querySelector('.track-context-menu__playlists')!.textContent).toContain('Mix')

    document.body.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
    expect(document.querySelector('.track-context-menu')).toBeNull()
    vi.unstubAllGlobals()
  })
})
