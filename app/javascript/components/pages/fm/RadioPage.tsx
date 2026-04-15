import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import type { TrackData } from '~/types/track'
import { CodexText } from '~/components/shared/CodexText'
import { useStreamStatus } from '~/hooks/useStreamStatus'
import { apiFetch, apiJson } from '~/utils/apiClient'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useHackrScopedDedupSet } from '~/hooks/useHackrScopedDedup'

interface Playlist {
  id: number
  name: string
  track_count: number
}

interface PlaylistTrack {
  track_id: number
  audio_url: string
  title: string
  artist: {
    name: string
  }
  release?: {
    cover_url: string | null
    cover_urls?: { thumbnail: string; standard: string; full: string }
  }
  duration: string | null
}

interface RadioStation {
  id: number
  name: string
  slug: string
  description: string
  genre: string
  stream_url: string
  color: string
  playlists: Playlist[]
}

interface StationPlaylist {
  id: number
  name: string
  tracks?: PlaylistTrack[]
}

export const RadioPage: React.FC = () => {
  const { hackr } = useGridAuth()
  const [stations, setStations] = useState<RadioStation[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [currentStation, setCurrentStation] = useState<{ name: string; genre: string } | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const audioRef = React.useRef<HTMLAudioElement>(null)
  const [volume, setVolume] = useState(70)
  const [playingStationId, setPlayingStationId] = useState<number | null>(null)
  const [audioPlayerIsPlaying, setAudioPlayerIsPlaying] = useState(false)
  // Dedup is scoped to hackr.id — auto-resets on logout/login swap so
  // a second user isn't silenced by the prior user's credits.
  const tunedStationIdsRef = useHackrScopedDedupSet<number>(hackr?.id)
  const { isLive, streamInfo } = useStreamStatus()

  // --- Dual-playback architecture ---------------------------------
  // Radio stations come in two flavors, each with its own audio
  // backend — a given station uses exactly one:
  //
  //   1. Playlist-backed (station.playlists.length > 0) — plays
  //      through the SHARED global `window.audioPlayer` (same
  //      instance that drives the Pulse Vault). Tune credit fires
  //      from the useEffect below, which watches the player's
  //      `playingStationId` + `isPlaying` state (polled every 500ms).
  //
  //   2. Raw stream URL (station.stream_url set, no playlists) —
  //      plays through a LOCAL `<audio ref={audioRef}>` element
  //      inside this component. Tune credit fires from the direct
  //      `play().then()` signal inside `tuneIn()` further down.
  //
  // The two paths are dispatched by the render (see the station
  // card JSX: `station.playlists?.length ? <playlist> : <stream>`).
  // `tunedStationIdsRef` guards against a user stopping + re-tuning
  // the SAME station, not against a cross-path double-fire — a
  // single station only ever uses one path.
  //
  // Fire tune_in POST once per station per hackr when playback starts.
  const creditTuneIn = React.useCallback((stationId: number) => {
    if (!hackr || tunedStationIdsRef.current.has(stationId)) return
    tunedStationIdsRef.current.add(stationId)
    apiFetch(`/api/radio_stations/${stationId}/tune_in`, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }, [hackr, tunedStationIdsRef])

  // Path 1 — playlist-backed stations. Credit only when audio is
  // actually playing. `playingStationId` alone proves nothing more
  // than `setPlaylist` was called, which can race ahead of playback
  // failure (bad audio URL, autoplay blocked, etc.). Requiring the
  // `audioPlayerIsPlaying` signal filters those out.
  useEffect(() => {
    if (playingStationId != null && audioPlayerIsPlaying) {
      creditTuneIn(playingStationId)
    }
  }, [playingStationId, audioPlayerIsPlaying, creditTuneIn])

  useEffect(() => {
    apiJson<RadioStation[]>('/api/radio_stations')
      .then(data => {
        setStations(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Failed to load stations')
        setLoading(false)
      })
  }, [])

  // Poll audio player for current station context
  useEffect(() => {
    const interval = setInterval(() => {
      if (window.audioPlayer) {
        const stationContext = window.audioPlayer.getStationContext()
        const isCurrentlyPlaying = window.audioPlayer.isPlaying()
        setPlayingStationId(stationContext?.id || null)
        setAudioPlayerIsPlaying(isCurrentlyPlaying)
      }
    }, 500)

    return () => clearInterval(interval)
  }, [])

  const currentYear = new Date().getFullYear()
  const futureYear = currentYear + 100

  // Replace year placeholder in station description
  const renderDescription = (description: string) => {
    return description.replace('2125', futureYear.toString())
  }

  const playStationPlaylists = async (station: RadioStation) => {
    // If this station is already playing, just toggle play/pause
    if (playingStationId === station.id && window.audioPlayer) {
      window.audioPlayer.togglePlayPause()
      return
    }

    if (!station.playlists || station.playlists.length === 0) {
      alert('This station has no playlists configured yet.')
      return
    }

    try {
      // Fetch all playlists for this radio station (public endpoint)
      const playlists = await apiJson<StationPlaylist[]>(`/api/radio_stations/${station.id}/playlists`)

      if (!playlists || playlists.length === 0) {
        alert('No playlists found for this station.')
        return
      }

      // Collect all tracks from all playlists in order
      const allTracks: TrackData[] = []

      for (const playlist of playlists) {
        if (playlist.tracks && playlist.tracks.length > 0) {
          const playlistTracks = playlist.tracks
            .map((track: PlaylistTrack) => ({
              id: String(track.track_id),
              url: track.audio_url || '',
              title: track.title,
              artist: track.artist.name,
              coverUrl: track.release?.cover_url || '',
              coverUrls: track.release?.cover_urls,
              duration: track.duration
            }))
            .filter((track: TrackData) => track.url) // Only include tracks with audio

          allTracks.push(...playlistTracks)
        }
      }

      if (allTracks.length === 0) {
        alert('No playable tracks found in station playlists.')
        return
      }

      // Pick a random track to simulate tuning into a live radio station
      // eslint-disable-next-line react-hooks/purity -- this runs in an event handler, not during render
      const randomIndex = Math.floor(Math.random() * allTracks.length)
      const randomTrack = allTracks[randomIndex]

      // Set playlist and play random track using the global audio player
      if (window.audioPlayer) {
        window.audioPlayer.setPlaylist(allTracks, {
          id: station.id,
          name: station.name
        })

        // Radio stations always play in shuffle mode
        if (!window.audioPlayer.isShuffle()) {
          window.audioPlayer.toggleShuffle()
        }

        // Get audio element and set up listener for when metadata loads
        const audio = document.getElementById('audio-element') as HTMLAudioElement
        if (audio) {
          // Pause immediately to prevent playback
          audio.pause()

          // Listen for loadedmetadata event to know when duration is available
          const onMetadataLoaded = () => {
            if (audio.duration && !isNaN(audio.duration)) {
              // Seek to random position (between 0% and 70% of the track)
              const randomPosition = Math.random() * audio.duration * 0.7
              audio.currentTime = randomPosition

              // Now play from the random position
              audio.play()
            }
            audio.removeEventListener('loadedmetadata', onMetadataLoaded)
          }

          audio.addEventListener('loadedmetadata', onMetadataLoaded)
        }

        // Load the track (this will trigger metadata loading)
        window.audioPlayer.loadTrack(randomTrack)
      }
    } catch (error) {
      console.error('Error loading station playlists:', error)
      alert('Failed to load station playlists. Please try again.')
    }
  }

  // Path 2 — raw-stream stations (see dual-playback block above).
  // Uses the local `audioRef` element; credits inside `.then()` so
  // autoplay rejections / bad stream URLs do NOT advance the counter.
  const tuneIn = (streamUrl: string, stationName: string, genre: string, stationId?: number) => {
    if (!audioRef.current) return

    audioRef.current.src = streamUrl
    setCurrentStation({ name: stationName, genre })
    setIsPlaying(true)

    audioRef.current.play()
      .then(() => {
        if (stationId != null) creditTuneIn(stationId)
      })
      .catch((error) => {
        console.error('Error playing stream:', error)
        alert('Error: Unable to connect to radio stream. Please check the stream URL.')
      })
  }

  const stopRadio = () => {
    if (!audioRef.current) return

    audioRef.current.pause()
    audioRef.current.currentTime = 0
    audioRef.current.src = ''
    setIsPlaying(false)
    setCurrentStation(null)
  }

  const handleVolumeChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newVolume = parseInt(e.target.value)
    setVolume(newVolume)
    if (audioRef.current) {
      audioRef.current.volume = newVolume / 100
    }
  }

  React.useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume / 100
    }
  }, [volume])

  return (
    <FmLayout>
      <div className="tui-window cyan-168 white-text" style={{ maxWidth: '1200px', margin: '0 auto', display: 'block' }}>
        <fieldset className="cyan-168-border">
          <legend className="center">hackr.fm :: RADIO</legend>

          <div>
            <h2 className="cyan-255-text" style={{ textAlign: 'center', marginBottom: '15px' }}>
              [:: FRACTURE NETWORK RADIO STATIONS ::]
            </h2>

            {loading && <LoadingSpinner message="Tuning radio frequencies..." color="cyan-255-text" />}
            {error && <p style={{ textAlign: 'center', padding: '40px', color: '#ff5555' }}>Error: {error}</p>}

            {!loading && !error && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '20px' }}>
                {stations.map((station) => {
                  const isTCP = station.slug === 'thecyberpulse'
                  const isSectorX = station.slug === 'sector-x'

                  if (isTCP && isLive) {
                    return (
                      <div key={station.slug} className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #00d9ff' }}>
                        <fieldset style={{ borderColor: '#00d9ff' }}>
                          <legend style={{ color: '#00d9ff' }}>{station.name}</legend>

                          <div style={{ padding: '15px' }}>
                            <div style={{ marginBottom: '10px' }}>
                              <span className="live-indicator" style={{ color: '#ff3333', fontWeight: 'bold', fontSize: '0.9em', marginRight: '10px' }}>● LIVE NOW</span>
                              <span style={{ color: '#00d9ff', fontWeight: 'bold' }}>
                                {streamInfo?.artist ? `${streamInfo.artist} is streaming` : 'Stream active'}
                              </span>
                            </div>
                            {streamInfo?.title && (
                              <p style={{ marginBottom: '10px', color: '#aaa' }}>
                                {streamInfo.title}
                              </p>
                            )}
                            <p style={{ marginBottom: '15px', lineHeight: '1.6', color: '#999' }}>
                              <CodexText>A live transmission is cutting through the noise. Tune in now on the root frequency.</CodexText>
                            </p>

                            <Link
                              to="/"
                              className="tui-button tune-in-btn"
                              style={{
                                display: 'block',
                                width: '100%',
                                textAlign: 'center',
                                background: '#ff3333',
                                color: 'white',
                                boxShadow: '10px 10px #333',
                                textDecoration: 'none'
                              }}
                            >
                              ▶ WATCH LIVE
                            </Link>
                          </div>
                        </fieldset>
                      </div>
                    )
                  }

                  if (isSectorX) {
                    return (
                      <div key={station.slug} className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #444' }}>
                        <fieldset style={{ borderColor: '#555' }}>
                          <legend style={{ color: '#14b8a6' }}>{station.name}</legend>

                          <div style={{ padding: '15px' }}>
                            {station.playlists && station.playlists.length > 0 && (
                              <div style={{ marginBottom: '10px' }}>
                                <span className="live-indicator" style={{ color: '#14b8a6', fontWeight: 'bold', fontSize: '0.9em', marginRight: '10px' }}>● LIVE</span>
                                <span style={{ color: '#888' }}>
                                  <strong>Genre:</strong> <span style={{ color: '#aaa' }}>{station.genre}</span>
                                </span>
                              </div>
                            )}
                            {(!station.playlists || station.playlists.length === 0) && (
                              <p style={{ marginBottom: '10px', color: '#888' }}>
                                <strong>Genre:</strong> <span style={{ color: '#aaa' }}>{station.genre}</span>
                              </p>
                            )}
                            <p style={{ marginBottom: '15px', lineHeight: '1.6', color: '#999' }}>
                              <CodexText>{renderDescription(station.description)}</CodexText>
                            </p>

                            {station.playlists && station.playlists.length > 0 ? (
                              <button
                                className="tui-button tune-in-btn"
                                onClick={() => playStationPlaylists(station)}
                                style={{
                                  width: '100%',
                                  background: playingStationId === station.id ? '#0d9488' : '#14b8a6',
                                  color: 'white',
                                  boxShadow: '10px 10px #333'
                                }}
                              >
                                {playingStationId === station.id
                                  ? (audioPlayerIsPlaying ? '❚❚ PAUSE' : '▶ RESUME')
                                  : '▶ PLAY STATION'}
                              </button>
                            ) : station.stream_url ? (
                              <button
                                className="tui-button tune-in-btn"
                                onClick={() => tuneIn(station.stream_url, station.name, station.genre, station.id)}
                                style={{ width: '100%', background: '#14b8a6', color: 'white' }}
                              >
                                ► TUNE IN
                              </button>
                            ) : (
                              <button
                                className="tui-button"
                                style={{ width: '100%', opacity: 0.5, cursor: 'not-allowed' }}
                                disabled
                              >
                                [COMING SOON]
                              </button>
                            )}
                          </div>
                        </fieldset>
                      </div>
                    )
                  }

                  return (
                    <div key={station.slug} className={`tui-window ${station.color} white-text`}>
                      <fieldset className={`${station.color}-border`}>
                        <legend>{station.name}</legend>

                        <div style={{ padding: '15px' }}>
                          {station.playlists && station.playlists.length > 0 && (
                            <div style={{ marginBottom: '10px' }}>
                              <span className="live-indicator" style={{ color: '#00d9ff', fontWeight: 'bold', fontSize: '0.9em', marginRight: '10px' }}>● LIVE</span>
                              <span>
                                <strong>Genre:</strong> {station.genre}
                              </span>
                            </div>
                          )}
                          {(!station.playlists || station.playlists.length === 0) && (
                            <p style={{ marginBottom: '10px' }}>
                              <strong>Genre:</strong> {station.genre}
                            </p>
                          )}
                          <p style={{ marginBottom: '15px', lineHeight: '1.6' }}>
                            <CodexText>{renderDescription(station.description)}</CodexText>
                          </p>

                          {station.playlists && station.playlists.length > 0 ? (
                            <button
                              className="tui-button tune-in-btn"
                              onClick={() => playStationPlaylists(station)}
                              style={{
                                width: '100%',
                                background: playingStationId === station.id ? '#9333ea' : '#222',
                                color: 'white'
                              }}
                            >
                              {playingStationId === station.id
                                ? (audioPlayerIsPlaying ? '❚❚ PAUSE' : '▶ RESUME')
                                : '▶ PLAY STATION'}
                            </button>
                          ) : station.stream_url ? (
                            <button
                              className="tui-button tune-in-btn"
                              onClick={() => tuneIn(station.stream_url, station.name, station.genre, station.id)}
                              style={{ width: '100%', background: '#222', color: 'white' }}
                            >
                              ► TUNE IN
                            </button>
                          ) : (
                            <button
                              className="tui-button"
                              style={{ width: '100%', opacity: 0.5, cursor: 'not-allowed' }}
                              disabled
                            >
                              [COMING SOON]
                            </button>
                          )}
                        </div>
                      </fieldset>
                    </div>
                  )
                })}
              </div>
            )}

            <div style={{ marginTop: '30px', padding: '20px', background: '#1a1a1a', border: '1px solid #444' }}>
              <h3 className="cyan-255-text" style={{ marginBottom: '10px' }}>[:: BROADCAST INFO ::]</h3>
              <p style={{ lineHeight: '1.6', color: '#ccc' }}>
                hackr.fm Radio transmits 24/7 from undisclosed locations across THE PULSE GRID.
                Each station is a beacon of the Fracture Network, broadcasting truth through the digital noise.
                Select a station above to begin streaming.
              </p>
            </div>
          </div>
        </fieldset>
      </div>

      {/* Radio Player */}
      {isPlaying && currentStation && (
        <div style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          background: '#0a0a0a',
          borderTop: '2px solid #00d9ff',
          padding: '15px 20px',
          zIndex: 1000
        }}>
          <div style={{ maxWidth: '1200px', margin: '0 auto' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
              <button
                className="tui-button"
                onClick={stopRadio}
                style={{ background: '#00d9ff', color: '#000', minWidth: '80px', fontWeight: 'bold' }}
              >
                ■ STOP
              </button>

              <div style={{ flex: 1 }}>
                <div style={{ marginBottom: '5px' }}>
                  <span style={{ color: '#00d9ff', fontWeight: 'bold' }}>● LIVE</span>
                  <span style={{ color: '#666', margin: '0 10px' }}>|</span>
                  <span style={{ color: '#00d9ff', fontWeight: 'bold' }}>{currentStation.name}</span>
                </div>
                <div>
                  <span style={{ color: '#888', fontSize: '0.9em' }}>Genre: </span>
                  <span style={{ color: '#aaa', fontSize: '0.9em' }}>{currentStation.genre}</span>
                </div>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <span style={{ color: '#888', fontSize: '0.9em' }}>Volume:</span>
                <input
                  type="range"
                  min="0"
                  max="100"
                  value={volume}
                  onChange={handleVolumeChange}
                  style={{
                    width: '100px',
                    height: '6px',
                    background: '#333',
                    borderRadius: '3px',
                    outline: 'none',
                    WebkitAppearance: 'none'
                  }}
                />
              </div>

              <button
                className="tui-button"
                onClick={stopRadio}
                style={{ background: '#444', color: '#aaa' }}
              >
                ✕
              </button>
            </div>
          </div>
        </div>
      )}

      <audio ref={audioRef} preload="none" />

      <style>{`
        @keyframes livePulse {
          0%, 100% {
            opacity: 1;
          }
          50% {
            opacity: 0.3;
          }
        }

        .live-indicator {
          animation: livePulse 4s ease-in-out infinite;
        }

        input[type="range"]::-webkit-slider-thumb {
          -webkit-appearance: none;
          appearance: none;
          width: 14px;
          height: 14px;
          background: #00d9ff;
          cursor: pointer;
          border-radius: 50%;
        }

        input[type="range"]::-moz-range-thumb {
          width: 14px;
          height: 14px;
          background: #00d9ff;
          cursor: pointer;
          border-radius: 50%;
          border: none;
        }
      `}</style>
    </FmLayout>
  )
}
