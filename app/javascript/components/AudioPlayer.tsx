import React, { useEffect, useRef, useState, useCallback } from 'react'
import { PlayerBar } from './PlayerBar.tsx'
import type { TrackData, AudioPlayerAPI, StationContext } from '~/types/track.ts'

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

  // Handle play/pause
  const handlePlayPause = useCallback(() => {
    if (!audioRef.current) return

    if (isPlaying) {
      audioRef.current.pause()
      setIsPlaying(false)
    } else {
      audioRef.current.play().catch((error) => {
        console.error('Playback failed:', error)
        setIsPlaying(false)
      })
      setIsPlaying(true)
    }
  }, [isPlaying])

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
  }, [])

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
  }, [loadTrack, handlePlayPause, playNext, playPrevious, currentTrack, isPlaying, setPlaylist, getPlaylist, getStationContext, onReady, refreshPlaylist, refreshUI, toggleShuffle, isShuffle])

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
  }, [])

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

    audio.addEventListener('timeupdate', handleTimeUpdate)
    audio.addEventListener('loadedmetadata', handleLoadedMetadata)
    audio.addEventListener('ended', handleEnded)

    // Set initial volume
    audio.volume = volume

    return () => {
      audio.removeEventListener('timeupdate', handleTimeUpdate)
      audio.removeEventListener('loadedmetadata', handleLoadedMetadata)
      audio.removeEventListener('ended', handleEnded)
    }
  }, [volume, isSeeking, currentTrack, loadTrack, shuffle])

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
      <audio ref={audioRef} id="audio-element" style={{ display: 'none' }} />
    </>
  )
}
