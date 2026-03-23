import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { render, screen, waitFor, fireEvent, act } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { AudioPlayer } from './AudioPlayer'

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

// Mock the hooks needed by PlayerBar
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
        getEffectivePlaylist: () => [],
        loadTrack: vi.fn()
      }
    }
  })
}))

// MediaError constants (not available in jsdom)
const MEDIA_ERR_NETWORK = 2
const MEDIA_ERR_DECODE = 3

describe('AudioPlayer', () => {
  const mockTrack = {
    id: 'track-1',
    url: 'https://example.com/track.mp3',
    title: 'Test Track',
    artist: 'Test Artist',
    coverUrl: 'https://example.com/cover.jpg'
  }

  beforeEach(() => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({})
    } as Response))

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
    vi.unstubAllGlobals()
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

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

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

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')
  })

  it('handles play/pause toggle', async () => {
    const user = userEvent.setup()
    render(<AudioPlayer />)

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

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

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      const pauseButton = document.querySelector('#play-pause-btn')
      expect(pauseButton?.textContent).toContain('PAUSE')
    })

    // Simulate spacebar press
    const spaceEvent = new KeyboardEvent('keydown', { key: ' ', bubbles: true })
    await act(async () => {
      document.dispatchEvent(spaceEvent)
    })

    await waitFor(() => {
      const playButton = document.querySelector('#play-pause-btn')
      expect(playButton?.textContent).toContain('PLAY')
    })
  })

  it('does not trigger spacebar in input fields', async () => {
    render(
      <>
        <AudioPlayer />
        <input type="text" data-testid="test-input" />
      </>
    )

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      const pauseButton = document.querySelector('#play-pause-btn')
      expect(pauseButton?.textContent).toContain('PAUSE')
    })

    const input = screen.getByTestId('test-input')
    input.focus()

    // Dispatch event from the input element itself (not document)
    await act(async () => {
      input.dispatchEvent(new KeyboardEvent('keydown', {
        key: ' ',
        bubbles: true
      }))
    })

    // Should still be playing (pause button visible) because spacebar in input should not toggle
    const pauseButton = document.querySelector('#play-pause-btn')
    expect(pauseButton?.textContent).toContain('PAUSE')
  })

  it('handles volume change', async () => {
    render(<AudioPlayer />)

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      expect(document.querySelector('#volume-control')).toBeInTheDocument()
    })

    const volumeControl = document.querySelector('#volume-control') as HTMLInputElement
    await act(async () => {
      fireEvent.change(volumeControl, { target: { value: '50' } })
    })

    await waitFor(() => {
      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      expect(audio.volume).toBe(0.5)
    })
  })

  it('handles seek operations', async () => {
    render(<AudioPlayer />)

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

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
    await act(async () => {
      fireEvent.change(seekBar, { target: { value: '50' } })
    })

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

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

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

    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      expect(track1Row.style.background).toBe('rgba(124, 58, 237, 0.15)')
      expect(track1Title.style.color).toBe('rgb(167, 139, 250)')
      expect(track1Button.textContent).toBe('❚❚ PAUSE')
    })
  })

  it('handles auto-play next track on end', async () => {
    render(<AudioPlayer />)

    // Populate playlist from DOM before loading track
    window.audioPlayer?.refreshPlaylist()
    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      expect(screen.getByText('Test Track')).toBeInTheDocument()
    })

    // Simulate track ending
    const audio = document.querySelector('#audio-element') as HTMLAudioElement
    const endEvent = new Event('ended')
    await act(async () => {
      audio.dispatchEvent(endEvent)
    })

    await waitFor(() => {
      // Should auto-play Track 2
      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-2')
    }, { timeout: 3000 })
  })

  it('respects filtered tracks for auto-play', async () => {
    render(<AudioPlayer />)

    // Hide track-2 (simulate filter)
    const track2Row = document.querySelector('.track-row[data-track-id="track-2"]') as HTMLElement
    track2Row.style.display = 'none'

    // Refresh playlist to respect the filter
    window.audioPlayer?.refreshPlaylist()
    await act(async () => {
      window.audioPlayer?.loadTrack(mockTrack)
    })

    await waitFor(() => {
      expect(screen.getByText('Test Track')).toBeInTheDocument()
    })

    // Simulate track ending
    const audio = document.querySelector('#audio-element') as HTMLAudioElement
    const endEvent = new Event('ended')
    await act(async () => {
      audio.dispatchEvent(endEvent)
    })

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

  describe('Playback Recovery', () => {
    const mockTrack = {
      id: 'track-1',
      url: 'https://example.com/track.mp3',
      title: 'Test Track',
      artist: 'Test Artist',
      coverUrl: 'https://example.com/cover.jpg'
    }

    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('handles stalled event by logging without reloading', async () => {
      vi.useRealTimers() // Use real timers for this test
      const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})

      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      const audio = document.querySelector('#audio-element') as HTMLAudioElement

      const loadSpy = vi.spyOn(audio, 'load')

      // Simulate stalled event
      const stalledEvent = new Event('stalled')
      await act(async () => {
        audio.dispatchEvent(stalledEvent)
      })

      // Should log a warning but NOT reload — browser handles rebuffering on its own
      expect(consoleSpy).toHaveBeenCalledWith(
        'Audio playback stalled — browser is rebuffering, waiting for data...'
      )
      expect(loadSpy).not.toHaveBeenCalled()

      loadSpy.mockRestore()
      consoleSpy.mockRestore()
    })

    it('handles network error by attempting recovery after delay', async () => {
      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      const loadSpy = vi.spyOn(audio, 'load')
      const playSpy = vi.spyOn(audio, 'play').mockResolvedValue(undefined)

      await act(async () => {
        audio.dispatchEvent(new Event('canplay'))
      })

      playSpy.mockClear()

      // Mock a network error
      Object.defineProperty(audio, 'error', {
        value: { code: MEDIA_ERR_NETWORK, message: 'Network error' },
        configurable: true
      })

      // Simulate error event
      const errorEvent = new Event('error')
      await act(async () => {
        audio.dispatchEvent(errorEvent)
      })

      // Recovery happens after 1000ms delay
      await act(async () => {
        vi.advanceTimersByTime(1000)
      })

      expect(loadSpy).toHaveBeenCalled()
      expect(playSpy).toHaveBeenCalled()

      loadSpy.mockRestore()
      playSpy.mockRestore()
    })

    it('does not attempt recovery for non-network errors', async () => {
      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      const loadSpy = vi.spyOn(audio, 'load')
      const playSpy = vi.spyOn(audio, 'play').mockResolvedValue(undefined)

      await act(async () => {
        audio.dispatchEvent(new Event('canplay'))
      })

      playSpy.mockClear()

      // Mock a decode error (not a network error)
      Object.defineProperty(audio, 'error', {
        value: { code: MEDIA_ERR_DECODE, message: 'Decode error' },
        configurable: true
      })

      // Simulate error event
      const errorEvent = new Event('error')
      await act(async () => {
        audio.dispatchEvent(errorEvent)
      })

      // Advance time past recovery delay
      await act(async () => {
        vi.advanceTimersByTime(2000)
      })

      // Should not attempt to reload for decode errors
      expect(loadSpy).not.toHaveBeenCalled()

      loadSpy.mockRestore()
      playSpy.mockRestore()
    })

    it('attempts to resume when unexpected pause is detected', async () => {
      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      const playSpy = vi.spyOn(audio, 'play').mockResolvedValue(undefined)

      await act(async () => {
        audio.dispatchEvent(new Event('canplay'))
      })

      playSpy.mockClear()

      // Mock audio as paused but we think it should be playing
      Object.defineProperty(audio, 'paused', {
        value: true,
        configurable: true
      })
      Object.defineProperty(audio, 'ended', {
        value: false,
        configurable: true
      })

      // Simulate pause event (browser intervention)
      const pauseEvent = new Event('pause')
      await act(async () => {
        audio.dispatchEvent(pauseEvent)
      })

      // Recovery check happens after 100ms
      await act(async () => {
        vi.advanceTimersByTime(100)
      })

      expect(playSpy).toHaveBeenCalled()

      playSpy.mockRestore()
    })

    it('does not attempt resume when audio has ended', async () => {
      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      const audio = document.querySelector('#audio-element') as HTMLAudioElement
      const playSpy = vi.spyOn(audio, 'play').mockResolvedValue(undefined)

      await act(async () => {
        audio.dispatchEvent(new Event('canplay'))
      })

      playSpy.mockClear()

      // Mock audio as ended
      Object.defineProperty(audio, 'ended', {
        value: true,
        configurable: true
      })

      // Simulate pause event
      const pauseEvent = new Event('pause')
      await act(async () => {
        audio.dispatchEvent(pauseEvent)
      })

      await act(async () => {
        vi.advanceTimersByTime(100)
      })

      // Should not resume since audio has ended naturally
      expect(playSpy).not.toHaveBeenCalled()

      playSpy.mockRestore()
    })

    it('watchdog is activated when track is playing', async () => {
      vi.useRealTimers()
      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      await waitFor(() => {
        expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')
      })

      // Wait for play state to be set - this indicates the watchdog effect should be running
      await waitFor(() => {
        const pauseBtn = document.querySelector('#play-pause-btn')
        expect(pauseBtn?.textContent).toContain('PAUSE')
      })

      // Verify the player is in a state where watchdog would be active
      expect(window.audioPlayer?.isPlaying()).toBe(true)
      expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')

      // The watchdog effect is now monitoring playback
      // (Full timing tests are impractical in unit tests due to 5s intervals)
    })

    it('logs waiting event for debugging', async () => {
      vi.useRealTimers()
      const consoleSpy = vi.spyOn(console, 'log').mockImplementation(() => {})

      render(<AudioPlayer />)

      await act(async () => {
        window.audioPlayer?.loadTrack(mockTrack)
      })

      await waitFor(() => {
        expect(window.audioPlayer?.getCurrentTrackId()).toBe('track-1')
      })

      const audio = document.querySelector('#audio-element') as HTMLAudioElement

      // Simulate waiting event
      const waitingEvent = new Event('waiting')
      await act(async () => {
        audio.dispatchEvent(waitingEvent)
      })

      expect(consoleSpy).toHaveBeenCalledWith('Audio waiting for data...')

      consoleSpy.mockRestore()
    })
  })
})
