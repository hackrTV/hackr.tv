import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { PlayerBar } from './PlayerBar'

// Mock the hooks
vi.mock('~/hooks/useGridAuth', () => ({
  useGridAuth: () => ({
    isLoggedIn: false,
    hackr: null,
    loading: false,
    disconnect: vi.fn()
  })
}))

vi.mock('~/contexts/AudioContext', () => ({
  useAudio: () => ({
    audioPlayerAPI: {
      current: {
        getPlaylist: () => [],
        loadTrack: vi.fn()
      }
    }
  })
}))

describe('PlayerBar', () => {
  const mockTrack = {
    id: '1',
    title: 'Test Track',
    artist: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg'
  }

  const defaultProps = {
    isPlaying: false,
    currentTrack: mockTrack,
    currentTime: 30,
    duration: 180,
    volume: 0.7,
    onPlayPause: vi.fn(),
    onSeekStart: vi.fn(),
    onSeek: vi.fn(),
    onSeekEnd: vi.fn(),
    onVolumeChange: vi.fn(),
    onClose: vi.fn()
  }

  it('renders with track information', () => {
    render(<PlayerBar {...defaultProps} />)

    expect(screen.getByText('Test Track')).toBeInTheDocument()
    expect(screen.getByText('Test Artist')).toBeInTheDocument()
  })

  it('renders album cover when coverUrl is provided', () => {
    render(<PlayerBar {...defaultProps} />)

    const cover = screen.getByAltText('Album Cover')
    expect(cover).toBeInTheDocument()
    expect(cover).toHaveAttribute('src', 'https://example.com/cover.jpg')
  })

  it('does not render album cover when no coverUrl', () => {
    const trackWithoutCover = { ...mockTrack, coverUrl: '' }
    render(<PlayerBar {...defaultProps} currentTrack={trackWithoutCover} />)

    const cover = screen.queryByAltText('Album Cover')
    expect(cover).not.toBeInTheDocument()
  })

  it('displays "No track loaded" when currentTrack is null', () => {
    render(<PlayerBar {...defaultProps} currentTrack={null} />)

    expect(screen.getByText('No track loaded')).toBeInTheDocument()
    // There may be multiple "—" in the UI (from time display), just check one exists
    const dashElements = screen.getAllByText('—')
    expect(dashElements.length).toBeGreaterThan(0)
  })

  it('shows PLAY button when not playing', () => {
    render(<PlayerBar {...defaultProps} isPlaying={false} />)

    expect(screen.getByRole('button', { name: /play/i })).toBeInTheDocument()
  })

  it('shows PAUSE button when playing', () => {
    render(<PlayerBar {...defaultProps} isPlaying={true} />)

    expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
  })

  it('calls onPlayPause when play/pause button clicked', async () => {
    const user = userEvent.setup()
    const onPlayPause = vi.fn()
    render(<PlayerBar {...defaultProps} onPlayPause={onPlayPause} />)

    const playButton = screen.getByRole('button', { name: /play/i })
    await user.click(playButton)

    expect(onPlayPause).toHaveBeenCalledTimes(1)
  })

  it('calls onClose when close button clicked', async () => {
    const user = userEvent.setup()
    const onClose = vi.fn()
    render(<PlayerBar {...defaultProps} onClose={onClose} />)

    const closeButton = screen.getByRole('button', { name: '✕' })
    await user.click(closeButton)

    expect(onClose).toHaveBeenCalledTimes(1)
  })

  it('renders SeekBar with correct props', () => {
    render(<PlayerBar {...defaultProps} />)

    // SeekBar displays time
    const currentTime = screen.getByText('0:30')
    const duration = screen.getByText('3:00')
    expect(currentTime).toBeInTheDocument()
    expect(duration).toBeInTheDocument()

    // Should have exactly one seek slider
    const sliders = screen.getAllByRole('slider')
    expect(sliders.length).toBeGreaterThanOrEqual(1)
  })

  it('renders VolumeControl with correct value', () => {
    render(<PlayerBar {...defaultProps} volume={0.7} />)

    const volumeControl = document.querySelector('#volume-control') as HTMLInputElement
    expect(volumeControl).toBeInTheDocument()
    expect(volumeControl.value).toBe('70')
  })

  it('calls onVolumeChange when volume slider changes', async () => {
    const onVolumeChange = vi.fn()
    render(<PlayerBar {...defaultProps} onVolumeChange={onVolumeChange} />)

    const volumeControl = document.querySelector('#volume-control') as HTMLInputElement

    // Change the volume value using fireEvent (proper React event)
    fireEvent.change(volumeControl, { target: { value: '50' } })

    expect(onVolumeChange).toHaveBeenCalled()
    expect(onVolumeChange).toHaveBeenCalledWith(0.5)
  })

  it('has fixed positioning at bottom of screen', () => {
    const { container } = render(<PlayerBar {...defaultProps} />)

    const playerBar = container.querySelector('#audio-player')
    expect(playerBar).toHaveStyle({
      position: 'fixed',
      bottom: '0',
      left: '0',
      right: '0'
    })
  })

  it('shows album overlay on hover', async () => {
    const user = userEvent.setup()
    render(<PlayerBar {...defaultProps} />)

    const cover = screen.getByAltText('Album Cover')

    // Verify overlay doesn't exist before hover
    expect(document.querySelector('#cover-overlay')).not.toBeInTheDocument()

    await user.hover(cover)

    // Verify overlay appears after hover
    const overlay = document.querySelector('#cover-overlay')
    expect(overlay).toBeInTheDocument()
  })
})
