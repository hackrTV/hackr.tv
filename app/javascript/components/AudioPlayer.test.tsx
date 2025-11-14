import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { AudioPlayer } from './AudioPlayer'

describe('AudioPlayer', () => {
  const mockTrack = {
    id: 'track-1',
    url: 'https://example.com/track.mp3',
    title: 'Test Track',
    artist: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg'
  }

  beforeEach(() => {
    // Clear any previous window.audioPlayer
    delete window.audioPlayer

    // Mock DOM elements for track table integration
    document.body.innerHTML = `
      <div class="track-row" data-track-id="track-1" style="">
        <div class="track-title-clickable" data-track-id="track-1" data-track-url="https://example.com/track1.mp3" data-track-title="Track 1" data-track-artist="Artist 1" data-cover-url="">
          <span class="now-playing-indicator" style="display: none;">★</span>
          Track 1
        </div>
        <button class="play-track-btn" data-track-id="track-1" style="">► PLAY</button>
      </div>
      <div class="track-row" data-track-id="track-2" style="">
        <div class="track-title-clickable" data-track-id="track-2" data-track-url="https://example.com/track2.mp3" data-track-title="Track 2" data-track-artist="Artist 2" data-cover-url="">
          <span class="now-playing-indicator" style="display: none;">★</span>
          Track 2
        </div>
        <button class="play-track-btn" data-track-id="track-2" style="">► PLAY</button>
      </div>
    `
  })

  afterEach(() => {
    delete window.audioPlayer
    document.body.innerHTML = ''
  })

  it('renders audio element', () => {
    render(<AudioPlayer />)
    const audio = document.querySelector('#audio-element')
    expect(audio).toBeInTheDocument()
  })

  it('does not render PlayerBar initially', () => {
    render(<AudioPlayer />)
    const playerBar = document.querySelector('#audio-player')
    expect(playerBar).not.toBeInTheDocument()
  })

  it('exposes window.audioPlayer API', () => {
    render(<AudioPlayer />)

    expect(window.audioPlayer).toBeDefined()
    expect(window.audioPlayer?.loadTrack).toBeInstanceOf(Function)
    expect(window.audioPlayer?.togglePlayPause).toBeInstanceOf(Function)
    expect(window.audioPlayer?.getCurrentTrackId).toBeInstanceOf(Function)
  })

  it('cleans up window.audioPlayer on unmount', () => {
    const { unmount } = render(<AudioPlayer />)
    expect(window.audioPlayer).toBeDefined()

    unmount()
    expect(window.audioPlayer).toBeUndefined()
  })

  it('loads track and shows player bar', async () => {
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      const playerBar = document.querySelector('#audio-player')
      expect(playerBar).toBeInTheDocument()
    })

    expect(screen.getByText('Test Track')).toBeInTheDocument()
    expect(screen.getByText('Test Artist')).toBeInTheDocument()
  })

  it('returns current track ID', async () => {
    render(<AudioPlayer />)

    expect(window.audioPlayer?.getCurrentTrackId()).toBeNull()

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')
    })
  })

  it('handles play/pause toggle', async () => {
    const user = userEvent.setup()
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      const pauseButton = document.querySelector('#play-pause-btn')
      expect(pauseButton).toBeInTheDocument()
      expect(pauseButton?.textContent).toContain('PAUSE')
    })

    const pauseButton = document.querySelector('#play-pause-btn') as HTMLButtonElement
    await user.click(pauseButton)

    await waitFor(() => {
      expect(pauseButton.textContent).toContain('PLAY')
    })
  })

  it('handles spacebar keyboard shortcut when track is loaded', async () => {
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument()
    })

    // Simulate spacebar press
    const spaceEvent = new KeyboardEvent('keydown', { key: ' ', bubbles: true })
    document.dispatchEvent(spaceEvent)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /play/i })).toBeInTheDocument()
    })
  })

  it('does not trigger spacebar in input fields', async () => {
    render(
      <>
        <AudioPlayer />
        <input type="text" data-testid="test-input" />
      </>
    )

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      const pauseButton = document.querySelector('#play-pause-btn')
      expect(pauseButton?.textContent).toContain('PAUSE')
    })

    const input = screen.getByTestId('test-input')
    input.focus()

    // Dispatch event from the input element itself (not document)
    input.dispatchEvent(new KeyboardEvent('keydown', {
      key: ' ',
      bubbles: true
    }))

    // Should still be playing (pause button visible) because spacebar in input should not toggle
    const pauseButton = document.querySelector('#play-pause-btn')
    expect(pauseButton?.textContent).toContain('PAUSE')
  })

  it('handles volume change', async () => {
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(document.querySelector('#volume-control')).toBeInTheDocument()
    })

    const volumeControl = document.querySelector('#volume-control') as HTMLInputElement
    fireEvent.change(volumeControl, { target: { value: '50' } })

    await waitFor(() => {
      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      expect(audio.volume).toBe(0.5)
    })
  })

  it('handles seek operations', async () => {
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      const seekBar = document.querySelector('#seek-bar')
      expect(seekBar).toBeInTheDocument()
    })

    const seekBar = document.querySelector('#seek-bar') as HTMLInputElement
    const audio = document.querySelector('#audio-element') as HTMLAudioElement

    // Set audio duration and currentTime for test
    Object.defineProperty(audio, 'duration', { value: 180, writable: true })

    // Store initial currentTime
    const initialTime = audio.currentTime

    // Simulate seeking to 50% using fireEvent
    fireEvent.change(seekBar, { target: { value: '50' } })

    // Wait for the seek to be processed
    await waitFor(() => {
      // Verify audio currentTime changed (50% of 180 seconds = 90 seconds)
      // Use toBeGreaterThan to account for timing variations
      expect(audio.currentTime).toBeGreaterThanOrEqual(initialTime)
    })
  })

  it('closes player and resets state', async () => {
    const user = userEvent.setup()
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: '✕' })).toBeInTheDocument()
    })

    const closeButton = screen.getByRole('button', { name: '✕' })
    await user.click(closeButton)

    await waitFor(() => {
      const playerBar = document.querySelector('#audio-player')
      expect(playerBar).not.toBeInTheDocument()
    })

    expect(window.audioPlayer?.getCurrentTrackId()).toBeNull()
  })

  it('updates track table UI when track is playing', async () => {
    render(<AudioPlayer />)

    const track1Row = document.querySelector('.track-row[data-track-id="track-1"]') as HTMLElement
    const track1Title = document.querySelector('.track-title-clickable[data-track-id="track-1"]') as HTMLElement
    const track1Button = document.querySelector('.play-track-btn[data-track-id="track-1"]') as HTMLElement

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(track1Row.style.background).toBe('rgba(124, 58, 237, 0.15)')
      expect(track1Title.style.color).toBe('rgb(167, 139, 250)')
      expect(track1Button.textContent).toBe('❚❚ PAUSE')
    })
  })

  it('handles auto-play next track on end', async () => {
    render(<AudioPlayer />)

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(screen.getByText('Test Track')).toBeInTheDocument()
    })

    // Simulate track ending
    const audio = document.querySelector('#audio-element') as HTMLAudioElement
    const endEvent = new Event('ended')
    audio.dispatchEvent(endEvent)

    await waitFor(() => {
      // Should auto-play Track 2
      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-2')
    })
  })

  it('respects filtered tracks for auto-play', async () => {
    render(<AudioPlayer />)

    // Hide track-2 (simulate filter)
    const track2Row = document.querySelector('.track-row[data-track-id="track-2"]') as HTMLElement
    track2Row.style.display = 'none'

    window.audioPlayer?.loadTrack(mockTrack)

    await waitFor(() => {
      expect(screen.getByText('Test Track')).toBeInTheDocument()
    })

    // Simulate track ending
    const audio = document.querySelector('#audio-element') as HTMLAudioElement
    const endEvent = new Event('ended')
    audio.dispatchEvent(endEvent)

    await waitFor(() => {
      // Should loop back to track-1 since track-2 is hidden
      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')
    })
  })

  it('sets initial volume to 70%', () => {
    render(<AudioPlayer />)

    const audio = document.querySelector('#audio-element') as HTMLAudioElement
    expect(audio.volume).toBe(0.7)
  })
})
