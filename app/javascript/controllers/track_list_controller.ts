import { Controller } from '@hotwired/stimulus'
import type { PlayerTrack } from './player_controller'

// Page side of the player contract (ported from TrackTable.tsx). Attach to
// any container of .track-row elements carrying data-player-* attributes
// (emitted by PlayerHelper#player_track_attrs — the single source of
// truth). Row click plays the track; the playlist handed to the player is
// the *visible* playable rows at click time, so an active filter shapes
// the queue exactly like the React table did. Highlights repaint from
// player:state events — no polling.
//
// Also ports the right-click context menu (play/pause, go to artist, copy
// title, add to playlist). Create-new-playlist is an inline name input in
// the menu instead of the React modal.

interface PlayerState {
  trackId: string | null
  playing: boolean
  stationId: number | null
}

export default class extends Controller {
  static targets = ['filter', 'count']
  static values = { autoplay: Boolean }

  declare readonly hasFilterTarget: boolean
  declare readonly filterTarget: HTMLInputElement
  declare readonly hasCountTarget: boolean
  declare readonly countTarget: HTMLElement
  declare autoplayValue: boolean

  private state: PlayerState = { trackId: null, playing: false, stationId: null }
  private menu: HTMLElement | null = null

  connect (): void {
    document.addEventListener('player:state', this.onPlayerState as EventListener)
    document.addEventListener('mousedown', this.onDocumentMouseDown)
    if (this.hasFilterTarget && this.filterTarget.value) this.applyFilter()
    if (this.autoplayValue) {
      // ?autoplay=true (playlist index ▶ Play): start playback and strip
      // the param so refresh/back doesn't replay.
      this.autoplayValue = false
      const url = new URL(window.location.href)
      url.searchParams.delete('autoplay')
      window.history.replaceState({}, '', url)
      this.playAll()
    }
  }

  disconnect (): void {
    document.removeEventListener('player:state', this.onPlayerState as EventListener)
    document.removeEventListener('mousedown', this.onDocumentMouseDown)
    this.closeMenu()
  }

  private readonly onPlayerState = (event: CustomEvent<PlayerState>): void => {
    this.state = event.detail
    this.repaint()
  }

  // --- filtering -----------------------------------------------------

  filterChanged (): void {
    this.applyFilter()
  }

  private applyFilter (): void {
    const term = this.hasFilterTarget ? this.filterTarget.value.toLowerCase() : ''
    let visible = 0
    for (const row of this.rows()) {
      const match = term === '' || (row.dataset.searchText || '').includes(term)
      row.hidden = !match
      if (match) visible++
    }
    if (this.hasCountTarget) this.countTarget.textContent = String(visible)
  }

  // --- playback ------------------------------------------------------

  rowClicked (event: Event): void {
    const row = event.currentTarget as HTMLElement
    this.playRow(row)
  }

  // ▶ Play Playlist: queue every visible playable row, start on the first.
  playAll (): void {
    const playlist = this.visiblePlaylist()
    if (playlist.length === 0) {
      alert('No playable tracks in this playlist')
      return
    }
    document.dispatchEvent(new CustomEvent('player:load-track', {
      detail: { track: playlist[0], playlist, station: null }
    }))
  }

  private playRow (row: HTMLElement): void {
    const track = this.trackFromRow(row)
    if (!track) return

    if (this.state.trackId === track.id && this.state.stationId === null) {
      document.dispatchEvent(new CustomEvent('player:toggle'))
      return
    }

    document.dispatchEvent(new CustomEvent('player:load-track', {
      detail: { track, playlist: this.visiblePlaylist(), station: null }
    }))
  }

  private rows (): HTMLElement[] {
    return Array.from(this.element.querySelectorAll<HTMLElement>('.track-row'))
  }

  private trackFromRow (row: HTMLElement): PlayerTrack | null {
    const data = row.dataset
    if (!data.playerUrl) return null
    return {
      id: data.playerId || '',
      url: data.playerUrl,
      title: data.playerTitle || '',
      artist: data.playerArtist || '',
      coverUrl: data.playerCover || '',
      coverThumbUrl: data.playerCoverThumb || '',
      coverFullUrl: data.playerCoverFull || ''
    }
  }

  // Tables render duplicate desktop/mobile row sets (marked with
  // data-track-set); only the set the media query is showing feeds the
  // queue, so it never contains duplicates. Unmarked rows always count.
  private visiblePlaylist (): PlayerTrack[] {
    const activeSet = window.matchMedia('(max-width: 767px)').matches ? 'mobile' : 'desktop'
    return this.rows()
      .filter((row) => !row.hidden && (!row.dataset.trackSet || row.dataset.trackSet === activeSet))
      .map((row) => this.trackFromRow(row))
      .filter((track): track is PlayerTrack => track !== null)
  }

  // --- highlight repaint ---------------------------------------------

  private repaint (): void {
    for (const row of this.rows()) {
      const isCurrent = this.state.trackId !== null && row.dataset.playerId === this.state.trackId
      const active = isCurrent && this.state.playing

      row.classList.toggle('track-row--active', active)

      const marker = row.querySelector<HTMLElement>('.track-row__marker')
      if (marker) marker.hidden = !active

      const button = row.querySelector<HTMLElement>('.play-track-btn')
      if (button) {
        button.textContent = active ? '❚❚ PAUSE' : '► PLAY'
        button.classList.toggle('play-track-btn--active', active)
      }
    }
  }

  // --- context menu --------------------------------------------------

  rowContextMenu (event: MouseEvent): void {
    const row = event.currentTarget as HTMLElement
    event.preventDefault()
    this.closeMenu()
    this.menu = this.buildMenu(row)
    document.body.appendChild(this.menu)

    // Clamp to the viewport after measuring.
    const rect = this.menu.getBoundingClientRect()
    const x = Math.min(event.clientX, window.innerWidth - rect.width - 8)
    const y = Math.min(event.clientY, window.innerHeight - rect.height - 8)
    this.menu.style.left = `${Math.max(0, x)}px`
    this.menu.style.top = `${Math.max(0, y)}px`
  }

  private readonly onDocumentMouseDown = (event: MouseEvent): void => {
    if (this.menu && !this.menu.contains(event.target as Node)) this.closeMenu()
  }

  private closeMenu (): void {
    this.menu?.remove()
    this.menu = null
  }

  private loggedIn (): boolean {
    return document.querySelector('meta[name="current-hackr-id"]') !== null
  }

  private buildMenu (row: HTMLElement): HTMLElement {
    const track = this.trackFromRow(row)
    const title = row.dataset.playerTitle || ''
    const artistPath = row.dataset.playerArtistPath || ''
    const active = track !== null && this.state.trackId === track.id && this.state.playing

    const menu = document.createElement('div')
    menu.className = 'track-context-menu'

    const addItem = (label: string, icon: string, disabled: boolean, onClick: () => void): void => {
      const item = document.createElement('button')
      item.className = 'track-context-menu__item'
      item.disabled = disabled
      const iconSpan = document.createElement('span')
      iconSpan.className = 'track-context-menu__icon'
      iconSpan.textContent = icon
      item.appendChild(iconSpan)
      item.appendChild(document.createTextNode(` ${label}`))
      item.addEventListener('click', () => {
        onClick()
        if (label !== 'Create New Playlist') this.closeMenu()
      })
      menu.appendChild(item)
    }

    addItem(active ? 'Pause' : `Play "${title}"`, active ? '❚❚' : '►', track === null, () => this.playRow(row))
    addItem('Go to Artist', '→', artistPath === '', () => { window.location.href = artistPath })
    addItem('Copy Track Title', '⎘', false, () => { void navigator.clipboard.writeText(title) })

    if (this.loggedIn() && track) {
      const separator = document.createElement('div')
      separator.className = 'track-context-menu__separator'
      menu.appendChild(separator)

      const header = document.createElement('div')
      header.className = 'track-context-menu__header'
      header.textContent = 'Add to Playlist'
      menu.appendChild(header)

      const list = document.createElement('div')
      list.className = 'track-context-menu__playlists'
      menu.appendChild(list)
      void this.populatePlaylists(list, track.id)

      addItem('Create New Playlist', '+', false, () => {
        this.showInlineCreate(menu, track.id)
      })
    }

    return menu
  }

  private async populatePlaylists (list: HTMLElement, trackId: string): Promise<void> {
    try {
      const response = await fetch('/api/playlists')
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const playlists = await response.json() as Array<{ id: number, name: string }>
      for (const playlist of playlists) {
        const item = document.createElement('button')
        item.className = 'track-context-menu__item'
        item.textContent = `♫ ${playlist.name}`
        item.addEventListener('click', () => {
          void this.addToPlaylist(playlist.id, trackId)
          this.closeMenu()
        })
        list.appendChild(item)
      }
    } catch {
      // Menu stays usable without the playlist section.
    }
  }

  private showInlineCreate (menu: HTMLElement, trackId: string): void {
    if (menu.querySelector('.track-context-menu__create')) return

    const form = document.createElement('form')
    form.className = 'track-context-menu__create'
    const input = document.createElement('input')
    input.type = 'text'
    input.placeholder = 'Playlist name...'
    input.maxLength = 100
    const submit = document.createElement('button')
    submit.type = 'submit'
    submit.className = 'tui-button'
    submit.textContent = 'Create'
    form.append(input, submit)
    form.addEventListener('submit', (event) => {
      event.preventDefault()
      const name = input.value.trim()
      if (name) {
        void this.createPlaylistAndAdd(name, trackId)
        this.closeMenu()
      }
    })
    menu.appendChild(form)
    input.focus()
  }

  private async createPlaylistAndAdd (name: string, trackId: string): Promise<void> {
    try {
      const response = await fetch('/api/playlists', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlist: { name } })
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json() as { playlist?: { id: number } }
      if (data.playlist) await this.addToPlaylist(data.playlist.id, trackId)
    } catch (err) {
      console.warn('Failed to create playlist:', err)
    }
  }

  private async addToPlaylist (playlistId: number, trackId: string): Promise<void> {
    try {
      await fetch(`/api/playlists/${playlistId}/tracks`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ track_id: trackId })
      })
    } catch (err) {
      console.warn('Failed to add track to playlist:', err)
    }
  }
}
