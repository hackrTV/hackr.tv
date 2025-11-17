import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { usePlaylist } from '~/hooks/usePlaylist'
import { CreatePlaylistModal } from '~/components/playlists/CreatePlaylistModal'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

export const PlaylistsPage: React.FC = () => {
  const { playlists, loading, error, fetchPlaylists, deletePlaylist } = usePlaylist()
  const [isCreating, setIsCreating] = useState(false)
  const [deletingId, setDeletingId] = useState<number | null>(null)

  useEffect(() => {
    fetchPlaylists()
  }, [fetchPlaylists])

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Delete playlist "${name}"?\n\nThis action cannot be undone.`)) {
      return
    }

    setDeletingId(id)
    const result = await deletePlaylist(id)

    if (!result.success) {
      alert(result.error || 'Failed to delete playlist')
    }

    setDeletingId(null)
  }

  const formatDate = (dateString: string) => {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  if (loading && playlists.length === 0) {
    return (
      <FmLayout>
        <LoadingSpinner message="Loading playlists..." />
      </FmLayout>
    )
  }

  return (
    <FmLayout>
      <div style={{ padding: '20px', maxWidth: '1400px', margin: '0 auto' }}>
        <div style={{ marginBottom: '30px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h1 style={{ color: '#00d9ff', fontSize: '2em', margin: 0 }}>
            MY PLAYLISTS
            </h1>
            <button
              onClick={() => { setIsCreating(true) }}
              className="tui-button"
              style={{ background: '#7c3aed', color: '#fff', padding: '10px 20px' }}
            >
            + Create Playlist
            </button>
          </div>

          {error && (
            <div style={{ padding: '15px', background: '#3a1a1a', border: '1px solid #ff3a3a', color: '#ff6b6b', marginBottom: '20px' }}>
              {error}
            </div>
          )}
        </div>

        {playlists.length === 0 ? (
          <div className="tui-window" style={{ maxWidth: '600px', margin: '40px auto', textAlign: 'center' }}>
            <fieldset className="tui-fieldset">
              <legend>NO PLAYLISTS YET</legend>
              <div style={{ padding: '40px 20px' }}>
                <p style={{ color: '#aaa', marginBottom: '20px', fontSize: '1.1em' }}>
                Create your first playlist to organize your favorite tracks!
                </p>
                <button
                  onClick={() => { setIsCreating(true) }}
                  className="tui-button"
                  style={{ background: '#7c3aed', color: '#fff', padding: '12px 24px' }}
                >
                Create Your First Playlist
                </button>
              </div>
            </fieldset>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px' }}>
            {playlists.map((playlist) => (
              <div key={playlist.id} className="tui-window">
                <fieldset className="tui-fieldset">
                  <legend style={{ color: '#7c3aed' }}>
                    {playlist.is_public ? '🔓 PUBLIC' : '🔒 PRIVATE'}
                  </legend>
                  <div style={{ padding: '15px' }}>
                    <Link
                      to={`/fm/playlists/${playlist.id}`}
                      style={{ textDecoration: 'none', color: '#00d9ff' }}
                    >
                      <h3 style={{ margin: '0 0 10px 0', fontSize: '1.2em', wordBreak: 'break-word' }}>
                        {playlist.name}
                      </h3>
                    </Link>

                    {playlist.description && (
                      <p style={{ color: '#aaa', fontSize: '0.9em', margin: '0 0 15px 0', wordBreak: 'break-word' }}>
                        {playlist.description}
                      </p>
                    )}

                    <div style={{ color: '#666', fontSize: '0.85em', marginBottom: '15px' }}>
                      <div>{playlist.track_count} {playlist.track_count === 1 ? 'track' : 'tracks'}</div>
                      <div>Created {formatDate(playlist.created_at)}</div>
                    </div>

                    <div style={{ display: 'flex', gap: '8px', flexDirection: 'column' }}>
                      <Link
                        to={`/fm/playlists/${playlist.id}?autoplay=true`}
                        className="tui-button"
                        style={{
                          textAlign: 'center',
                          textDecoration: 'none',
                          background: '#7c3aed',
                          color: '#fff',
                          fontSize: '0.85em'
                        }}
                      >
                        ▶ Play
                      </Link>
                      <div style={{ display: 'flex', gap: '8px' }}>
                        <Link
                          to={`/fm/playlists/${playlist.id}`}
                          className="tui-button"
                          style={{
                            flex: 1,
                            textAlign: 'center',
                            textDecoration: 'none',
                            background: '#444',
                            color: '#fff',
                            fontSize: '0.85em'
                          }}
                        >
                          View
                        </Link>
                        <button
                          onClick={() => { handleDelete(playlist.id, playlist.name) }}
                          disabled={deletingId === playlist.id}
                          className="tui-button"
                          style={{
                            flex: 1,
                            background: '#444',
                            color: '#ff6b6b',
                            fontSize: '0.85em'
                          }}
                        >
                          {deletingId === playlist.id ? 'Deleting...' : 'Delete'}
                        </button>
                      </div>
                    </div>
                  </div>
                </fieldset>
              </div>
            ))}
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
    </FmLayout>
  )
}
