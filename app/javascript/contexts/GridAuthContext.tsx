import React, { createContext, useContext, useState, useEffect, useCallback, useRef, ReactNode } from 'react'
import { apiJson, ApiError } from '~/utils/apiClient'

export interface GridHackr {
  id: number
  hackr_alias: string
  role: string
  current_room: GridRoom | null
}

export interface GridRoom {
  id: number
  name: string
  description: string
}

interface LoginResponse {
  success: boolean
  message?: string
  error?: string
  hackr?: GridHackr
}

interface RegisterResponse {
  success: boolean
  message?: string
  error?: string
  hackr?: GridHackr
}

interface RequestRegistrationResponse {
  success: boolean
  message?: string
  error?: string
}

interface VerifyTokenResponse {
  valid: boolean
  email?: string
  error?: string
}

interface CompleteRegistrationResponse {
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
  login: (hackr_alias: string, password: string) => Promise<LoginResponse>
  register: (hackr_alias: string, password: string, password_confirmation: string) => Promise<RegisterResponse>
  requestRegistration: (email: string) => Promise<RequestRegistrationResponse>
  verifyToken: (token: string) => Promise<VerifyTokenResponse>
  completeRegistration: (token: string, hackr_alias: string, password: string, password_confirmation: string) => Promise<CompleteRegistrationResponse>
  disconnect: () => Promise<{ success: boolean; error?: string }>
  checkAuth: () => Promise<void>
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

  const login = useCallback(async (hackr_alias: string, password: string): Promise<LoginResponse> => {
    setError(null)
    try {
      const data = await apiJson<LoginResponse>('/api/grid/login', {
        method: 'POST',
        body: JSON.stringify({ hackr_alias, password })
      })

      if (data.success && data.hackr) {
        setHackr(data.hackr)
        return data
      }

      setError(data.error || 'Login failed')
      return data
    } catch (err) {
      console.error('Login failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const register = useCallback(async (
    hackr_alias: string,
    password: string,
    password_confirmation: string
  ): Promise<RegisterResponse> => {
    setError(null)
    try {
      const data = await apiJson<RegisterResponse>('/api/grid/register', {
        method: 'POST',
        body: JSON.stringify({ hackr_alias, password, password_confirmation })
      })

      if (data.success && data.hackr) {
        setHackr(data.hackr)
        return data
      }

      setError(data.error || 'Registration failed')
      return data
    } catch (err) {
      console.error('Registration failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const requestRegistration = useCallback(async (email: string): Promise<RequestRegistrationResponse> => {
    setError(null)
    try {
      const data = await apiJson<RequestRegistrationResponse>('/api/grid/register', {
        method: 'POST',
        body: JSON.stringify({ email })
      })

      if (!data.success) {
        setError(data.error || 'Failed to send verification email')
      }
      return data
    } catch (err) {
      console.error('Registration request failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const verifyToken = useCallback(async (token: string): Promise<VerifyTokenResponse> => {
    setError(null)
    try {
      const data = await apiJson<VerifyTokenResponse>(`/api/grid/verify/${token}`)
      if (!data.valid) {
        setError(data.error || 'Invalid token')
      }
      return data
    } catch (err) {
      console.error('Token verification failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { valid: false, error: errorMsg }
    }
  }, [])

  const completeRegistration = useCallback(async (
    token: string,
    hackr_alias: string,
    password: string,
    password_confirmation: string
  ): Promise<CompleteRegistrationResponse> => {
    setError(null)
    try {
      const data = await apiJson<CompleteRegistrationResponse>('/api/grid/complete_registration', {
        method: 'POST',
        body: JSON.stringify({ token, hackr_alias, password, password_confirmation })
      })

      if (data.success && data.hackr) {
        setHackr(data.hackr)
        return data
      }

      setError(data.error || 'Registration failed')
      return data
    } catch (err) {
      console.error('Registration completion failed:', err)
      const errorMsg = err instanceof Error ? err.message : 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

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
    login,
    register,
    requestRegistration,
    verifyToken,
    completeRegistration,
    disconnect,
    checkAuth
  }

  return (
    <GridAuthContext.Provider value={value}>
      {children}
    </GridAuthContext.Provider>
  )
}
