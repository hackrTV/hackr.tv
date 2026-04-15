import React, { useEffect, useRef, useState, useCallback } from 'react'
import { PlayerBar } from './PlayerBar.tsx'
import type { TrackData, AudioPlayerAPI, StationContext } from '~/types/track.ts'
import { apiFetch } from '~/utils/apiClient'

interface AudioPlayerProps {
  onReady?: (api: AudioPlayerAPI) => void
}

export const AudioPlayer: React.FC<AudioPlayerProps> = ({ onReady }) => {
  const audioRef = useRef<HTMLAudioElement>(null)
  const [currentTrack, setCurrentTrack] = useState<TrackData | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [volume, setVolume] = useState(0.7)
  const [isVisible, setIsVisible] = useState(false)
  const [isSeeking, setIsSeeking] = useState(false)
  const [stationContext, setStationContext] = useState<StationContext | null>(null)
  const [shuffle, setShuffle] = useState(false)
  const playlistRef = useRef<TrackData[]>([]) // Store playlist in memory
  const stationContextRef = useRef<StationContext | null>(null) // Store station context
  const shuffledPlaylistRef = useRef<TrackData[]>([]) // Store shuffled playlist
  const lastTimeRef = useRef<number>(0) // Track last known playback time for stall detection
  const creditedTrackIdsRef = useRef<Set<string>>(new Set()) // Achievement play_credit dedup (per session)
  // Cumulative audio played per track (id → seconds). Used to gate the
  // 30s play-credit — counts only forward-progression under 2s between
  // samples, so seeking past the 30s mark does not award credit.
  const playedSecondsByTrackRef = useRef<Map<string, number>>(new Map())
  const lastPlaybackPosRef = useRef<{ id: string; time: number } | null>(null)

  // Update overlay paused state only (without changing track)
  const updateOverlayPaused = useCallback((paused: boolean) => {
    apiFetch('/api/overlay/now-playing', {
      method: 'POST',
      body: JSON.stringify({ paused })
    }).catch(err => console.warn('Failed to update overlay paused state:', err))
  }, [])

  // Handle play/pause
  const handlePlayPause = useCallback(() => {
    if (!audioRef.current) return

    if (isPlaying) {
      audioRef.current.pause()
      setIsPlaying(false)
      updateOverlayPaused(true)
    } else {
      audioRef.current.play().catch((error) => {
        console.error('Playback failed:', error)
        setIsPlaying(false)
      })
      setIsPlaying(true)
      updateOverlayPaused(false)
    }
  }, [isPlaying, updateOverlayPaused])

  // Shuffle array using Fisher-Yates algorithm
  const shuffleArray = useCallback((array: TrackData[]): TrackData[] => {
    const shuffled = [...array]
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      ;[shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]]
    }
    return shuffled
  }, [])

  // Generate shuffled playlist, keeping current track first if playing
  const generateShuffledPlaylist = useCallback(() => {
    const playlist = playlistRef.current
    if (playlist.length === 0) return []

    // If no current track, just shuffle the whole playlist
    if (!currentTrack) {
      return shuffleArray(playlist)
    }

    // Find current track in playlist
    const currentIndex = playlist.findIndex((track) => track.id === currentTrack.id)

    if (currentIndex === -1) {
      return shuffleArray(playlist)
    }

    // Create array without current track, shuffle it, then put current track first
    const otherTracks = playlist.filter((track) => track.id !== currentTrack.id)
    const shuffledOthers = shuffleArray(otherTracks)

    return [currentTrack, ...shuffledOthers]
  }, [currentTrack, shuffleArray])

  // Update overlay Now Playing via API
  const updateNowPlaying = useCallback((trackId: string | null, paused: boolean = false) => {
    const body = trackId ? { track_id: trackId, paused } : { clear: true }
    apiFetch('/api/overlay/now-playing', {
      method: 'POST',
      body: JSON.stringify(body)
    }).catch(err => console.warn('Failed to update overlay now playing:', err))
  }, [])

  // Load and play track
  const loadTrack = useCallback((track: TrackData) => {
    const audio = audioRef.current
    if (!audio) return

    // Pause and reset current playback
    audio.pause()
    setIsPlaying(false)

    // Set new track info
    setCurrentTrack(track)
    setIsVisible(true)

    // Update overlay Now Playing
    updateNowPlaying(track.id)

    // Build playlist from DOM if we don't have one yet or if it's empty
    // This captures all visible tracks when first playing
    if (playlistRef.current.length === 0) {
      const trackElements = document.querySelectorAll('.track-title-clickable')
      const tracks: TrackData[] = []

      trackElements.forEach((el) => {
        const trackEl = el as HTMLElement
        const row = trackEl.closest('.track-row') as HTMLElement

        // Only include visible tracks
        if (row && row.style.display !== 'none') {
          tracks.push({
            id: trackEl.dataset.trackId || '',
            url: trackEl.dataset.trackUrl || '',
            title: trackEl.dataset.trackTitle || '',
            artist: trackEl.dataset.trackArtist || '',
            coverUrl: trackEl.dataset.coverUrl || ''
          })
        }
      })

      playlistRef.current = tracks
    }

    // Set the new source
    audio.src = track.url
    audio.load() // Explicitly load the new source

    // Wait for the audio to be ready, then play
    const onCanPlay = () => {
      audio.play()
        .then(() => {
          setIsPlaying(true)
        })
        .catch((error) => {
          console.error('Playback failed:', error)
          setIsPlaying(false)
        })

      // Remove listener after it fires
      audio.removeEventListener('canplay', onCanPlay)
    }

    audio.addEventListener('canplay', onCanPlay)
  }, [updateNowPlaying])

  // Refresh playlist from current DOM (called when navigating to pulse vault)
  const refreshPlaylist = useCallback(() => {
    const trackElements = document.querySelectorAll('.track-title-clickable')
    const tracks: TrackData[] = []

    trackElements.forEach((el) => {
      const trackEl = el as HTMLElement
      const row = trackEl.closest('.track-row') as HTMLElement

      // Only include visible tracks
      if (row && row.style.display !== 'none') {
        tracks.push({
          id: trackEl.dataset.trackId || '',
          url: trackEl.dataset.trackUrl || '',
          title: trackEl.dataset.trackTitle || '',
          artist: trackEl.dataset.trackArtist || '',
          coverUrl: trackEl.dataset.coverUrl || ''
        })
      }
    })

    playlistRef.current = tracks
  }, [])

  // Refresh UI highlighting (called when navigating back to pulse vault)
  const refreshUI = useCallback(() => {
    // Clear all previous highlighting and reset all buttons
    document.querySelectorAll('.track-row').forEach((row) => {
      const rowEl = row as HTMLElement
      rowEl.style.background = ''

      const titleEl = row.querySelector('.track-title-clickable') as HTMLElement
      if (titleEl) {
        titleEl.style.color = '#ccc'
        const indicator = titleEl.querySelector('.now-playing-indicator') as HTMLElement
        if (indicator) indicator.style.display = 'none'
      }

      const playBtn = row.querySelector('.play-track-btn') as HTMLElement
      if (playBtn) {
        playBtn.textContent = '► PLAY'
        playBtn.style.background = '#7c3aed'
        playBtn.style.color = 'white'
      }
    })

    // Highlight the current track if playing
    if (currentTrack) {
      const currentRow = document.querySelector(`.track-row[data-track-id="${currentTrack.id}"]`) as HTMLElement
      if (currentRow) {
        currentRow.style.background = 'rgba(124, 58, 237, 0.15)'

        const titleEl = currentRow.querySelector('.track-title-clickable') as HTMLElement
        if (titleEl) {
          titleEl.style.color = '#a78bfa'
          const indicator = titleEl.querySelector('.now-playing-indicator') as HTMLElement
          if (indicator) indicator.style.display = 'inline'
        }

        const playBtn = currentRow.querySelector('.play-track-btn') as HTMLElement
        if (playBtn) {
          playBtn.textContent = isPlaying ? '❚❚ PAUSE' : '► PLAY'
          playBtn.style.background = isPlaying ? '#9333ea' : '#7c3aed'
          playBtn.style.color = isPlaying ? '#00d9ff' : 'white'
        }
      }
    }
  }, [currentTrack, isPlaying])

  // Set playlist from React component
  const setPlaylist = useCallback((tracks: TrackData[], stationCtx?: StationContext) => {
    playlistRef.current = tracks
    stationContextRef.current = stationCtx || null
    setStationContext(stationCtx || null)
  }, [])

  // Get current playlist
  const getPlaylist = useCallback(() => {
    return playlistRef.current
  }, [])

  // Get effective playlist (shuffled if shuffle is on, otherwise original)
  const getEffectivePlaylist = useCallback(() => {
    return shuffle ? shuffledPlaylistRef.current : playlistRef.current
  }, [shuffle])

  // Get station context
  const getStationContext = useCallback(() => {
    return stationContextRef.current
  }, [])

  // Play next track in playlist
  const playNext = useCallback(() => {
    // Use shuffled playlist if shuffle is enabled, otherwise use normal playlist
    const playlist = shuffle ? shuffledPlaylistRef.current : playlistRef.current
    if (playlist.length === 0) return

    // Find current track index
    let currentIndex = -1
    for (let i = 0; i < playlist.length; i++) {
      if (playlist[i].id === currentTrack?.id) {
        currentIndex = i
        break
      }
    }

    // Get next track (wrap around to start if at end)
    const nextIndex = (currentIndex + 1) % playlist.length
    const nextTrack = playlist[nextIndex]

    loadTrack(nextTrack)
  }, [currentTrack, loadTrack, shuffle])

  // Play previous track in playlist
  const playPrevious = useCallback(() => {
    // Use shuffled playlist if shuffle is enabled, otherwise use normal playlist
    const playlist = shuffle ? shuffledPlaylistRef.current : playlistRef.current
    if (playlist.length === 0) return

    // Find current track index
    let currentIndex = -1
    for (let i = 0; i < playlist.length; i++) {
      if (playlist[i].id === currentTrack?.id) {
        currentIndex = i
        break
      }
    }

    // Get previous track (wrap around to end if at start)
    const previousIndex = currentIndex <= 0 ? playlist.length - 1 : currentIndex - 1
    const previousTrack = playlist[previousIndex]

    loadTrack(previousTrack)
  }, [currentTrack, loadTrack, shuffle])

  // Toggle shuffle mode
  const toggleShuffle = useCallback(() => {
    const newShuffleState = !shuffle
    setShuffle(newShuffleState)

    // If enabling shuffle, generate shuffled playlist
    if (newShuffleState) {
      shuffledPlaylistRef.current = generateShuffledPlaylist()
    }
  }, [shuffle, generateShuffledPlaylist])

  // Check if shuffle is enabled
  const isShuffle = useCallback(() => {
    return shuffle
  }, [shuffle])

  // Expose API to vanilla JS and React context
  useEffect(() => {
    const api: AudioPlayerAPI = {
      loadTrack,
      togglePlayPause: handlePlayPause,
      playNext,
      playPrevious,
      getCurrentTrackId: () => currentTrack?.id || null,
      isPlaying: () => isPlaying,
      setPlaylist,
      getPlaylist,
      getEffectivePlaylist,
      getStationContext,
      refreshPlaylist,
      refreshUI,
      toggleShuffle,
      isShuffle
    }
    window.audioPlayer = api

    // Notify parent component that API is ready
    if (onReady) {
      onReady(api)
    }

    return () => {
      delete window.audioPlayer
    }
  }, [loadTrack, handlePlayPause, playNext, playPrevious, currentTrack, isPlaying, setPlaylist, getPlaylist, getEffectivePlaylist, getStationContext, onReady, refreshPlaylist, refreshUI, toggleShuffle, isShuffle])

  // Update track table UI when current track or playing state changes
  useEffect(() => {
    refreshUI()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [currentTrack, isPlaying])

  // Handle seek start (when user starts dragging)
  const handleSeekStart = useCallback(() => {
    setIsSeeking(true)
  }, [])

  // Handle seek (while dragging)
  const handleSeek = useCallback((time: number) => {
    if (audioRef.current) {
      audioRef.current.currentTime = time
      setCurrentTime(time) // Update displayed time immediately
    }
  }, [])

  // Handle seek end (when user releases)
  const handleSeekEnd = useCallback(() => {
    setIsSeeking(false)
  }, [])

  // Handle volume change
  const handleVolumeChange = useCallback((newVolume: number) => {
    setVolume(newVolume)
    if (audioRef.current) {
      audioRef.current.volume = newVolume
    }
  }, [])

  // Handle close
  const handleClose = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause()
    }
    setIsVisible(false)
    setIsPlaying(false)
    setCurrentTrack(null)
    // Clear overlay Now Playing
    updateNowPlaying(null)
  }, [updateNowPlaying])

  // Handle keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Spacebar to play/pause (only if not typing in an input)
      if (
        e.key === ' ' &&
        currentTrack &&
        !(e.target instanceof HTMLInputElement) &&
        !(e.target instanceof HTMLTextAreaElement)
      ) {
        e.preventDefault()
        handlePlayPause()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [currentTrack, handlePlayPause])

  // Audio event handlers
  useEffect(() => {
    const audio = audioRef.current
    if (!audio) return

    const handleTimeUpdate = () => {
      // Only update time if not currently seeking to avoid conflicts
      if (!isSeeking) {
        setCurrentTime(audio.currentTime)
      }

      // Achievement: credit a track play once 30s of actual playback has
      // been accumulated. Seeking past the mark does not count — we only
      // add the delta between samples when it's a small forward step
      // (< 2s), indicating real playback progression rather than a jump.
      const track = currentTrack
      if (track && !creditedTrackIdsRef.current.has(track.id)) {
        const last = lastPlaybackPosRef.current
        const now = audio.currentTime
        if (last && last.id === track.id) {
          const delta = now - last.time
          if (delta > 0 && delta < 2) {
            const prev = playedSecondsByTrackRef.current.get(track.id) || 0
            const accumulated = prev + delta
            playedSecondsByTrackRef.current.set(track.id, accumulated)
            if (accumulated >= 30) {
              creditedTrackIdsRef.current.add(track.id)
              apiFetch(`/api/tracks/${encodeURIComponent(track.id)}/play_credit`, { method: 'POST' })
                .catch(err => console.warn('play_credit failed:', err))
            }
          }
        }
        lastPlaybackPosRef.current = { id: track.id, time: now }
      }
    }

    const handleLoadedMetadata = () => setDuration(audio.duration)

    const handleEnded = () => {
      setIsPlaying(false)

      // Auto-play next track from stored playlist (use shuffled if shuffle is enabled)
      const playlist = shuffle ? shuffledPlaylistRef.current : playlistRef.current

      if (playlist.length === 0) return

      // Find current track index in playlist
      let currentIndex = -1
      for (let i = 0; i < playlist.length; i++) {
        if (playlist[i].id === currentTrack?.id) {
          currentIndex = i
          break
        }
      }

      // Get next track (wrap around to start if at end)
      const nextIndex = (currentIndex + 1) % playlist.length
      const nextTrack = playlist[nextIndex]

      loadTrack(nextTrack)
    }

    // Handle stalled playback - browser is trying to fetch media but data is unavailable
    // This event is normal during initial buffering; the browser will keep retrying.
    // The watchdog timer handles truly stuck playback — no need to reload here.
    const handleStalled = () => {
      console.warn('Audio playback stalled — browser is rebuffering, waiting for data...')
    }

    // Handle waiting - playback stopped due to temporary lack of data
    const handleWaiting = () => {
      console.log('Audio waiting for data...')
    }

    // Handle error events
    const handleError = () => {
      const error = audio.error
      if (error) {
        console.error('Audio error:', error.code, error.message)
        // For network errors (code 2), attempt to reload after a short delay
        if (error.code === 2) {
          const currentPos = audio.currentTime
          setTimeout(() => {
            console.log('Attempting to recover from network error...')
            audio.load()
            audio.currentTime = currentPos
            if (isPlaying) {
              audio.play().catch((err) => {
                console.error('Failed to resume after network error:', err)
              })
            }
          }, 1000)
        }
      }
    }

    // Handle pause events not triggered by user (e.g., browser intervention)
    const handlePause = () => {
      // Only react if we think we should be playing
      if (isPlaying && !audio.ended) {
        // Check if this was a user-initiated pause or browser intervention
        // Browser interventions typically happen when the tab is backgrounded
        // We'll attempt to resume after a brief delay
        setTimeout(() => {
          if (isPlaying && audio.paused && !audio.ended) {
            console.log('Detected unexpected pause, attempting to resume...')
            audio.play().catch((error) => {
              console.warn('Could not auto-resume:', error)
              setIsPlaying(false)
            })
          }
        }, 100)
      }
    }

    audio.addEventListener('timeupdate', handleTimeUpdate)
    audio.addEventListener('loadedmetadata', handleLoadedMetadata)
    audio.addEventListener('ended', handleEnded)
    audio.addEventListener('stalled', handleStalled)
    audio.addEventListener('waiting', handleWaiting)
    audio.addEventListener('error', handleError)
    audio.addEventListener('pause', handlePause)

    // Set initial volume
    audio.volume = volume

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate)
      audio.removeEventListener('loadedmetadata', handleLoadedMetadata)
      audio.removeEventListener('ended', handleEnded)
      audio.removeEventListener('stalled', handleStalled)
      audio.removeEventListener('waiting', handleWaiting)
      audio.removeEventListener('error', handleError)
      audio.removeEventListener('pause', handlePause)
    }
  }, [volume, isSeeking, currentTrack, loadTrack, shuffle, isPlaying])

  // Update document title with current track info
  useEffect(() => {
    if (isPlaying && currentTrack) {
      if (stationContext) {
        document.title = `${stationContext.name} | hackr.tv`
      } else {
        document.title = `${currentTrack.title} — ${currentTrack.artist} | hackr.tv`
      }
    } else {
      document.title = 'hackr.tv'
    }
  }, [isPlaying, currentTrack, stationContext])

  // Watchdog: detect if playback has silently stalled (no events fired)
  // This catches HTTP connection timeouts that don't trigger browser events
  useEffect(() => {
    if (!isPlaying || !currentTrack) return

    const audio = audioRef.current
    if (!audio) return

    // Check every 5 seconds if playback is progressing
    const watchdogInterval = setInterval(() => {
      // If we're supposed to be playing but time hasn't advanced in 5 seconds
      // and we're not at the end of the track, something is wrong
      if (isPlaying && !audio.paused && !audio.ended) {
        const currentPos = audio.currentTime
        const timeDiff = currentPos - lastTimeRef.current

        // If time hasn't moved at all (or moved backwards, which shouldn't happen)
        // and we're not near the end, attempt recovery
        if (timeDiff <= 0 && currentPos < duration - 1) {
          console.warn('Watchdog: Playback appears stalled, attempting recovery...')
          // Try to resume from current position
          audio.load()
          audio.currentTime = currentPos
          audio.play().catch((error) => {
            console.error('Watchdog: Failed to resume playback:', error)
            setIsPlaying(false)
          })
        }

        lastTimeRef.current = currentPos
      }
    }, 5000)

    return () => clearInterval(watchdogInterval)
  }, [isPlaying, currentTrack, duration])

  return (
    <>
      {(isVisible || currentTrack) && (
        <PlayerBar
          isPlaying={isPlaying}
          currentTrack={currentTrack}
          currentTime={currentTime}
          duration={duration}
          volume={volume}
          stationContext={stationContext}
          shuffle={shuffle}
          onPlayPause={handlePlayPause}
          onNext={playNext}
          onPrevious={playPrevious}
          onSeekStart={handleSeekStart}
          onSeek={handleSeek}
          onSeekEnd={handleSeekEnd}
          onVolumeChange={handleVolumeChange}
          onToggleShuffle={toggleShuffle}
          onClose={handleClose}
        />
      )}
      <audio ref={audioRef} id="audio-element" preload="auto" style={{ display: 'none' }} />
    </>
  )
}
