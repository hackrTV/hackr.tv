import React, { useState } from 'react'
import { usePlaylist } from '~/hooks/usePlaylist'

interface CreatePlaylistModalProps {
  isOpen: boolean
  onClose: () => void
  onSuccess?: () => void
}

export const CreatePlaylistModal: React.FC<CreatePlaylistModalProps> = ({
  isOpen,
  onClose,
  onSuccess
}) => {
  const { createPlaylist } = usePlaylist()
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!isOpen) return null

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    if (!name.trim()) {
      setError('Playlist name is required')
      return
    }

    setIsSubmitting(true)

    const result = await createPlaylist(name.trim(), description.trim() || undefined)

    if (result.success) {
      setName('')
      setDescription('')
      onClose()
      if (onSuccess) {
        onSuccess()
      }
    } else {
      setError(result.error || 'Failed to create playlist')
    }

    setIsSubmitting(false)
  }

  const handleClose = () => {
    if (!isSubmitting) {
      setName('')
      setDescription('')
      setError(null)
      onClose()
    }
  }

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(0, 0, 0, 0.85)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 9999,
        padding: '20px'
      }}
      onClick={handleClose}
    >
      <div
        className="tui-window"
        style={{ maxWidth: '500px', width: '100%', margin: '0 auto' }}
        onClick={(e) => { e.stopPropagation() }}
      >
        <fieldset className="tui-fieldset">
          <legend>CREATE NEW PLAYLIST</legend>

          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '15px' }}>
              <label htmlFor="playlist-name" style={{ display: 'block', marginBottom: '5px', color: '#00d9ff' }}>
                Playlist Name *
              </label>
              <input
                id="playlist-name"
                type="text"
                value={name}
                onChange={(e) => { setName(e.target.value) }}
                disabled={isSubmitting}
                style={{
                  width: '100%',
                  padding: '8px',
                  background: '#1a1a1a',
                  border: '1px solid #7c3aed',
                  color: '#fff',
                  fontFamily: 'monospace'
                }}
                placeholder="Enter playlist name..."
                maxLength={100}
                autoFocus
              />
            </div>

            <div style={{ marginBottom: '15px' }}>
              <label htmlFor="playlist-description" style={{ display: 'block', marginBottom: '5px', color: '#00d9ff' }}>
                Description (optional)
              </label>
              <textarea
                id="playlist-description"
                value={description}
                onChange={(e) => { setDescription(e.target.value) }}
                disabled={isSubmitting}
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
                placeholder="Enter description..."
                maxLength={500}
              />
            </div>

            {error && (
              <div style={{ marginBottom: '15px', padding: '10px', background: '#3a1a1a', border: '1px solid #ff3a3a', color: '#ff6b6b' }}>
                {error}
              </div>
            )}

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                type="button"
                onClick={handleClose}
                disabled={isSubmitting}
                className="tui-button"
                style={{ background: '#444', color: '#aaa' }}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting || !name.trim()}
                className="tui-button"
                style={{ background: '#7c3aed', color: '#fff' }}
              >
                {isSubmitting ? 'Creating...' : 'Create Playlist'}
              </button>
            </div>
          </form>
        </fieldset>
      </div>
    </div>
  )
}
