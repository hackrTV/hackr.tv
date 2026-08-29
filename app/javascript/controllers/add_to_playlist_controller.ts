import { Controller } from '@hotwired/stimulus'

// "+ Playlist" dropdown (ported from AddToPlaylistDropdown.tsx). Lives in
// the permanent player bar; the player controller writes the current
// track's id/title into this element's value attributes on every load.
// Create-new is an inline name form instead of the React modal — the bar
// must work on every page, not just ones that host a playlist modal.

interface PlaylistSummary {
  id: number
  name: string
  track_count: number
}

export default class extends Controller {
  static targets = ['panel', 'trackLabel', 'message', 'list', 'createForm', 'createName']
  static values = {
    trackId: String,
    trackTitle: String,
    direction: { type: String, default: 'down' }
  }

  declare readonly panelTarget: HTMLElement
  declare readonly trackLabelTarget: HTMLElement
  declare readonly messageTarget: HTMLElement
  declare readonly listTarget: HTMLElement
  declare readonly createFormTarget: HTMLFormElement
  declare readonly createNameTarget: HTMLInputElement
  declare trackIdValue: string
  declare trackTitleValue: string

  connect (): void {
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
    document.addEventListener('mousedown', this.onDocumentMouseDown)
  }

  disconnect (): void {
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
  }

  private readonly onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.panelTarget.hidden) return
    if (!this.element.contains(event.target as Node)) this.close()
  }

  async toggle (): Promise<void> {
    if (this.panelTarget.hidden) {
      this.trackLabelTarget.textContent = this.trackTitleValue
      this.panelTarget.hidden = false
      await this.fetchPlaylists()
    } else {
      this.close()
    }
  }

  close (): void {
    this.panelTarget.hidden = true
    this.hideMessage()
    this.createFormTarget.hidden = true
  }

  showCreate (): void {
    this.createFormTarget.hidden = false
    this.createNameTarget.focus()
  }

  async create (event: Event): Promise<void> {
    event.preventDefault()
    const name = this.createNameTarget.value.trim()
    if (!name) return

    try {
      const response = await fetch('/api/playlists', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlist: { name } })
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json() as { playlist?: { id: number, name: string } }

      this.createNameTarget.value = ''
      this.createFormTarget.hidden = true

      if (data.playlist && this.trackIdValue) {
        await this.addToPlaylist(data.playlist.id, data.playlist.name)
      } else {
        await this.fetchPlaylists()
      }
    } catch {
      this.showMessage('Failed to create playlist', 'error')
    }
  }

  async pick (event: Event): Promise<void> {
    const button = event.currentTarget as HTMLElement
    await this.addToPlaylist(Number(button.dataset.playlistId), button.dataset.playlistName || '')
  }

  private async addToPlaylist (playlistId: number, playlistName: string): Promise<void> {
    try {
      const response = await fetch(`/api/playlists/${playlistId}/tracks`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ track_id: this.trackIdValue })
      })
      const data = await response.json() as { success?: boolean, error?: string }

      if (response.ok && data.success) {
        this.showMessage(`Added to "${playlistName}"`, 'success')
        window.setTimeout(() => this.close(), 1500)
      } else {
        this.showMessage(data.error || 'Failed to add track', 'error')
      }
    } catch {
      this.showMessage('Failed to add track', 'error')
    }
  }

  private async fetchPlaylists (): Promise<void> {
    this.listTarget.innerHTML = '<div class="add-to-playlist__empty">Loading...</div>'
    try {
      const response = await fetch('/api/playlists')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const playlists = await response.json() as PlaylistSummary[]
      this.renderPlaylists(playlists)
    } catch {
      this.listTarget.innerHTML = '<div class="add-to-playlist__empty">Failed to load playlists</div>'
    }
  }

  private renderPlaylists (playlists: PlaylistSummary[]): void {
    if (playlists.length === 0) {
      this.listTarget.innerHTML = '<div class="add-to-playlist__empty">No playlists yet.<br>Create one to get started!</div>'
      return
    }

    this.listTarget.textContent = ''
    for (const playlist of playlists) {
      const button = document.createElement('button')
      button.className = 'tui-button add-to-playlist__item'
      button.dataset.playlistId = String(playlist.id)
      button.dataset.playlistName = playlist.name
      button.setAttribute('data-action', 'add-to-playlist#pick')

      const name = document.createElement('div')
      name.className = 'add-to-playlist__item-name'
      name.textContent = playlist.name

      const count = document.createElement('div')
      count.className = 'add-to-playlist__item-count'
      count.textContent = `${playlist.track_count} ${playlist.track_count === 1 ? 'track' : 'tracks'}`

      button.append(name, count)
      this.listTarget.appendChild(button)
    }
  }

  private showMessage (text: string, type: 'success' | 'error'): void {
    this.messageTarget.textContent = text
    this.messageTarget.hidden = false
    this.messageTarget.classList.toggle('add-to-playlist__message--success', type === 'success')
    this.messageTarget.classList.toggle('add-to-playlist__message--error', type === 'error')
  }

  private hideMessage (): void {
    this.messageTarget.hidden = true
  }
}
