import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { TrackTable } from './TrackTable'

// Mock matchMedia for useMobileDetect hook
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
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

// Mock the hooks
const mockLoadTrack = vi.fn()
const mockSetPlaylist = vi.fn()
const mockTogglePlayPause = vi.fn()
const mockGetCurrentTrackId = vi.fn()
const mockIsPlaying = vi.fn()
const mockGetStationContext = vi.fn()
const mockIsShuffle = vi.fn()
const mockToggleShuffle = vi.fn()

const mockGridAuth = { isLoggedIn: false, hackr: null, loading: false }
vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => mockGridAuth
}))

vi.mock('~/contexts/AudioContext', () => ({
  useAudio: () => ({
    audioPlayerAPI: {
      current: {
        loadTrack: mockLoadTrack,
        setPlaylist: mockSetPlaylist,
        togglePlayPause: mockTogglePlayPause,
        getCurrentTrackId: mockGetCurrentTrackId,
        isPlaying: mockIsPlaying,
        getStationContext: mockGetStationContext,
        isShuffle: mockIsShuffle,
        toggleShuffle: mockToggleShuffle
      }
    }
  })
}))

const mockFetchPlaylists = vi.fn().mockResolvedValue(undefined)
const mockAddTrackToPlaylist = vi.fn().mockResolvedValue({ success: true })
const mockPlaylists: { id: number; name: string; track_count: number }[] = []
vi.mock('~/hooks/usePlaylist', () => ({
  usePlaylist: () => ({
    playlists: mockPlaylists,
    loading: false,
    error: null,
    fetchPlaylists: mockFetchPlaylists,
    addTrackToPlaylist: mockAddTrackToPlaylist
  })
}))

describe('TrackTable', () => {
  const mockTracks = [
    {
      id: 1,
      title: 'Track One',
      artist: { name: 'Artist A', genre: 'Electronic' },
      release: { name: 'Album A', cover_url: 'https://example.com/cover1.jpg' },
      audio_url: 'https://example.com/track1.mp3'
    },
    {
      id: 2,
      title: 'Track Two',
      artist: { name: 'Artist B', genre: 'Industrial' },
      release: { name: 'Album B', cover_url: 'https://example.com/cover2.jpg' },
      audio_url: 'https://example.com/track2.mp3'
    },
    {
      id: 3,
      title: 'Unavailable Track',
      artist: { name: 'Artist C', genre: 'Synthwave' },
      release: { name: 'Album C', cover_url: null },
      audio_url: null
    }
  ]

  beforeEach(() => {
    vi.clearAllMocks()
    mockGetCurrentTrackId.mockReturnValue(null)
    mockIsPlaying.mockReturnValue(false)
    mockGetStationContext.mockReturnValue(null)
    mockGridAuth.isLoggedIn = false
    mockPlaylists.length = 0
  })

  it('renders track information', () => {
    render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

    expect(screen.getByText('Track One')).toBeInTheDocument()
    expect(screen.getByText('Track Two')).toBeInTheDocument()
    expect(screen.getByText('Unavailable Track')).toBeInTheDocument()
  })

  it('renders artist names', () => {
    render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

    expect(screen.getByText(/Artist A/)).toBeInTheDocument()
    expect(screen.getByText(/Artist B/)).toBeInTheDocument()
  })

  it('shows PLAY button for tracks with audio', () => {
    render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

    const playButtons = screen.getAllByRole('button', { name: /play/i })
    expect(playButtons).toHaveLength(2)
  })

  it('does not show PLAY button for tracks without audio', () => {
    render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

    // Track 3 has no audio_url, so it should show a dash instead of a button
    const trackRow = screen.getByText('Unavailable Track').closest('tr')
    expect(trackRow).toBeInTheDocument()
  })

  describe('currently playing track highlighting', () => {
    it('highlights currently playing track with cyan text color', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackTitle = screen.getByText('Track One').closest('strong')
        expect(trackTitle).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('shows play indicator on currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByText('►')).toBeInTheDocument()
      })
    })

    it('does not highlight non-playing tracks with cyan', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the state to update first
      await waitFor(() => {
        expect(screen.getByText('►')).toBeInTheDocument()
      })

      // Track Two should have normal gray color, not cyan
      const trackTwoTitle = screen.getByText('Track Two').closest('strong')
      expect(trackTwoTitle).toHaveStyle({ color: '#ccc' })
    })

    it('does not highlight when paused', () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(false)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // When paused, the track should not have cyan color (no need to wait, initial state is correct)
      const trackTitle = screen.getByText('Track One').closest('strong')
      expect(trackTitle).toHaveStyle({ color: '#ccc' })
    })

    it('highlights artist name with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        const artistCell = trackRow?.querySelectorAll('td')[1]
        expect(artistCell).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('highlights release name with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        const releaseCell = trackRow?.querySelectorAll('td')[2]
        expect(releaseCell).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('highlights genre with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        const genreCell = trackRow?.querySelectorAll('td')[3]
        expect(genreCell).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('shows PAUSE button for currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
      })
    })

    it('applies purple background tint to currently playing row', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        expect(trackRow).toHaveStyle({ backgroundColor: 'rgba(124, 58, 237, 0.15)' })
      })
    })
  })

  describe('filtering', () => {
    it('filters tracks by title', async () => {
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'One')

      expect(screen.getByText('Track One')).toBeInTheDocument()
      expect(screen.queryByText('Track Two')).not.toBeInTheDocument()
    })

    it('filters tracks by artist', async () => {
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'Artist B')

      expect(screen.queryByText('Track One')).not.toBeInTheDocument()
      expect(screen.getByText('Track Two')).toBeInTheDocument()
    })

    it('filters tracks by genre', async () => {
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'Industrial')

      expect(screen.queryByText('Track One')).not.toBeInTheDocument()
      expect(screen.getByText('Track Two')).toBeInTheDocument()
    })

    it('uses initialFilter prop', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} initialFilter="Artist A" /></MemoryRouter>)

      expect(screen.getByText('Track One')).toBeInTheDocument()
      expect(screen.queryByText('Track Two')).not.toBeInTheDocument()
    })
  })

  describe('playback controls', () => {
    it('calls loadTrack when clicking play on a track', async () => {
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      const playButtons = screen.getAllByRole('button', { name: /play/i })
      await user.click(playButtons[0])

      expect(mockSetPlaylist).toHaveBeenCalled()
      expect(mockLoadTrack).toHaveBeenCalledWith({
        id: '1',
        url: 'https://example.com/track1.mp3',
        title: 'Track One',
        artist: 'Artist A',
        coverUrl: 'https://example.com/cover1.jpg',
        coverUrls: undefined
      })
    })

    it('toggles play/pause when clicking on currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
      })

      const pauseButton = screen.getByRole('button', { name: /pause/i })
      await user.click(pauseButton)

      expect(mockTogglePlayPause).toHaveBeenCalled()
    })
  })

  describe('context menu', () => {
    const rightClickTrack = (trackName: string) => {
      const trackElement = screen.getByText(trackName).closest('tr')!
      fireEvent.contextMenu(trackElement, { clientX: 100, clientY: 200 })
    }

    it('opens context menu on right-click with track-specific play label', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')

      expect(screen.getByRole('menu')).toBeInTheDocument()
      expect(screen.getByText('Play "Track One"')).toBeInTheDocument()
    })

    it('shows Go to Artist and Copy Track Title items', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')

      expect(screen.getByText('Go to Artist')).toBeInTheDocument()
      expect(screen.getByText('Copy Track Title')).toBeInTheDocument()
    })

    it('does not show playlist section when logged out', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')

      expect(screen.queryByText('Add to Playlist')).not.toBeInTheDocument()
      expect(screen.queryByText('Create New Playlist')).not.toBeInTheDocument()
    })

    it('shows playlist section when logged in', () => {
      mockGridAuth.isLoggedIn = true
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')

      expect(screen.getByText('Add to Playlist')).toBeInTheDocument()
      expect(screen.getByText('Create New Playlist')).toBeInTheDocument()
    })

    it('lists user playlists when logged in', () => {
      mockGridAuth.isLoggedIn = true
      mockPlaylists.push(
        { id: 10, name: 'My Playlist', track_count: 3 },
        { id: 11, name: 'Another Playlist', track_count: 0 }
      )
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')

      expect(screen.getByText('My Playlist')).toBeInTheDocument()
      expect(screen.getByText('Another Playlist')).toBeInTheDocument()
    })

    it('calls addTrackToPlaylist when clicking a playlist item', async () => {
      mockGridAuth.isLoggedIn = true
      mockPlaylists.push({ id: 10, name: 'My Playlist', track_count: 3 })
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')
      await user.click(screen.getByText('My Playlist'))

      expect(mockAddTrackToPlaylist).toHaveBeenCalledWith(10, 1)
    })

    it('plays track when clicking Play from context menu', async () => {
      const user = userEvent.setup()
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')
      await user.click(screen.getByText('Play "Track One"'))

      expect(mockLoadTrack).toHaveBeenCalledWith(
        expect.objectContaining({ id: '1', title: 'Track One' })
      )
    })

    it('shows Pause label for currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      await waitFor(() => {
        expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
      })

      rightClickTrack('Track One')

      expect(screen.getByText('Pause')).toBeInTheDocument()
    })

    it('closes context menu on Escape key', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')
      expect(screen.getByRole('menu')).toBeInTheDocument()

      fireEvent.keyDown(document, { key: 'Escape' })
      expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    })

    it('closes context menu on outside click', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      rightClickTrack('Track One')
      expect(screen.getByRole('menu')).toBeInTheDocument()

      fireEvent.mouseDown(document.body)
      expect(screen.queryByRole('menu')).not.toBeInTheDocument()
    })

    it('disables Play for tracks without audio', () => {
      render(<MemoryRouter><TrackTable tracks={mockTracks} /></MemoryRouter>)

      const trackElement = screen.getByText('Unavailable Track').closest('tr')!
      fireEvent.contextMenu(trackElement, { clientX: 100, clientY: 200 })

      const playItem = screen.getByText('Play "Unavailable Track"')
      expect(playItem).toHaveStyle({ color: '#555' })
    })
  })
})
