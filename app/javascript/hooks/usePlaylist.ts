import { useState, useCallback } from 'react'
import type { Playlist, PlaylistSummary } from '~/types/playlist'
import { apiJson, ApiError } from '~/utils/apiClient'

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

interface PlaylistResponse {
  playlist?: Playlist
  error?: string
}

interface StatusResponse {
  success: boolean
  error?: string
}

export const usePlaylist = (): UsePlaylistReturn => {
  const [playlists, setPlaylists] = useState<PlaylistSummary[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const fetchPlaylists = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const data = await apiJson<PlaylistSummary[]>('/api/playlists')
      setPlaylists(data)
    } catch (err) {
      let errorMessage = 'Failed to fetch playlists'
      if (err instanceof ApiError && err.status === 401) {
        errorMessage = 'Please log in to view your playlists'
      } else if (err instanceof Error) {
        errorMessage = err.message
      }
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
      const data = await apiJson<PlaylistResponse>('/api/playlists', {
        method: 'POST',
        body: JSON.stringify({
          playlist: {
            name,
            description: description || null
          }
        })
      })

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
      const data = await apiJson<PlaylistResponse>(`/api/playlists/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          playlist: {
            name,
            description: description || null,
            is_public: isPublic
          }
        })
      })

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
      await apiJson<StatusResponse>(`/api/playlists/${id}`, {
        method: 'DELETE'
      })

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
      await apiJson<StatusResponse>(`/api/playlists/${playlistId}/tracks`, {
        method: 'POST',
        body: JSON.stringify({ track_id: trackId })
      })

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to add track to playlist:', err)
      return { success: false, error: errorMessage }
    }
  }, [])

  const removeTrackFromPlaylist = useCallback(async (playlistId: number, playlistTrackId: number) => {
    try {
      await apiJson<StatusResponse>(`/api/playlists/${playlistId}/tracks/${playlistTrackId}`, {
        method: 'DELETE'
      })

      return { success: true }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Network error'
      console.error('Failed to remove track from playlist:', err)
      return { success: false, error: errorMessage }
    }
  }, [])

  const reorderTracks = useCallback(async (playlistId: number, trackIds: number[]) => {
    try {
      await apiJson<StatusResponse>(`/api/playlists/${playlistId}/reorder`, {
        method: 'POST',
        body: JSON.stringify({ track_ids: trackIds })
      })

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
