import { useState, useCallback } from 'react'
import type { Playlist, PlaylistSummary } from '~/types/playlist'

interface UsePlaylistReturn {
  playlists: PlaylistSummary[]
  loading: boolean
  error: string | null
  fetchPlaylists: () => Promise<void>
  createPlaylist: (name: string, description?: string) => Promise<{ success: boolean; playlist?: Playlist; error?: string }>
  updatePlaylist: (id: number, name: string, description?: string, isPublic?: boolean) => Promise<{ success: boolean; playlist?: Playlist; error?: string }>
  deletePlaylist: (id: number) => Promise<{ success: boolean; error?: string }>
  addTrackToPlaylist: (playlistId: number, trackId: number) => Promise<{ success: boolean; error?: string }>
  removeTrackFromPlaylist: (playlistId: number, playlistTrackId: number) => Promise<{ success: boolean; error?: string }>
  reorderTracks: (playlistId: number, trackIds: number[]) => Promise<{ success: boolean; error?: string }>
}

export const usePlaylist = (): UsePlaylistReturn => {
  const [playlists, setPlaylists] = useState<PlaylistSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPlaylists = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/playlists', {
        credentials: 'include'
      })

      if (!response.ok) {
        if (response.status === 401) {
          throw new Error('Please log in to view your playlists')
        }
        throw new Error('Failed to fetch playlists')
      }

      const data = await response.json()
      setPlaylists(data)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'An error occurred'
      setError(errorMessage)
      console.error('Failed to fetch playlists:', err)
    } finally {
      setLoading(false)
    }
  }, [])

  const createPlaylist = useCallback(async (name: string, description?: string) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch('/api/playlists', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({
          playlist: {
            name,
            description: description || null
          }
        })
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to create playlist' }
      }

      // Refresh playlists list
      await fetchPlaylists()

      return { success: true, playlist: data.playlist }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to create playlist:', err)
      return { success: false, error: errorMessage }
    } finally {
      setLoading(false)
    }
  }, [fetchPlaylists])

  const updatePlaylist = useCallback(async (id: number, name: string, description?: string, isPublic?: boolean) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/playlists/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({
          playlist: {
            name,
            description: description || null,
            is_public: isPublic
          }
        })
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to update playlist' }
      }

      // Refresh playlists list
      await fetchPlaylists()

      return { success: true, playlist: data.playlist }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to update playlist:', err)
      return { success: false, error: errorMessage }
    } finally {
      setLoading(false)
    }
  }, [fetchPlaylists])

  const deletePlaylist = useCallback(async (id: number) => {
    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`/api/playlists/${id}`, {
        method: 'DELETE',
        credentials: 'include'
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to delete playlist' }
      }

      // Refresh playlists list
      await fetchPlaylists()

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to delete playlist:', err)
      return { success: false, error: errorMessage }
    } finally {
      setLoading(false)
    }
  }, [fetchPlaylists])

  const addTrackToPlaylist = useCallback(async (playlistId: number, trackId: number) => {
    try {
      const response = await fetch(`/api/playlists/${playlistId}/tracks`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({ track_id: trackId })
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to add track to playlist' }
      }

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to add track to playlist:', err)
      return { success: false, error: errorMessage }
    }
  }, [])

  const removeTrackFromPlaylist = useCallback(async (playlistId: number, playlistTrackId: number) => {
    try {
      const response = await fetch(`/api/playlists/${playlistId}/tracks/${playlistTrackId}`, {
        method: 'DELETE',
        credentials: 'include'
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to remove track from playlist' }
      }

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to remove track from playlist:', err)
      return { success: false, error: errorMessage }
    }
  }, [])

  const reorderTracks = useCallback(async (playlistId: number, trackIds: number[]) => {
    try {
      const response = await fetch(`/api/playlists/${playlistId}/reorder`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({ track_ids: trackIds })
      })

      const data = await response.json()

      if (!response.ok) {
        return { success: false, error: data.error || 'Failed to reorder tracks' }
      }

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to reorder tracks:', err)
      return { success: false, error: errorMessage }
    }
  }, [])

  return {
    playlists,
    loading,
    error,
    fetchPlaylists,
    createPlaylist,
    updatePlaylist,
    deletePlaylist,
    addTrackToPlaylist,
    removeTrackFromPlaylist,
    reorderTracks
  }
}
