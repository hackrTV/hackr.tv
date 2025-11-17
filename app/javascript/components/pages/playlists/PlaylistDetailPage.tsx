import React, { useEffect, useState, useCallback } from 'react'
import { useParams, Link, useSearchParams } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { usePlaylist } from '~/hooks/usePlaylist'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import type { Playlist } from '~/types/playlist'
import type { TrackData } from '~/types/track'
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent
} from '@dnd-kit/core'
import {
  arrayMove,
  SortableContext,
  sortableKeyboardCoordinates,
  useSortable,
  verticalListSortingStrategy
} from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'

// Sortable Track Row Component
interface SortableTrackRowProps {
  track: Playlist['tracks'][0]
  index: number
  onRemove: (id: number, title: string) => void
  formatDuration: (duration: string | null) => string
}

const SortableTrackRow: React.FC<SortableTrackRowProps> = ({ track, index, onRemove, formatDuration }) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging
  } = useSortable({ id: track.track_id })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
    cursor: isDragging ? 'grabbing' : 'grab',
    borderBottom: '1px solid #333'
  }

  return (
    <tr ref={setNodeRef} style={style} {...attributes} {...listeners}>
      <td style={{ padding: '10px', color: '#666' }}>
        <span style={{ marginRight: '8px' }}>☰</span>
        {index + 1}
      </td>
      <td style={{ padding: '10px', color: '#ccc' }}>{track.title}</td>
      <td style={{ padding: '10px', color: '#aaa' }}>{track.artist.name}</td>
      <td style={{ padding: '10px', color: '#aaa' }}>{track.album?.name || '—'}</td>
      <td style={{ padding: '10px', color: '#aaa' }}>{formatDuration(track.duration)}</td>
      <td style={{ padding: '10px', textAlign: 'center' }}>
        <button
          onClick={(e) => {
            e.stopPropagation()
            onRemove(track.id, track.title)
          }}
          className="tui-button"
          style={{
            background: '#444',
            color: '#ff6b6b',
            fontSize: '0.8em',
            padding: '4px 8px'
          }}
        >
          Remove
        </button>
      </td>
    </tr>
  )
}

export const PlaylistDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const [searchParams, setSearchParams] = useSearchParams()
  const { updatePlaylist, removeTrackFromPlaylist } = usePlaylist()
  const [playlist, setPlaylist] = useState<Playlist | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [isEditing, setIsEditing] = useState(false)
  const [editName, setEditName] = useState('')
  const [editDescription, setEditDescription] = useState('')
  const [editIsPublic, setEditIsPublic] = useState(false)

  const sensors = useSensors(
    useSensor(PointerSensor),
    useSensor(KeyboardSensor, {
      coordinateGetter: sortableKeyboardCoordinates
    })
  )

  const fetchPlaylist = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/playlists/${id}`, {
        credentials: 'include'
      })

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Playlist not found')
        }
        if (response.status === 403) {
          throw new Error('You do not have permission to view this playlist')
        }
        throw new Error('Failed to load playlist')
      }

      const data = await response.json()
      setPlaylist(data)
      setEditName(data.name)
      setEditDescription(data.description || '')
      setEditIsPublic(data.is_public)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred'
      setError(errorMessage)
      console.error('Failed to fetch playlist:', err)
    } finally {
      setLoading(false)
    }
  }, [id])

  const handlePlayPlaylist = useCallback(() => {
    if (!playlist || !playlist.tracks || playlist.tracks.length === 0) {
      return
    }

    // Convert tracks to TrackData format for audio player
    const trackDataList: TrackData[] = playlist.tracks.map((track) => ({
      id: String(track.id),
      url: track.audio_url || '',
      title: track.title,
      artist: track.artist.name,
      coverUrl: track.album?.cover_url || ''
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
  }, [playlist])

  useEffect(() => {
    if (id) {
      fetchPlaylist()
    }
  }, [id, fetchPlaylist])

  // Handle autoplay if ?autoplay=true in URL
  useEffect(() => {
    if (playlist && searchParams.get('autoplay') === 'true') {
      // Remove the autoplay param from URL
      setSearchParams({})
      // Auto-play the playlist
      handlePlayPlaylist()
    }
  }, [playlist, searchParams, setSearchParams, handlePlayPlaylist])

  const handleSaveEdit = async () => {
    if (!playlist) return

    const result = await updatePlaylist(playlist.id, editName, editDescription, editIsPublic)

    if (result.success) {
      setPlaylist({
        ...playlist,
        name: editName,
        description: editDescription || null,
        is_public: editIsPublic
      })
      setIsEditing(false)
    } else {
      alert(result.error || 'Failed to update playlist')
    }
  }

  const handleRemoveTrack = async (playlistTrackId: number, trackTitle: string) => {
    if (!playlist) return

    if (!confirm(`Remove "${trackTitle}" from this playlist?`)) {
      return
    }

    const result = await removeTrackFromPlaylist(playlist.id, playlistTrackId)

    if (result.success) {
      // Refresh playlist
      fetchPlaylist()
    } else {
      alert(result.error || 'Failed to remove track')
    }
  }

  const handleDragEnd = async (event: DragEndEvent) => {
    const { active, over } = event

    if (!over || !playlist || !playlist.tracks) {
      return
    }

    if (active.id !== over.id) {
      const oldIndex = playlist.tracks.findIndex((track) => track.track_id === active.id)
      const newIndex = playlist.tracks.findIndex((track) => track.track_id === over.id)

      if (oldIndex === -1 || newIndex === -1) {
        return
      }

      // Optimistically update UI
      const newTracks = arrayMove(playlist.tracks, oldIndex, newIndex)
      setPlaylist({
        ...playlist,
        tracks: newTracks
      })

      // Call API to persist the new order
      const trackIds = newTracks.map((track) => track.track_id)

      try {
        const response = await fetch(`/api/playlists/${playlist.id}/reorder`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          credentials: 'include',
          body: JSON.stringify({ track_ids: trackIds })
        })

        if (!response.ok) {
          throw new Error('Failed to reorder tracks')
        }

        // Refresh to get updated positions from server
        fetchPlaylist()
      } catch (err) {
        console.error('Failed to reorder tracks:', err)
        alert('Failed to save new track order')
        // Revert to original order on error
        fetchPlaylist()
      }
    }
  }

  const copyShareLink = () => {
    if (!playlist) return

    const shareUrl = `${window.location.origin}/shared/${playlist.share_token}`

    // Try modern clipboard API first
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(shareUrl)
        .then(() => {
          alert('Share link copied to clipboard!')
        })
        .catch(() => {
          fallbackCopy(shareUrl)
        })
    } else {
      // Fallback for older browsers or insecure contexts
      fallbackCopy(shareUrl)
    }
  }

  const fallbackCopy = (text: string) => {
    // Create a temporary textarea
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()

    try {
      const successful = document.execCommand('copy')
      document.body.removeChild(textarea)

      if (successful) {
        alert('Share link copied to clipboard!')
      } else {
        // If copy failed, show the URL for manual copying
        prompt('Copy this share link:', text)
      }
    } catch {
      document.body.removeChild(textarea)
      // If everything fails, show the URL in a prompt
      prompt('Copy this share link:', text)
    }
  }

  const formatDuration = (duration: string | null) => {
    if (!duration) return '--:--'
    return duration
  }

  if (loading) {
    return (
      <FmLayout>
        <LoadingSpinner message="Loading playlist..." />
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
                <Link to="/fm/playlists" className="tui-button" style={{ background: '#7c3aed', color: '#fff', textDecoration: 'none' }}>
                  Back to Playlists
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
        {/* Header */}
        <div style={{ marginBottom: '20px' }}>
          <Link to="/fm/playlists" style={{ color: '#00d9ff', textDecoration: 'none', fontSize: '0.9em' }}>
          ← Back to Playlists
          </Link>
        </div>

        {/* Playlist Info */}
        <div className="tui-window" style={{ marginBottom: '20px', display: 'block', width: '100%' }}>
          <fieldset className="tui-fieldset">
            <legend style={{ color: '#7c3aed' }}>
              {playlist.is_public ? '🔓 PUBLIC PLAYLIST' : '🔒 PRIVATE PLAYLIST'}
            </legend>
            <div style={{ padding: '20px' }}>
              {!isEditing ? (
                <>
                  <h1 style={{ color: '#00d9ff', margin: '0 0 10px 0', fontSize: '2em' }}>
                    {playlist.name}
                  </h1>
                  {playlist.description && (
                    <p style={{ color: '#aaa', margin: '0 0 15px 0' }}>{playlist.description}</p>
                  )}
                  <div style={{ color: '#666', fontSize: '0.9em', marginBottom: '20px' }}>
                    {playlist.track_count} {playlist.track_count === 1 ? 'track' : 'tracks'}
                  </div>
                  <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <button
                      onClick={handlePlayPlaylist}
                      disabled={!playlist.tracks || playlist.tracks.length === 0}
                      className="tui-button"
                      style={{ background: '#7c3aed', color: '#fff' }}
                    >
                    ▶ Play Playlist
                    </button>
                    <button
                      onClick={() => { setIsEditing(true) }}
                      className="tui-button"
                      style={{ background: '#444', color: '#fff' }}
                    >
                    ✎ Edit
                    </button>
                    {playlist.is_public && (
                      <button
                        onClick={copyShareLink}
                        className="tui-button"
                        style={{ background: '#444', color: '#00d9ff' }}
                      >
                      🔗 Share
                      </button>
                    )}
                  </div>
                </>
              ) : (
                <>
                  <div style={{ marginBottom: '15px' }}>
                    <label style={{ display: 'block', marginBottom: '5px', color: '#00d9ff' }}>Name</label>
                    <input
                      type="text"
                      value={editName}
                      onChange={(e) => { setEditName(e.target.value) }}
                      style={{
                        width: '100%',
                        padding: '8px',
                        background: '#1a1a1a',
                        border: '1px solid #7c3aed',
                        color: '#fff',
                        fontFamily: 'monospace'
                      }}
                    />
                  </div>
                  <div style={{ marginBottom: '15px' }}>
                    <label style={{ display: 'block', marginBottom: '5px', color: '#00d9ff' }}>Description</label>
                    <textarea
                      value={editDescription}
                      onChange={(e) => { setEditDescription(e.target.value) }}
                      rows={3}
                      style={{
                        width: '100%',
                        padding: '8px',
                        background: '#1a1a1a',
                        border: '1px solid #7c3aed',
                        color: '#fff',
                        fontFamily: 'monospace',
                        resize: 'vertical'
                      }}
                    />
                  </div>
                  <div style={{ marginBottom: '15px' }}>
                    <label style={{ display: 'flex', alignItems: 'center', color: '#00d9ff', cursor: 'pointer' }}>
                      <input
                        type="checkbox"
                        checked={editIsPublic}
                        onChange={(e) => { setEditIsPublic(e.target.checked) }}
                        style={{ marginRight: '8px' }}
                      />
                    Make this playlist public (allows sharing)
                    </label>
                  </div>
                  <div style={{ display: 'flex', gap: '10px' }}>
                    <button
                      onClick={handleSaveEdit}
                      className="tui-button"
                      style={{ background: '#7c3aed', color: '#fff' }}
                    >
                    Save
                    </button>
                    <button
                      onClick={() => {
                        setIsEditing(false)
                        setEditName(playlist.name)
                        setEditDescription(playlist.description || '')
                        setEditIsPublic(playlist.is_public)
                      }}
                      className="tui-button"
                      style={{ background: '#444', color: '#aaa' }}
                    >
                    Cancel
                    </button>
                  </div>
                </>
              )}
            </div>
          </fieldset>
        </div>

        {/* Tracks */}
        {!playlist.tracks || playlist.tracks.length === 0 ? (
          <div className="tui-window" style={{ display: 'block', width: '100%' }}>
            <fieldset className="tui-fieldset">
              <legend>EMPTY PLAYLIST</legend>
              <div style={{ padding: '40px 20px', textAlign: 'center' }}>
                <p style={{ color: '#aaa', marginBottom: '20px' }}>
                This playlist is empty. Add tracks from the Pulse Vault!
                </p>
                <Link
                  to="/fm/pulse_vault"
                  className="tui-button"
                  style={{ background: '#7c3aed', color: '#fff', textDecoration: 'none' }}
                >
                Go to Pulse Vault
                </Link>
              </div>
            </fieldset>
          </div>
        ) : (
          <div className="tui-window" style={{ display: 'block', width: '100%' }}>
            <fieldset className="tui-fieldset">
              <legend>TRACKS ({playlist.tracks.length}) - Drag to reorder</legend>
              <div style={{ overflowX: 'auto' }}>
                <DndContext
                  sensors={sensors}
                  collisionDetection={closestCenter}
                  onDragEnd={handleDragEnd}
                >
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <thead>
                      <tr style={{ borderBottom: '2px solid #7c3aed' }}>
                        <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>#</th>
                        <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Track</th>
                        <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Artist</th>
                        <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Album</th>
                        <th style={{ padding: '10px', textAlign: 'left', color: '#00d9ff' }}>Duration</th>
                        <th style={{ padding: '10px', textAlign: 'center', color: '#00d9ff' }}>Actions</th>
                      </tr>
                    </thead>
                    <SortableContext
                      items={playlist.tracks.map((track) => track.track_id)}
                      strategy={verticalListSortingStrategy}
                    >
                      <tbody>
                        {playlist.tracks.map((track, index) => (
                          <SortableTrackRow
                            key={track.track_id}
                            track={track}
                            index={index}
                            onRemove={handleRemoveTrack}
                            formatDuration={formatDuration}
                          />
                        ))}
                      </tbody>
                    </SortableContext>
                  </table>
                </DndContext>
              </div>
            </fieldset>
          </div>
        )}
      </div>
    </FmLayout>
  )
}
