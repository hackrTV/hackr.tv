import React, { createContext, useContext, useState, useEffect, useCallback, useRef, ReactNode } from 'react'

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
      const response = await fetch('/api/grid/current_hackr', {
        credentials: 'include'
      })

      if (response.ok) {
        const data: CurrentHackrResponse = await response.json()
        if (data.logged_in && data.hackr) {
          setHackr(data.hackr)
        } else {
          setHackr(null)
        }
      } else if (response.status === 401) {
        // 401 is expected when not logged in
        setHackr(null)
      } else {
        console.warn('Grid auth check returned unexpected status:', response.status)
        setHackr(null)
      }
    } catch (_err) {
      console.error('Auth check failed:', _err)
      setHackr(null)
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
      const response = await fetch('/api/grid/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({ hackr_alias, password })
      })

      const data: LoginResponse = await response.json()

      if (data.success && data.hackr) {
        setHackr(data.hackr)
        return data
      } else {
        setError(data.error || 'Login failed')
        return data
      }
    } catch (err) {
      console.error('Login failed:', err)
      const errorMsg = 'Network error. Please try again.'
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
      const response = await fetch('/api/grid/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include',
        body: JSON.stringify({ hackr_alias, password, password_confirmation })
      })

      const data: RegisterResponse = await response.json()

      if (data.success && data.hackr) {
        setHackr(data.hackr)
        return data
      } else {
        setError(data.error || 'Registration failed')
        return data
      }
    } catch (err) {
      console.error('Registration failed:', err)
      const errorMsg = 'Network error. Please try again.'
      setError(errorMsg)
      return { success: false, error: errorMsg }
    }
  }, [])

  const disconnect = useCallback(async () => {
    setError(null)
    try {
      const response = await fetch('/api/grid/disconnect', {
        method: 'DELETE',
        credentials: 'include'
      })

      if (response.ok) {
        setHackr(null)
        return { success: true }
      } else {
        const errorMsg = 'Failed to disconnect'
        setError(errorMsg)
        return { success: false, error: errorMsg }
      }
    } catch (err) {
      console.error('Disconnect failed:', err)
      const errorMsg = 'Network error. Please try again.'
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
    disconnect,
    checkAuth
  }

  return (
    <GridAuthContext.Provider value={value}>
      {children}
    </GridAuthContext.Provider>
  )
}
