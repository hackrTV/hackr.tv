import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { apiJson } from '~/utils/apiClient'

interface AppSettings {
  prerelease_mode: string | null
  prerelease_banner_text: string | null
}

interface AppSettingsContextType {
  settings: AppSettings
  isLoading: boolean
  isPrereleaseMode: boolean
}

const defaultSettings: AppSettings = {
  prerelease_mode: null,
  prerelease_banner_text: null
}

const AppSettingsContext = createContext<AppSettingsContextType | null>(null)

export const useAppSettings = (): AppSettingsContextType => {
  const context = useContext(AppSettingsContext)
  if (!context) {
    // Return default values if context is not available
    return {
      settings: defaultSettings,
      isLoading: true,
      isPrereleaseMode: false
    }
  }
  return context
}

interface AppSettingsProviderProps {
  children: ReactNode
}

export const AppSettingsProvider: React.FC<AppSettingsProviderProps> = ({ children }) => {
  const [settings, setSettings] = useState<AppSettings>(defaultSettings)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const data = await apiJson<AppSettings>('/api/settings')
        setSettings(data)
      } catch (error) {
        console.error('Failed to fetch app settings:', error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchSettings()
  }, [])

  const isPrereleaseMode = Boolean(settings.prerelease_mode)

  return (
    <AppSettingsContext.Provider value={{ settings, isLoading, isPrereleaseMode }}>
      {children}
    </AppSettingsContext.Provider>
  )
}
