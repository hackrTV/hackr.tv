import React, { createContext, useContext, useState, useCallback, useRef, ReactNode } from 'react'
import { apiJson } from '~/utils/apiClient'
import { CommandInputHandle } from '~/components/grid/CommandInput'

interface GridCommandResponse {
  output?: string
  room_id?: number
  current_room?: {
    ambient_playlist?: unknown
  }
}

interface TacticalContextValue {
  output: string[]
  currentRoomId: number | null
  executing: boolean
  refreshToken: number
  sendCommand: (command: string) => Promise<void>
  setOutput: React.Dispatch<React.SetStateAction<string[]>>
  setCurrentRoomId: React.Dispatch<React.SetStateAction<number | null>>
  commandInputRef: React.RefObject<CommandInputHandle | null>
}

const TacticalContext = createContext<TacticalContextValue | null>(null)

export const useTactical = () => {
  const ctx = useContext(TacticalContext)
  if (!ctx) throw new Error('useTactical must be used within TacticalProvider')
  return ctx
}

export const TacticalProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [output, setOutput] = useState<string[]>([])
  const [currentRoomId, setCurrentRoomId] = useState<number | null>(null)
  const [executing, setExecuting] = useState(false)
  const [refreshToken, setRefreshToken] = useState(0)
  const commandInputRef = useRef<CommandInputHandle | null>(null)

  const sendCommand = useCallback(async (command: string) => {
    if (['clear', 'cls', 'cl'].includes(command.toLowerCase())) {
      setOutput([])
      return
    }

    setOutput(prev => [
      ...prev,
      '<div style="height: 1px; background: #444; margin-top: 16px; margin-bottom: 12px; overflow: hidden;"></div>',
      `<span style="color: #22d3ee;">&gt; ${command}</span>`
    ])

    setExecuting(true)

    try {
      const data = await apiJson<GridCommandResponse>('/api/grid/command', {
        method: 'POST',
        body: JSON.stringify({ input: command })
      })

      const outputText = data.output?.trim()
      if (outputText) {
        setOutput(prev => [...prev, outputText])
      }

      if (data.room_id) {
        setCurrentRoomId(prev => data.room_id !== prev ? data.room_id! : prev)
      }

      setRefreshToken(prev => prev + 1)
    } catch (err) {
      console.error('Command execution failed:', err)
      setOutput(prev => [...prev, '<span style="color: #f87171;">Error: Network error. Please try again.</span>'])
    } finally {
      setExecuting(false)
    }
  }, [])

  return (
    <TacticalContext.Provider value={{
      output, currentRoomId, executing, refreshToken,
      sendCommand, setOutput, setCurrentRoomId, commandInputRef
    }}>
      {children}
    </TacticalContext.Provider>
  )
}
