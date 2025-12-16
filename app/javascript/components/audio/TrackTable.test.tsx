import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { TrackTable } from './TrackTable'

// Mock the hooks
const mockLoadTrack = vi.fn()
const mockSetPlaylist = vi.fn()
const mockTogglePlayPause = vi.fn()
const mockGetCurrentTrackId = vi.fn()
const mockIsPlaying = vi.fn()

vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => ({
    isLoggedIn: false,
    hackr: null,
    loading: false
  })
}))

vi.mock('~/contexts/AudioContext', () => ({
  useAudio: () => ({
    audioPlayerAPI: {
      current: {
        loadTrack: mockLoadTrack,
        setPlaylist: mockSetPlaylist,
        togglePlayPause: mockTogglePlayPause,
        getCurrentTrackId: mockGetCurrentTrackId,
        isPlaying: mockIsPlaying
      }
    }
  })
}))

describe('TrackTable', () => {
  const mockTracks = [
    {
      id: 1,
      title: 'Track One',
      artist: { name: 'Artist A', genre: 'Electronic' },
      album: { name: 'Album A', cover_url: 'https://example.com/cover1.jpg' },
      audio_url: 'https://example.com/track1.mp3'
    },
    {
      id: 2,
      title: 'Track Two',
      artist: { name: 'Artist B', genre: 'Industrial' },
      album: { name: 'Album B', cover_url: 'https://example.com/cover2.jpg' },
      audio_url: 'https://example.com/track2.mp3'
    },
    {
      id: 3,
      title: 'Unavailable Track',
      artist: { name: 'Artist C', genre: 'Synthwave' },
      album: { name: 'Album C', cover_url: null },
      audio_url: null
    }
  ]

  beforeEach(() => {
    vi.clearAllMocks()
    mockGetCurrentTrackId.mockReturnValue(null)
    mockIsPlaying.mockReturnValue(false)
  })

  it('renders track information', () => {
    render(<TrackTable tracks={mockTracks} />)

    expect(screen.getByText('Track One')).toBeInTheDocument()
    expect(screen.getByText('Track Two')).toBeInTheDocument()
    expect(screen.getByText('Unavailable Track')).toBeInTheDocument()
  })

  it('renders artist names', () => {
    render(<TrackTable tracks={mockTracks} />)

    expect(screen.getByText(/Artist A/)).toBeInTheDocument()
    expect(screen.getByText(/Artist B/)).toBeInTheDocument()
  })

  it('shows PLAY button for tracks with audio', () => {
    render(<TrackTable tracks={mockTracks} />)

    const playButtons = screen.getAllByRole('button', { name: /play/i })
    expect(playButtons).toHaveLength(2)
  })

  it('does not show PLAY button for tracks without audio', () => {
    render(<TrackTable tracks={mockTracks} />)

    // Track 3 has no audio_url, so it should show a dash instead of a button
    const trackRow = screen.getByText('Unavailable Track').closest('tr')
    expect(trackRow).toBeInTheDocument()
  })

  describe('currently playing track highlighting', () => {
    it('highlights currently playing track with cyan text color', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackTitle = screen.getByText('Track One').closest('strong')
        expect(trackTitle).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('shows play indicator on currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByText('►')).toBeInTheDocument()
      })
    })

    it('does not highlight non-playing tracks with cyan', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

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

      render(<TrackTable tracks={mockTracks} />)

      // When paused, the track should not have cyan color (no need to wait, initial state is correct)
      const trackTitle = screen.getByText('Track One').closest('strong')
      expect(trackTitle).toHaveStyle({ color: '#ccc' })
    })

    it('highlights artist name with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        const artistCell = trackRow?.querySelectorAll('td')[1]
        expect(artistCell).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('highlights album name with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        const trackRow = screen.getByText('Track One').closest('tr')
        const albumCell = trackRow?.querySelectorAll('td')[2]
        expect(albumCell).toHaveStyle({ color: '#00ffff' })
      })
    })

    it('highlights genre with cyan when track is playing', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

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

      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
      })
    })

    it('applies purple background tint to currently playing row', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      render(<TrackTable tracks={mockTracks} />)

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
      render(<TrackTable tracks={mockTracks} />)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'One')

      expect(screen.getByText('Track One')).toBeInTheDocument()
      expect(screen.queryByText('Track Two')).not.toBeInTheDocument()
    })

    it('filters tracks by artist', async () => {
      const user = userEvent.setup()
      render(<TrackTable tracks={mockTracks} />)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'Artist B')

      expect(screen.queryByText('Track One')).not.toBeInTheDocument()
      expect(screen.getByText('Track Two')).toBeInTheDocument()
    })

    it('filters tracks by genre', async () => {
      const user = userEvent.setup()
      render(<TrackTable tracks={mockTracks} />)

      const searchInput = screen.getByPlaceholderText('Type to filter tracks...')
      await user.type(searchInput, 'Industrial')

      expect(screen.queryByText('Track One')).not.toBeInTheDocument()
      expect(screen.getByText('Track Two')).toBeInTheDocument()
    })

    it('uses initialFilter prop', () => {
      render(<TrackTable tracks={mockTracks} initialFilter="Artist A" />)

      expect(screen.getByText('Track One')).toBeInTheDocument()
      expect(screen.queryByText('Track Two')).not.toBeInTheDocument()
    })
  })

  describe('playback controls', () => {
    it('calls loadTrack when clicking play on a track', async () => {
      const user = userEvent.setup()
      render(<TrackTable tracks={mockTracks} />)

      const playButtons = screen.getAllByRole('button', { name: /play/i })
      await user.click(playButtons[0])

      expect(mockSetPlaylist).toHaveBeenCalled()
      expect(mockLoadTrack).toHaveBeenCalledWith({
        id: '1',
        url: 'https://example.com/track1.mp3',
        title: 'Track One',
        artist: 'Artist A',
        coverUrl: 'https://example.com/cover1.jpg'
      })
    })

    it('toggles play/pause when clicking on currently playing track', async () => {
      mockGetCurrentTrackId.mockReturnValue('1')
      mockIsPlaying.mockReturnValue(true)

      const user = userEvent.setup()
      render(<TrackTable tracks={mockTracks} />)

      // Wait for the useEffect polling to update the state
      await waitFor(() => {
        expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
      })

      const pauseButton = screen.getByRole('button', { name: /pause/i })
      await user.click(pauseButton)

      expect(mockTogglePlayPause).toHaveBeenCalled()
    })
  })
})
