import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import AddToPlaylistController from './add_to_playlist_controller'

// Fixture mirrors the "+ Playlist" block in shared/_player_bar.html.erb.

const FIXTURE = `
  <div data-controller="add-to-playlist"
       data-add-to-playlist-track-id-value="42"
       data-add-to-playlist-track-title-value="Alpha Signal">
    <button data-action="add-to-playlist#toggle">+ Playlist</button>
    <div data-add-to-playlist-target="panel" hidden>
      <span data-add-to-playlist-target="trackLabel"></span>
      <div data-add-to-playlist-target="message" hidden></div>
      <div data-add-to-playlist-target="list"></div>
      <form data-add-to-playlist-target="createForm" hidden data-action="submit->add-to-playlist#create">
        <input data-add-to-playlist-target="createName">
        <button type="submit">Create</button>
      </form>
      <button data-action="add-to-playlist#showCreate">+ Create New Playlist</button>
    </div>
  </div>
  <div id="outside"></div>`

describe('AddToPlaylistController', () => {
  let application: Application
  let fetchMock: ReturnType<typeof vi.fn>

  const panel = (): HTMLElement => document.querySelector('[data-add-to-playlist-target="panel"]')!
  const list = (): HTMLElement => document.querySelector('[data-add-to-playlist-target="list"]')!
  const message = (): HTMLElement => document.querySelector('[data-add-to-playlist-target="message"]')!
  const toggleButton = (): HTMLElement => document.querySelector('[data-action="add-to-playlist#toggle"]')!

  function jsonResponse (body: unknown, ok = true, status = 200): Response {
    return { ok, status, json: async () => body } as unknown as Response
  }

  async function settle (): Promise<void> {
    await Promise.resolve()
    await Promise.resolve()
    await Promise.resolve()
  }

  beforeEach(async () => {
    vi.useFakeTimers()
    fetchMock = vi.fn()
    vi.stubGlobal('fetch', fetchMock)
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('add-to-playlist', AddToPlaylistController)
    await settle()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application.stop()
    vi.unstubAllGlobals()
    vi.useRealTimers()
  })

  it('opens the panel, shows the track title, and renders fetched playlists', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([
      { id: 1, name: 'Mix', track_count: 1 },
      { id: 2, name: 'Chill', track_count: 3 }
    ]))

    toggleButton().click()
    await settle()

    expect(panel().hidden).toBe(false)
    expect(document.querySelector('[data-add-to-playlist-target="trackLabel"]')!.textContent).toBe('Alpha Signal')
    expect(fetchMock).toHaveBeenCalledWith('/api/playlists')

    const items = list().querySelectorAll('.add-to-playlist__item')
    expect(items).toHaveLength(2)
    expect(items[0]!.textContent).toContain('Mix')
    expect(items[0]!.textContent).toContain('1 track')
    expect(items[1]!.textContent).toContain('3 tracks')
  })

  it('shows the empty state and the fetch-failure state', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([]))
    toggleButton().click()
    await settle()
    expect(list().textContent).toContain('No playlists yet')

    toggleButton().click() // close
    fetchMock.mockRejectedValueOnce(new Error('boom'))
    toggleButton().click()
    await settle()
    expect(list().textContent).toContain('Failed to load playlists')
  })

  it('adds the current track on pick and auto-closes on success', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([{ id: 1, name: 'Mix', track_count: 1 }]))
    toggleButton().click()
    await settle()

    fetchMock.mockResolvedValueOnce(jsonResponse({ success: true }))
    list().querySelector<HTMLElement>('.add-to-playlist__item')!.click()
    await settle()

    expect(fetchMock).toHaveBeenLastCalledWith('/api/playlists/1/tracks', expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({ track_id: '42' })
    }))
    expect(message().hidden).toBe(false)
    expect(message().textContent).toBe('Added to "Mix"')
    expect(message().classList.contains('add-to-playlist__message--success')).toBe(true)

    vi.advanceTimersByTime(1500)
    expect(panel().hidden).toBe(true)
  })

  it('shows the server error when the add fails', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([{ id: 1, name: 'Mix', track_count: 1 }]))
    toggleButton().click()
    await settle()

    fetchMock.mockResolvedValueOnce(jsonResponse({ success: false, error: 'Track already in playlist' }, false, 422))
    list().querySelector<HTMLElement>('.add-to-playlist__item')!.click()
    await settle()

    expect(message().textContent).toBe('Track already in playlist')
    expect(message().classList.contains('add-to-playlist__message--error')).toBe(true)
    expect(panel().hidden).toBe(false)
  })

  it('creates a playlist then adds the current track to it', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([]))
    toggleButton().click()
    await settle()

    const createForm = document.querySelector<HTMLFormElement>('[data-add-to-playlist-target="createForm"]')!
    const nameInput = document.querySelector<HTMLInputElement>('[data-add-to-playlist-target="createName"]')!
    document.querySelector<HTMLElement>('[data-action="add-to-playlist#showCreate"]')!.click()
    expect(createForm.hidden).toBe(false)

    fetchMock.mockResolvedValueOnce(jsonResponse({ playlist: { id: 9, name: 'Fresh' } }))
    fetchMock.mockResolvedValueOnce(jsonResponse({ success: true }))
    nameInput.value = '  Fresh  '
    createForm.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
    await settle()

    expect(fetchMock).toHaveBeenNthCalledWith(2, '/api/playlists', expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({ playlist: { name: 'Fresh' } })
    }))
    expect(fetchMock).toHaveBeenNthCalledWith(3, '/api/playlists/9/tracks', expect.anything())
    expect(message().textContent).toBe('Added to "Fresh"')
    expect(nameInput.value).toBe('')
    expect(createForm.hidden).toBe(true)
  })

  it('closes on outside mousedown but not on inside mousedown', async () => {
    fetchMock.mockResolvedValueOnce(jsonResponse([]))
    toggleButton().click()
    await settle()
    expect(panel().hidden).toBe(false)

    list().dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
    expect(panel().hidden).toBe(false)

    document.getElementById('outside')!.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }))
    expect(panel().hidden).toBe(true)
  })
})
