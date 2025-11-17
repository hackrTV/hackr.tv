import React, { useState, useEffect, useRef } from 'react'
import { usePlaylist } from '~/hooks/usePlaylist'
import { CreatePlaylistModal } from './CreatePlaylistModal'

interface AddToPlaylistDropdownProps {
  trackId: number
  trackTitle: string
  onSuccess?: () => void
  direction?: 'up' | 'down'
  buttonText?: string
}

export const AddToPlaylistDropdown: React.FC<AddToPlaylistDropdownProps> = ({
  trackId,
  trackTitle,
  onSuccess,
  direction = 'down',
  buttonText = '+ Playlist'
}) => {
  const { playlists, fetchPlaylists, addTrackToPlaylist } = usePlaylist()
  const [isOpen, setIsOpen] = useState(false)
  const [isCreating, setIsCreating] = useState(false)
  const [message, setMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null)
  const dropdownRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (isOpen) {
      fetchPlaylists()
    }
  }, [isOpen, fetchPlaylists])

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false)
        setMessage(null)
      }
    }

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside)
      return () => {
        document.removeEventListener('mousedown', handleClickOutside)
      }
    }
  }, [isOpen])

  const handleAddToPlaylist = async (playlistId: number, playlistName: string) => {
    const result = await addTrackToPlaylist(playlistId, trackId)

    if (result.success) {
      setMessage({ text: `Added to "${playlistName}"`, type: 'success' })
      setTimeout(() => {
        setIsOpen(false)
        setMessage(null)
        if (onSuccess) {
          onSuccess()
        }
      }, 1500)
    } else {
      setMessage({ text: result.error || 'Failed to add track', type: 'error' })
    }
  }

  return (
    <div ref={dropdownRef} style={{ position: 'relative', display: 'inline-block' }}>
      <button
        onClick={() => { setIsOpen(!isOpen) }}
        className="tui-button"
        style={{
          background: '#7c3aed',
          color: '#fff',
          fontSize: '0.85em',
          padding: '4px 8px'
        }}
      >
        {buttonText}
      </button>

      {isOpen && (
        <div
          style={{
            position: 'absolute',
            ...(direction === 'up' ? { bottom: '100%', marginBottom: '5px' } : { top: '100%', marginTop: '5px' }),
            right: 0,
            background: '#0a0a0a',
            border: '2px solid #7c3aed',
            borderRadius: '4px',
            minWidth: '250px',
            maxWidth: '350px',
            maxHeight: '400px',
            overflowY: 'auto',
            zIndex: 1000,
            boxShadow: '0 4px 8px rgba(0, 0, 0, 0.5)'
          }}
        >
          <div style={{ padding: '10px', borderBottom: '1px solid #7c3aed' }}>
            <div style={{ color: '#00d9ff', fontWeight: 'bold', marginBottom: '5px', fontSize: '0.9em' }}>
              Add to Playlist
            </div>
            <div style={{ color: '#aaa', fontSize: '0.8em', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {trackTitle}
            </div>
          </div>

          {message && (
            <div
              style={{
                padding: '10px',
                background: message.type === 'success' ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                borderBottom: `1px solid ${message.type === 'success' ? '#22c55e' : '#ef4444'}`,
                color: message.type === 'success' ? '#22c55e' : '#ef4444',
                fontSize: '0.85em'
              }}
            >
              {message.text}
            </div>
          )}

          <div style={{ padding: '8px' }}>
            <button
              onClick={() => { setIsCreating(true) }}
              className="tui-button"
              style={{
                width: '100%',
                marginBottom: '8px',
                background: '#444',
                color: '#00d9ff',
                fontSize: '0.85em',
                padding: '8px'
              }}
            >
              + Create New Playlist
            </button>

            {playlists.length === 0 ? (
              <div style={{ padding: '20px', textAlign: 'center', color: '#666', fontSize: '0.85em' }}>
                No playlists yet.<br />Create one to get started!
              </div>
            ) : (
              <div style={{ maxHeight: '250px', overflowY: 'auto' }}>
                {playlists.map((playlist) => (
                  <button
                    key={playlist.id}
                    onClick={() => { handleAddToPlaylist(playlist.id, playlist.name) }}
                    className="tui-button"
                    style={{
                      width: '100%',
                      marginBottom: '4px',
                      background: '#1a1a1a',
                      color: '#fff',
                      textAlign: 'left',
                      padding: '8px',
                      fontSize: '0.85em',
                      border: '1px solid #333'
                    }}
                  >
                    <div style={{ fontWeight: 'bold' }}>{playlist.name}</div>
                    <div style={{ fontSize: '0.8em', color: '#aaa' }}>
                      {playlist.track_count} {playlist.track_count === 1 ? 'track' : 'tracks'}
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      <CreatePlaylistModal
        isOpen={isCreating}
        onClose={() => { setIsCreating(false) }}
        onSuccess={() => {
          fetchPlaylists()
        }}
      />
    </div>
  )
}
