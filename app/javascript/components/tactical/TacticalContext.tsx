import React, { createContext, useContext, useState, useCallback, useRef, ReactNode } from 'react'
import { apiJson } from '~/utils/apiClient'
import { CommandInputHandle } from '~/components/grid/CommandInput'
import { NpcMobStub } from '~/types/zoneMap'

interface GridCommandResponse {
  output?: string
  room_id?: number
  current_room?: {
    ambient_playlist?: unknown
  }
  in_breach?: boolean
  breach_meta?: BreachMeta | null
}

export interface BreachProtocolMeta {
  position: number
  alive: boolean
  type_label: string
  state: string
}

export interface BreachMeta {
  template_name: string
  tier_label: string
  protocols: BreachProtocolMeta[]
  detection_level: number
  pnr_threshold: number
  actions_remaining: number
  actions_this_round: number
  round_number: number
}

interface TacticalContextValue {
  output: string[]
  currentRoomId: number | null
  executing: boolean
  refreshToken: number
  inBreach: boolean
  breachMeta: BreachMeta | null
  breachOutput: string[]
  hasVendor: boolean
  hasTransit: boolean
  hasNpc: boolean
  npcMobs: NpcMobStub[]
  sendCommand: (command: string) => Promise<string | undefined>
  setOutput: React.Dispatch<React.SetStateAction<string[]>>
  setCurrentRoomId: React.Dispatch<React.SetStateAction<number | null>>
  setHasVendor: React.Dispatch<React.SetStateAction<boolean>>
  setHasTransit: React.Dispatch<React.SetStateAction<boolean>>
  setHasNpc: React.Dispatch<React.SetStateAction<boolean>>
  setNpcMobs: React.Dispatch<React.SetStateAction<NpcMobStub[]>>
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
  const [inBreach, setInBreach] = useState(false)
  const [breachMeta, setBreachMeta] = useState<BreachMeta | null>(null)
  const [breachOutput, setBreachOutput] = useState<string[]>([])
  const [hasVendor, setHasVendor] = useState(false)
  const [hasTransit, setHasTransit] = useState(false)
  const [hasNpc, setHasNpc] = useState(false)
  const [npcMobs, setNpcMobs] = useState<NpcMobStub[]>([])
  const commandInputRef = useRef<CommandInputHandle | null>(null)
  const inBreachRef = useRef(false)

  const sendCommand = useCallback(async (command: string) => {
    if (['clear', 'cls', 'cl'].includes(command.toLowerCase())) {
      setOutput([])
      return
    }

    const echoLines = [
      '<div style="height: 1px; background: #444; margin-top: 16px; margin-bottom: 12px; overflow: hidden;"></div>',
      `<span style="color: #22d3ee;">&gt; ${command}</span>`
    ]

    setOutput(prev => [...prev, ...echoLines])

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

      // Breach state tracking (uses ref to avoid stale closure)
      const wasInBreach = inBreachRef.current
      const nowInBreach = data.in_breach === true

      if (nowInBreach) {
        inBreachRef.current = true
        setInBreach(true)
        setBreachMeta(data.breach_meta ?? null)
        // Replace breach output with latest command result (no scrolling)
        const newLines = [...echoLines]
        if (outputText) newLines.push(outputText)
        setBreachOutput(newLines)
      } else if (wasInBreach && !nowInBreach) {
        // Breach just ended — show final output, then clear all breach state together
        inBreachRef.current = false
        const finalLines = [...echoLines]
        if (outputText) finalLines.push(outputText)
        setBreachOutput(finalLines)
        // Delay clearing so panel can show final output during slide-down
        setTimeout(() => {
          setInBreach(false)
          setBreachMeta(null)
          setBreachOutput([])
        }, 400)
      }

      setRefreshToken(prev => prev + 1)
      return outputText
    } catch (err: unknown) {
      console.error('Command execution failed:', err)
      const raw = err instanceof Error ? err.message : 'Network error. Please try again.'
      const safe = raw.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      setOutput(prev => [...prev, `<span style="color: #f87171;">Error: ${safe}</span>`])
    } finally {
      setExecuting(false)
    }
  }, [])

  return (
    <TacticalContext.Provider value={{
      output, currentRoomId, executing, refreshToken,
      inBreach, breachMeta, breachOutput, hasVendor, hasTransit, hasNpc, npcMobs,
      sendCommand, setOutput, setCurrentRoomId, setHasVendor, setHasTransit, setHasNpc, setNpcMobs, commandInputRef
    }}>
      {children}
    </TacticalContext.Provider>
  )
}
