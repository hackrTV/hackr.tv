import React, { useEffect, useState, useCallback } from 'react'
import { useParams, Link } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeSanitize from 'rehype-sanitize'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import type { Playlist } from '~/types/playlist'
import type { TrackData } from '~/types/track'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'
import { apiJson } from '~/utils/apiClient'

export const SharedPlaylistPage: React.FC = () => {
  const { token } = useParams<{ token: string }>()
  const { mappings } = useCodexMappings()
  const [playlist, setPlaylist] = useState<Playlist | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchSharedPlaylist = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const data = await apiJson<Playlist>(`/api/shared_playlists/${token}`)
      setPlaylist(data)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred'
      setError(errorMessage)
      console.error('Failed to fetch shared playlist:', err)
    } finally {
      setLoading(false)
    }
  }, [token])

  useEffect(() => {
    if (token) {
      fetchSharedPlaylist()
    }
  }, [token, fetchSharedPlaylist])

  const handlePlayPlaylist = () => {
    if (!playlist || !playlist.tracks || playlist.tracks.length === 0) {
      return
    }

    // Convert tracks to TrackData format for audio player
    const trackDataList: TrackData[] = playlist.tracks.map((track) => ({
      id: String(track.track_id),
      url: track.audio_url || '',
      title: track.title,
      artist: track.artist.name,
      coverUrl: track.release?.cover_url || ''
    })).filter(track => track.url) // Only include tracks with audio files

    if (trackDataList.length === 0) {
      alert('No playable tracks in this playlist')
      return
    }

    // Set playlist and play first track
    if (window.audioPlayer) {
      window.audioPlayer.setPlaylist(trackDataList)
      window.audioPlayer.loadTrack(trackDataList[0])
    }
  }

  const formatDuration = (duration: string | null) => {
    if (!duration) return '--:--'
    return duration
  }

  if (loading) {
    return (
      <FmLayout>
        <LoadingSpinner message="Loading shared playlist..." />
      </FmLayout>
    )
  }

  if (error) {
    return (
      <FmLayout>
        <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto' }}>
          <div className="tui-window">
            <fieldset className="tui-fieldset">
              <legend>ERROR</legend>
              <div style={{ padding: '20px', textAlign: 'center' }}>
                <p style={{ color: '#ff6b6b', marginBottom: '20px' }}>{error}</p>
                <Link to="/fm/radio" className="tui-button" style={{ background: '#7c3aed', color: '#fff', textDecoration: 'none' }}>
                  Go to hackr.fm
                </Link>
              </div>
            </fieldset>
          </div>
        </div>
      </FmLayout>
    )
  }

  if (!playlist) {
    return null
  }

  return (
    <FmLayout>
      <div style={{ padding: '20px', maxWidth: '1400px', margin: '0 auto' }}>
        {/* Playlist Info */}
        <div className="tui-window" style={{ marginBottom: '20px', display: 'block', width: '100%' }}>
          <fieldset className="tui-fieldset">
            <legend style={{ color: '#7c3aed' }}>🔓 SHARED PLAYLIST</legend>
            <div style={{ padding: '20px' }}>
              <h1 style={{ color: '#00d9ff', margin: '0 0 10px 0', fontSize: '2em' }}>
                {playlist.name}
              </h1>
              {playlist.description && (
                <div style={{ color: '#aaa', margin: '0 0 15px 0' }}>
                  <ReactMarkdown
                    remarkPlugins={[remarkGfm]}
                    rehypePlugins={[rehypeSanitize]}
                    components={{
                      a: ({ _node, ...props }) => (
                        <a style={{ color: '#60a5fa', textDecoration: 'underline' }} {...props} />
                      ),
                      p: ({ _node, ...props }) => <p style={{ margin: 0 }} {...props} />
                    }}
                  >
                    {transformMarkdownLinks(playlist.description, mappings)}
                  </ReactMarkdown>
                </div>
              )}
              <div style={{ color: '#666', fontSize: '0.9em', marginBottom: '20px' }}>
                {playlist.track_count} {playlist.track_count === 1 ? 'track' : 'tracks'}
              </div>
              <button
                onClick={handlePlayPlaylist}
                disabled={!playlist.tracks || playlist.tracks.length === 0}
                className="tui-button"
                style={{ background: '#7c3aed', color: '#fff' }}
              >
                ▶ Play Playlist
              </button>
            </div>
          </fieldset>
        </div>

        {/* Tracks */}
        {!playlist.tracks || playlist.tracks.length === 0 ? (
          <div className="tui-window" style={{ display: 'block', width: '100%' }}>
            <fieldset className="tui-fieldset">
              <legend>EMPTY PLAYLIST</legend>
              <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                <p style={{ color: '#aaa' }}>This playlist is empty.</p>
              </div>
            </fieldset>
          </div>
        ) : (
          <div className="tui-window" style={{ display: 'block', width: '100%' }}>
            <fieldset className="tui-fieldset">
              <legend>TRACKS ({playlist.tracks.length})</legend>
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom: '2px solid #7c3aed' }}>
                      <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>#</th>
                      <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Track</th>
                      <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Artist</th>
                      <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Release</th>
                      <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {playlist.tracks.map((track, index) => (
                      <tr key={track.track_id} style={{ borderBottom: '1px solid #333' }}>
                        <td style={{ padding: '10px', color: '#666' }}>{index + 1}</td>
                        <td style={{ padding: '10px', color: '#ccc' }}>{track.title}</td>
                        <td style={{ padding: '10px', color: '#aaa' }}>{track.artist.name}</td>
                        <td style={{ padding: '10px', color: '#aaa' }}>{track.release?.name || '-'}</td>
                        <td style={{ padding: '10px', color: '#aaa' }}>{formatDuration(track.duration)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </fieldset>
          </div>
        )}
      </div>
    </FmLayout>
  )
}
