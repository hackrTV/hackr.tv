import React, { createContext, useContext, useState, useEffect, useCallback, useRef, ReactNode } from 'react'
import { apiJson, ApiError } from '~/utils/apiClient'

// The auth/account PAGES (login, register, identity, 2FA, …) are
// server-rendered since Hotwire migration Phase 2 — this context only
// hydrates the logged-in state for the remaining SPA pages and carries
// the few mutations they still perform (disconnect, own-profile bio).

export interface GridHackr {
  id: number
  hackr_alias: string
  email?: string
  role: string
  current_room: GridRoom | null
  features: string[]
  otp_enabled?: boolean
  bio?: string
}

export interface GridRoom {
  id: number
  name: string
  description: string
}

interface UpdateProfileResponse {
  success: boolean
  message?: string
  error?: string
  hackr?: GridHackr
}

interface CurrentHackrResponse {
  logged_in: boolean
  hackr?: GridHackr
}

interface GridAuthContextType {
  hackr: GridHackr | null
  loading: boolean
  error: string | null
  isLoggedIn: boolean
  updateProfile: (bio: string) => Promise<UpdateProfileResponse>
  disconnect: () => Promise<{ success: boolean; error?: string }>
  hasFeature: (feature: string) => boolean
}

const GridAuthContext = createContext<GridAuthContextType | null>(null)

export const useGridAuthContext = () => {
  const context = useContext(GridAuthContext)
  if (!context) {
    throw new Error('useGridAuthContext must be used within GridAuthProvider')
  }
  return context
}

interface GridAuthProviderProps {
  children: ReactNode
}

export const GridAuthProvider: React.FC<GridAuthProviderProps> = ({ children }) => {
  const [hackr, setHackr] = useState<GridHackr | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const hasCheckedAuth = useRef(false)

  // Check if user is already logged in
  const checkAuth = useCallback(async () => {
    try {
      const data = await apiJson<CurrentHackrResponse>('/api/grid/current_hackr')
      if (data.logged_in && data.hackr) {
        setHackr(data.hackr)
      } else {
        setHackr(null)
      }
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        setHackr(null)
      } else {
        console.error('Auth check failed:', err)
        setHackr(null)
      }
    } finally {
      setLoading(false)
    }
  }, [])

  // Check auth on mount (only once, even in StrictMode)
  useEffect(() => {
    if (hasCheckedAuth.current) return
    hasCheckedAuth.current = true
    checkAuth()
  }, [checkAuth])

  const updateProfile = useCallback(async (bio: string): Promise<UpdateProfileResponse> => {
    setError(null)
    try {
      const data = await apiJson<UpdateProfileResponse>('/api/grid/identity', {
        method: 'PATCH',
        body: JSON.stringify({ bio })
      })

      if (data.success && data.hackr) {
        setHackr(data.hackr)
      }
      return data
    } catch (err) {
      // apiFetch throws ApiError on 422; its message carries the backend
      // error string (e.g. the GovCorp profanity rejection).
      const errorMsg = err instanceof Error ? err.message : 'Failed to update profile.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const hasFeature = useCallback((feature: string): boolean => {
    if (!hackr) return false
    if (hackr.role === 'admin') return true
    return hackr.features?.includes(feature) ?? false
  }, [hackr])

  const disconnect = useCallback(async () => {
    setError(null)
    try {
      await apiJson('/api/grid/disconnect', {
        method: 'DELETE'
      })

      setHackr(null)
      return { success: true }
    } catch (err) {
      console.error('Disconnect failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const value: GridAuthContextType = {
    hackr,
    loading,
    error,
    isLoggedIn: !!hackr,
    updateProfile,
    disconnect,
    hasFeature
  }

  return (
    <GridAuthContext.Provider value={value}>
      {children}
    </GridAuthContext.Provider>
  )
}
