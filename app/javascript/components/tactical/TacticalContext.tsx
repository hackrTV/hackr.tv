import React, { createContext, useContext, useState, useCallback, useRef, useMemo, ReactNode } from 'react'
import { apiJson } from '~/utils/apiClient'
import { trackEvent } from '~/utils/analyticsCollector'
import { CommandInputHandle } from '~/components/grid/CommandInput'
import { NpcMobStub } from '~/types/zoneMap'

const MAX_OUTPUT_LINES = 500

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
  mapRefreshToken: number
  dataRefreshToken: number
  breachRefreshToken: number
  inBreach: boolean
  breachMeta: BreachMeta | null
  breachOutput: string[]
  hasVendor: boolean
  hasTransit: boolean
  hasNpc: boolean
  hasRestPod: boolean
  npcMobs: NpcMobStub[]
  sendCommand: (command: string) => Promise<string | undefined>
  setOutput: React.Dispatch<React.SetStateAction<string[]>>
  setCurrentRoomId: (id: number | null) => void
  setHasVendor: React.Dispatch<React.SetStateAction<boolean>>
  setHasTransit: React.Dispatch<React.SetStateAction<boolean>>
  setHasNpc: React.Dispatch<React.SetStateAction<boolean>>
  setHasRestPod: React.Dispatch<React.SetStateAction<boolean>>
  setNpcMobs: React.Dispatch<React.SetStateAction<NpcMobStub[]>>
  commandInputRef: React.RefObject<CommandInputHandle | null>
}

const TacticalContext = createContext<TacticalContextValue | null>(null)

export const useTactical = () => {
  const ctx = useContext(TacticalContext)
  if (!ctx) throw new Error('useTactical must be used within TacticalProvider')
  return ctx
}

const capOutput = (lines: string[]): string[] =>
  lines.length > MAX_OUTPUT_LINES ? lines.slice(-MAX_OUTPUT_LINES) : lines

export const TacticalProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [output, setOutputRaw] = useState<string[]>([])
  const [currentRoomId, setCurrentRoomIdRaw] = useState<number | null>(null)
  const [executing, setExecuting] = useState(false)
  const [mapRefreshToken, setMapRefreshToken] = useState(0)
  const [dataRefreshToken, setDataRefreshToken] = useState(0)
  const [breachRefreshToken, setBreachRefreshToken] = useState(0)
  const [inBreach, setInBreach] = useState(false)
  const [breachMeta, setBreachMeta] = useState<BreachMeta | null>(null)
  const [breachOutput, setBreachOutput] = useState<string[]>([])
  const [hasVendor, setHasVendor] = useState(false)
  const [hasTransit, setHasTransit] = useState(false)
  const [hasNpc, setHasNpc] = useState(false)
  const [hasRestPod, setHasRestPod] = useState(false)
  const [npcMobs, setNpcMobs] = useState<NpcMobStub[]>([])
  const commandInputRef = useRef<CommandInputHandle | null>(null)
  const inBreachRef = useRef(false)
  const executingRef = useRef(false)
  const currentRoomIdRef = useRef<number | null>(null)

  // Wrap setOutput to enforce cap — all callers (including external handleEvent) get automatic capping
  const setOutput: React.Dispatch<React.SetStateAction<string[]>> = useCallback(
    (action: React.SetStateAction<string[]>) => {
      setOutputRaw(prev => {
        const next = typeof action === 'function' ? action(prev) : action
        return capOutput(next)
      })
    }, []
  )

  // Wrap setCurrentRoomId to keep ref in sync (ref used by sendCommand to avoid stale closure)
  const setCurrentRoomId = useCallback((id: number | null) => {
    currentRoomIdRef.current = id
    setCurrentRoomIdRaw(id)
  }, [])

  const sendCommand = useCallback(async (command: string) => {
    // clear/cls are UI-only (no server round-trip, no gameplay) — intentionally untracked
    if (['clear', 'cls', 'cl'].includes(command.toLowerCase())) {
      setOutput([])
      return
    }

    if (executingRef.current) return
    trackEvent('command_entered', command.split(' ')[0].toLowerCase())

    const echoLines = [
      '<div style="height: 1px; background: #444; margin-top: 16px; margin-bottom: 12px; overflow: hidden;"></div>',
      `<span style="color: #22d3ee;">&gt; ${command}</span>`
    ]

    setOutput(prev => [...prev, ...echoLines])

    executingRef.current = true
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

      const roomChanged = data.room_id && data.room_id !== currentRoomIdRef.current
      if (data.room_id) {
        setCurrentRoomId(data.room_id)
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
        setBreachRefreshToken(prev => prev + 1)
      } else if (wasInBreach && !nowInBreach) {
        // Breach just ended — show final output, then clear all breach state together
        inBreachRef.current = false
        const finalLines = [...echoLines]
        if (outputText) finalLines.push(outputText)
        setBreachOutput(finalLines)
        setBreachRefreshToken(prev => prev + 1)
        // Delay clearing so panel can show final output during slide-down
        setTimeout(() => {
          setInBreach(false)
          setBreachMeta(null)
          setBreachOutput([])
        }, 400)
      }

      // Targeted refresh: map only on room change, data always (vitals/inventory/etc change on most commands)
      if (roomChanged) {
        setMapRefreshToken(prev => prev + 1)
      }
      setDataRefreshToken(prev => prev + 1)

      return outputText
    } catch (err: unknown) {
      console.error('Command execution failed:', err)
      const raw = err instanceof Error ? err.message : 'Network error. Please try again.'
      const safe = raw.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      setOutput(prev => [...prev, `<span style="color: #f87171;">Error: ${safe}</span>`])
    } finally {
      executingRef.current = false
      setExecuting(false)
    }
  }, [setOutput, setCurrentRoomId])

  const value = useMemo<TacticalContextValue>(() => ({
    output, currentRoomId, executing,
    mapRefreshToken, dataRefreshToken, breachRefreshToken,
    inBreach, breachMeta, breachOutput,
    hasVendor, hasTransit, hasNpc, hasRestPod, npcMobs,
    sendCommand, setOutput, setCurrentRoomId,
    setHasVendor, setHasTransit, setHasNpc, setHasRestPod, setNpcMobs,
    commandInputRef
  }), [
    output, currentRoomId, executing,
    mapRefreshToken, dataRefreshToken, breachRefreshToken,
    inBreach, breachMeta, breachOutput,
    hasVendor, hasTransit, hasNpc, hasRestPod, npcMobs,
    sendCommand, setOutput, setCurrentRoomId, commandInputRef
  ])

  return (
    <TacticalContext.Provider value={value}>
      {children}
    </TacticalContext.Provider>
  )
}
