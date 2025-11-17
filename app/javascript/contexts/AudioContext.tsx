import React, { createContext, useContext, useRef, useCallback, ReactNode } from 'react'
import { AudioPlayer } from '~/components/AudioPlayer'
import type { AudioPlayerAPI } from '~/types/track'

interface AudioContextType {
  audioPlayerAPI: React.MutableRefObject<AudioPlayerAPI | null>
}

const AudioContext = createContext<AudioContextType | null>(null)

export const useAudio = () => {
  const context = useContext(AudioContext)
  if (!context) {
    throw new Error('useAudio must be used within AudioProvider')
  }
  return context
}

interface AudioProviderProps {
  children: ReactNode
}

export const AudioProvider: React.FC<AudioProviderProps> = ({ children }) => {
  const audioPlayerAPI = useRef<AudioPlayerAPI | null>(null)

  // Callback to receive the AudioPlayer API when it's ready
  const handleAudioPlayerReady = useCallback((api: AudioPlayerAPI) => {
    audioPlayerAPI.current = api
    // Also expose on window for backward compatibility with legacy code
    if (typeof window !== 'undefined') {
      window.audioPlayer = api
    }
  }, [])

  const value: AudioContextType = {
    audioPlayerAPI
  }

  return (
    <AudioContext.Provider value={value}>
      {children}
      {/* AudioPlayer is always mounted and renders the player bar */}
      <AudioPlayer onReady={handleAudioPlayerReady} />
    </AudioContext.Provider>
  )
}
