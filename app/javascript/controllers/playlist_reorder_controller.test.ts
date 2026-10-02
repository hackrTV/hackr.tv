import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { Application } from '@hotwired/stimulus'
import PlaylistReorderController from './playlist_reorder_controller'

// Fixture mirrors playlists/_tracks_table.html.erb: sortable tbody rows
// with data-track-ref-id, position cells, and ↑/↓ move buttons.

function rowHtml (refId: number, position: number): string {
  return `
    <tr data-track-ref-id="${refId}" draggable="true">
      <td data-playlist-reorder-target="position">${position}</td>
      <td>Track ${refId}</td>
      <td>
        <button class="up" data-action="playlist-reorder#moveUp">↑</button>
        <button class="down" data-action="playlist-reorder#moveDown">↓</button>
      </td>
    </tr>`
}

const FIXTURE = `
  <div data-controller="playlist-reorder" data-playlist-reorder-url-value="/api/playlists/5/reorder">
    <table>
      <thead><tr><th>#</th><th>Title</th><th></th></tr></thead>
      <tbody data-playlist-reorder-target="body">
        ${rowHtml(11, 1)}
        ${rowHtml(22, 2)}
        ${rowHtml(33, 3)}
      </tbody>
    </table>
  </div>`

describe('PlaylistReorderController', () => {
  let application: Application
  let fetchMock: ReturnType<typeof vi.fn>

  const tbody = (): HTMLTableSectionElement => document.querySelector('[data-playlist-reorder-target="body"]')!
  const order = (): number[] => Array.from(tbody().rows).map((r) => Number(r.dataset.trackRefId))
  const positions = (): string[] =>
    Array.from(document.querySelectorAll('[data-playlist-reorder-target="position"]')).map((c) => c.textContent!)

  async function settle (): Promise<void> {
    await Promise.resolve()
    await Promise.resolve()
  }

  beforeEach(async () => {
    fetchMock = vi.fn().mockResolvedValue({ ok: true })
    vi.stubGlobal('fetch', fetchMock)
    document.body.innerHTML = FIXTURE
    application = Application.start()
    application.register('playlist-reorder', PlaylistReorderController)
    await settle()
  })

  afterEach(async () => {
    document.body.innerHTML = ''
    await Promise.resolve()
    application.stop()
    vi.unstubAllGlobals()
    vi.restoreAllMocks()
  })

  it('moveDown swaps the row with its successor, renumbers, and persists the order', async () => {
    tbody().rows[0]!.querySelector<HTMLElement>('.down')!.click()
    await settle()

    expect(order()).toEqual([22, 11, 33])
    // Position cells renumber to match the new visual order
    expect(positions()).toEqual(['1', '2', '3'])
    expect(fetchMock).toHaveBeenCalledWith('/api/playlists/5/reorder', expect.objectContaining({
      method: 'POST',
      body: JSON.stringify({ track_ids: [22, 11, 33] })
    }))
  })

  it('moveUp swaps the row with its predecessor', async () => {
    tbody().rows[2]!.querySelector<HTMLElement>('.up')!.click()
    await settle()

    expect(order()).toEqual([11, 33, 22])
    expect(fetchMock).toHaveBeenCalledOnce()
  })

  it('does nothing at the boundaries', async () => {
    tbody().rows[0]!.querySelector<HTMLElement>('.up')!.click()
    tbody().rows[2]!.querySelector<HTMLElement>('.down')!.click()
    await settle()

    expect(order()).toEqual([11, 22, 33])
    expect(fetchMock).not.toHaveBeenCalled()
  })

  it('reorders via drag events and persists once on dragend', async () => {
    const rows = tbody().rows
    rows[0]!.dispatchEvent(new Event('dragstart', { bubbles: true }))
    expect(rows[0]!.classList.contains('playlist-table__row--dragging')).toBe(true)

    // Drag row 1 over row 3 (downward → insert after)
    tbody().rows[2]!.dispatchEvent(new Event('dragover', { bubbles: true, cancelable: true }))
    expect(order()).toEqual([22, 33, 11])

    tbody().rows[0]!.dispatchEvent(new Event('dragend', { bubbles: true }))
    await settle()

    expect(fetchMock).toHaveBeenCalledOnce()
    expect(fetchMock).toHaveBeenCalledWith('/api/playlists/5/reorder', expect.objectContaining({
      body: JSON.stringify({ track_ids: [22, 33, 11] })
    }))
    expect(document.querySelector('.playlist-table__row--dragging')).toBeNull()
  })

  it('alerts and reloads when persistence fails', async () => {
    fetchMock.mockResolvedValue({ ok: false, status: 500 })
    const alertSpy = vi.spyOn(window, 'alert').mockImplementation(() => {})
    const reloadSpy = vi.fn()
    vi.spyOn(console, 'error').mockImplementation(() => {})
    Object.defineProperty(window, 'location', {
      writable: true,
      value: { ...window.location, reload: reloadSpy }
    })

    tbody().rows[0]!.querySelector<HTMLElement>('.down')!.click()
    await settle()
    await settle()

    expect(alertSpy).toHaveBeenCalledWith('Failed to save new track order')
    expect(reloadSpy).toHaveBeenCalled()
  })
})
