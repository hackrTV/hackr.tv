import React, { useState } from 'react'
import { useAudio } from '~/contexts/AudioContext'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { AddToPlaylistDropdown } from '~/components/playlists/AddToPlaylistDropdown'

interface Track {
  id: number
  title: string
  artist: { name: string; genre: string | null }
  album: { name: string; cover_url: string | null }
  audio_url: string | null
}

interface TrackTableProps {
  tracks: Track[]
  initialFilter?: string
}

export const TrackTable: React.FC<TrackTableProps> = ({ tracks, initialFilter = '' }) => {
  const { audioPlayerAPI } = useAudio()
  const { isLoggedIn } = useGridAuth()
  const { isMobile } = useMobileDetect()
  const [filter, setFilter] = useState(initialFilter)
  const [currentTrackId, setCurrentTrackId] = useState<number | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)

  // Update filter when initialFilter prop changes (e.g., navigating from bands page)
  React.useEffect(() => {
    setFilter(initialFilter)
  }, [initialFilter])

  const filteredTracks = tracks.filter(track => {
    const searchTerm = filter.toLowerCase()
    return (
      track.title.toLowerCase().includes(searchTerm) ||
      track.artist.name.toLowerCase().includes(searchTerm) ||
      track.album.name.toLowerCase().includes(searchTerm) ||
      (track.artist.genre && track.artist.genre.toLowerCase().includes(searchTerm))
    )
  })

  const handlePlayTrack = (track: Track) => {
    if (!track.audio_url || !audioPlayerAPI.current) return

    const trackIdStr = track.id.toString()

    // If clicking the currently playing track, toggle play/pause
    if (currentTrackId === track.id) {
      audioPlayerAPI.current.togglePlayPause()
    } else {
      // Build playlist from current filtered tracks
      const playableFilteredTracks = filteredTracks
        .filter(track => track.audio_url)
        .map(track => ({
          id: track.id.toString(),
          url: track.audio_url!,
          title: track.title,
          artist: track.artist.name,
          coverUrl: track.album.cover_url || ''
        }))

      // Check if switching from radio station before setting new playlist
      const wasPlayingRadio = audioPlayerAPI.current.getStationContext() !== null

      // Set the playlist ONLY when user clicks to play a track
      audioPlayerAPI.current.setPlaylist(playableFilteredTracks)

      // Turn off shuffle only when switching from radio station to Pulse Vault
      if (wasPlayingRadio && audioPlayerAPI.current.isShuffle()) {
        audioPlayerAPI.current.toggleShuffle()
      }

      // Load and play the selected track
      audioPlayerAPI.current.loadTrack({
        id: trackIdStr,
        url: track.audio_url,
        title: track.title,
        artist: track.artist.name,
        coverUrl: track.album.cover_url || ''
      })
      setCurrentTrackId(track.id)
      setIsPlaying(true)
    }
  }

  // Listen for play/pause state changes from audio player
  React.useEffect(() => {
    const updatePlayState = () => {
      if (audioPlayerAPI.current) {
        const trackId = audioPlayerAPI.current.getCurrentTrackId()
        const playing = audioPlayerAPI.current.isPlaying()
        setCurrentTrackId(trackId ? parseInt(trackId) : null)
        setIsPlaying(playing)
      }
    }

    // Poll for state changes
    const interval = setInterval(updatePlayState, 500)
    return () => clearInterval(interval)
  }, [audioPlayerAPI])

  // Mobile card view for a single track
  const renderMobileTrackCard = (track: Track) => {
    const isCurrentTrack = currentTrackId === track.id
    const isActive = isCurrentTrack && isPlaying

    return (
      <div
        key={track.id}
        onClick={() => track.audio_url && handlePlayTrack(track)}
        style={{
          display: 'flex',
          alignItems: 'center',
          padding: '10px 12px',
          borderBottom: '1px solid #333',
          opacity: track.audio_url ? 1 : 0.4,
          cursor: track.audio_url ? 'pointer' : 'default',
          backgroundColor: isActive ? 'rgba(124, 58, 237, 0.15)' : 'transparent',
          gap: '10px'
        }}
      >
        {/* Album cover or play button */}
        <div style={{ flexShrink: 0, width: '40px', height: '40px', position: 'relative' }}>
          {track.album.cover_url ? (
            <>
              <img
                src={track.album.cover_url}
                alt={track.album.name}
                style={{
                  width: '40px',
                  height: '40px',
                  objectFit: 'cover',
                  border: isActive ? '2px solid #7c3aed' : '1px solid #444',
                  borderRadius: '2px'
                }}
              />
              {/* Play/pause overlay on cover */}
              {track.audio_url && (
                <div
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '40px',
                    height: '40px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    background: isActive ? 'rgba(124, 58, 237, 0.7)' : 'rgba(0, 0, 0, 0.5)',
                    color: '#fff',
                    fontSize: '14px',
                    borderRadius: '2px'
                  }}
                >
                  {isActive ? '❚❚' : '►'}
                </div>
              )}
            </>
          ) : (
            // Fallback: just play button if no cover
            track.audio_url ? (
              <button
                className="tui-button"
                onClick={(e) => {
                  e.stopPropagation()
                  handlePlayTrack(track)
                }}
                style={{
                  width: '40px',
                  height: '40px',
                  padding: 0,
                  fontSize: '1em',
                  background: isActive ? '#7c3aed' : '#333',
                  color: isActive ? '#fff' : '#aaa'
                }}
              >
                {isActive ? '❚❚' : '►'}
              </button>
            ) : (
              <div style={{
                width: '40px',
                height: '40px',
                background: '#222',
                border: '1px solid #444',
                borderRadius: '2px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#555'
              }}>
                -
              </div>
            )
          )}
        </div>

        {/* Track info */}
        <div style={{ flex: 1, minWidth: 0, overflow: 'hidden' }}>
          <div style={{
            color: isActive ? '#00ffff' : '#ccc',
            fontWeight: 'bold',
            fontSize: '0.95em',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis'
          }}>
            {track.title}
          </div>
          <div style={{
            color: isActive ? '#00ffff' : '#888',
            fontSize: '0.85em',
            whiteSpace: 'nowrap',
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            marginTop: '2px'
          }}>
            {track.artist.name}
          </div>
        </div>

        {/* Add to playlist button */}
        {isLoggedIn && track.audio_url && (
          <div onClick={(e) => { e.stopPropagation() }} style={{ flexShrink: 0 }}>
            <AddToPlaylistDropdown
              trackId={track.id}
              trackTitle={track.title}
              buttonText="+"
            />
          </div>
        )}
      </div>
    )
  }

  return (
    <div>
      <div style={{ marginBottom: isMobile ? '12px' : '20px' }}>
        <label htmlFor="track-search" style={{ color: '#888', display: 'block', marginBottom: '8px', fontSize: isMobile ? '0.85em' : '1em' }}>
          {isMobile ? 'SEARCH TRACKS' : 'SEARCH TRACKS :: Filter by track, artist, album, or genre'}
        </label>
        <input
          type="text"
          id="track-search"
          placeholder={isMobile ? 'Filter...' : 'Type to filter tracks...'}
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{
            width: '100%',
            padding: isMobile ? '12px' : '10px',
            background: '#0a0a0a',
            border: '1px solid #555',
            color: '#ccc',
            fontFamily: 'monospace',
            fontSize: isMobile ? '16px' : '1em' // 16px prevents iOS zoom on focus
          }}
        />
      </div>

      <div className="tui-fieldset" style={{ borderColor: '#555' }}>
        <legend style={{ color: '#888', fontSize: isMobile ? '0.85em' : '1em' }}>
          {isMobile ? `TRACKS (${filteredTracks.length})` : 'TRACK LIBRARY'}
        </legend>

        {isMobile ? (
          // Mobile: Card-based list view
          <div style={{ maxHeight: '60vh', overflowY: 'auto' }}>
            {filteredTracks.map(renderMobileTrackCard)}
          </div>
        ) : (
          // Desktop: Full table view
          <table className="tui-table" style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 2px' }}>
            <thead>
              <tr>
                <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Track</th>
                <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Artist</th>
                <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Album</th>
                <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Genre</th>
                <th style={{ textAlign: 'center', color: '#888', width: '120px', minWidth: '120px' }}>Stream</th>
                {isLoggedIn && <th style={{ textAlign: 'center', color: '#888', width: '60px', minWidth: '60px' }}>&nbsp;</th>}
              </tr>
            </thead>
            <tbody>
              {filteredTracks.map((track) => {
                const isCurrentTrack = currentTrackId === track.id
                const rowStyle: React.CSSProperties = {
                  opacity: track.audio_url ? 1 : 0.4,
                  cursor: track.audio_url ? 'pointer' : 'default',
                  backgroundColor: isCurrentTrack && isPlaying ? 'rgba(124, 58, 237, 0.15)' : 'transparent'
                }

                return (
                  <tr
                    key={track.id}
                    className="track-row"
                    data-track-id={track.id}
                    style={rowStyle}
                    onClick={() => track.audio_url && handlePlayTrack(track)}
                    onMouseEnter={(e) => {
                      if (track.audio_url) {
                        e.currentTarget.style.backgroundColor = 'rgba(124, 58, 237, 0.08)'
                      }
                    }}
                    onMouseLeave={(e) => {
                      if (!isCurrentTrack || !isPlaying) {
                        e.currentTarget.style.backgroundColor = 'transparent'
                      } else {
                        e.currentTarget.style.backgroundColor = 'rgba(124, 58, 237, 0.15)'
                      }
                    }}
                  >
                    <td>
                      {track.audio_url ? (
                        <strong style={{ color: isCurrentTrack && isPlaying ? '#00ffff' : '#ccc', cursor: 'pointer' }}>
                          {isCurrentTrack && isPlaying && <span>► </span>}
                          {track.title}
                        </strong>
                      ) : (
                        <strong style={{ color: '#666' }}>{track.title}</strong>
                      )}
                    </td>
                    <td style={{ color: !track.audio_url ? '#555' : isCurrentTrack && isPlaying ? '#00ffff' : '#aaa' }}>
                      &nbsp;{track.artist.name}&nbsp;
                    </td>
                    <td style={{ color: !track.audio_url ? '#555' : isCurrentTrack && isPlaying ? '#00ffff' : '#999' }}>
                      &nbsp;{track.album.name || '-'}&nbsp;
                    </td>
                    <td style={{ color: !track.audio_url ? '#555' : isCurrentTrack && isPlaying ? '#00ffff' : '#999' }}>
                      &nbsp;{track.artist.genre || '-'}&nbsp;
                    </td>
                    <td style={{ textAlign: 'center', width: '135px', minWidth: '135px' }}>
                      {track.audio_url ? (
                        <button
                          className="tui-button play-track-btn"
                          onClick={(e) => {
                            e.stopPropagation()
                            handlePlayTrack(track)
                          }}
                          style={{
                            padding: '2px 12px',
                            fontSize: '0.85em',
                            background: '#7c3aed',
                            color: 'white'
                          }}
                        >
                          {isCurrentTrack && isPlaying ? '❚❚ PAUSE' : '► PLAY'}
                        </button>
                      ) : (
                        <span style={{ color: '#555' }}>-</span>
                      )}
                    </td>
                    {isLoggedIn && (
                      <td style={{ textAlign: 'center', width: '60px', minWidth: '60px' }}>
                        <div onClick={(e) => { e.stopPropagation() }}>
                          <AddToPlaylistDropdown
                            trackId={track.id}
                            trackTitle={track.title}
                            buttonText="+"
                          />
                        </div>
                      </td>
                    )}
                  </tr>
                )
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  )
}
