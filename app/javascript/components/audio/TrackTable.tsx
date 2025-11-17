import React, { useState } from 'react'
import { useAudio } from '~/contexts/AudioContext'

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

  // Update playlist in audio player when tracks or filter changes
  React.useEffect(() => {
    if (audioPlayerAPI.current) {
      const playableFilteredTracks = filteredTracks
        .filter(track => track.audio_url)
        .map(track => ({
          id: track.id.toString(),
          url: track.audio_url!,
          title: track.title,
          artist: track.artist.name,
          coverUrl: track.album.cover_url || ''
        }))
      audioPlayerAPI.current.setPlaylist(playableFilteredTracks)
    }
  }, [filteredTracks, audioPlayerAPI])

  const handlePlayTrack = (track: Track) => {
    if (!track.audio_url || !audioPlayerAPI.current) return

    const trackIdStr = track.id.toString()

    // If clicking the currently playing track, toggle play/pause
    if (currentTrackId === track.id) {
      audioPlayerAPI.current.togglePlayPause()
    } else {
      // Load and play a different track
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

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <label htmlFor="track-search" style={{ color: '#888', display: 'block', marginBottom: '8px' }}>
          SEARCH TRACKS :: Filter by track, artist, album, or genre
        </label>
        <input
          type="text"
          id="track-search"
          placeholder="Type to filter tracks..."
          value={filter}
          onChange={(e) => setFilter(e.target.value)}
          style={{
            width: '100%',
            padding: '10px',
            background: '#0a0a0a',
            border: '1px solid #555',
            color: '#ccc',
            fontFamily: 'monospace',
            fontSize: '1em'
          }}
        />
      </div>

      <div className="tui-fieldset" style={{ borderColor: '#555' }}>
        <legend style={{ color: '#888' }}>TRACK LIBRARY</legend>
        <table className="tui-table" style={{ width: '100%', borderCollapse: 'separate', borderSpacing: '0 2px' }}>
          <thead>
            <tr>
              <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Track</th>
              <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Artist</th>
              <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Album</th>
              <th style={{ textAlign: 'left', color: '#888' }}>&nbsp;Genre</th>
              <th style={{ textAlign: 'center', color: '#888', width: '120px', minWidth: '120px' }}>Stream</th>
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
                      <strong style={{ color: '#ccc', cursor: 'pointer' }}>
                        {isCurrentTrack && isPlaying && <span>★ </span>}
                        {track.title}
                      </strong>
                    ) : (
                      <strong style={{ color: '#666' }}>{track.title}</strong>
                    )}
                  </td>
                  <td style={{ color: track.audio_url ? '#aaa' : '#555' }}>
                    &nbsp;{track.artist.name}&nbsp;
                  </td>
                  <td style={{ color: track.audio_url ? '#999' : '#555' }}>
                    &nbsp;{track.album.name || '—'}&nbsp;
                  </td>
                  <td style={{ color: track.audio_url ? '#999' : '#555' }}>
                    &nbsp;{track.artist.genre || '—'}&nbsp;
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
                      <span style={{ color: '#555' }}>—</span>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
