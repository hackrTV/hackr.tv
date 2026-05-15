import React, { useEffect, useRef, useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useActionCable, GridEvent } from '~/hooks/useActionCable'
import { TacticalProvider, useTactical } from '~/components/tactical/TacticalContext'
import { TacticalBar } from '~/components/tactical/TacticalBar'
import { TacticalTerminal } from '~/components/tactical/TacticalTerminal'
import { TacticalStatusPanel } from '~/components/tactical/TacticalStatusPanel'
import { ZoneMap } from '~/components/tactical/map/ZoneMap'
import { BreachTargetButtons } from '~/components/tactical/breach/BreachTargetButtons'
import { BreachConfirmModal } from '~/components/tactical/breach/BreachConfirmModal'
import { BreachPanel } from '~/components/tactical/breach/BreachPanel'
import { BreachEncounter, DeckStatus } from '~/types/zoneMap'
import { VendorHandle } from '~/components/tactical/vendor/VendorHandle'
import { VendorPanel } from '~/components/tactical/vendor/VendorPanel'
import { TransitHandle } from '~/components/tactical/transit/TransitHandle'
import { TransitPanel } from '~/components/tactical/transit/TransitPanel'

const TacticalInner: React.FC = () => {
  const { hackr } = useGridAuth()
  const {
    currentRoomId, setCurrentRoomId, setOutput,
    refreshToken, sendCommand, commandInputRef,
    inBreach, breachMeta, breachOutput,
    hasVendor, setHasVendor,
    hasTransit, setHasTransit
  } = useTactical()
  const initialLoadDoneRef = useRef(false)
  const [breachEncounters, setBreachEncounters] = useState<BreachEncounter[]>([])
  const [deckStatus, setDeckStatus] = useState<DeckStatus>({ equipped: false, fried: false })
  const [confirmTarget, setConfirmTarget] = useState<BreachEncounter | null>(null)
  const [vendorOpen, setVendorOpen] = useState(false)
  const [transitOpen, setTransitOpen] = useState(false)

  const handleBreachEncountersChange = useCallback((encounters: BreachEncounter[], ds: DeckStatus) => {
    setBreachEncounters(encounters)
    setDeckStatus(ds)
  }, [])

  const handleVendorPresenceChange = useCallback((v: boolean) => {
    setHasVendor(v)
    if (!v) setVendorOpen(false)
  }, [setHasVendor])

  const handleTransitPresenceChange = useCallback((v: boolean) => {
    setHasTransit(v)
    if (!v) setTransitOpen(false)
  }, [setHasTransit])

  // Close panels when breach starts
  useEffect(() => {
    if (inBreach) {
      setVendorOpen(false)
      setTransitOpen(false)
    }
  }, [inBreach])

  const handleBreachConfirm = useCallback(() => {
    if (confirmTarget) {
      sendCommand(`breach ${confirmTarget.name}`)
      setConfirmTarget(null)
    }
  }, [confirmTarget, sendCommand])

  // Tab anywhere → focus command input
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Tab') {
        e.preventDefault()
        commandInputRef.current?.focus()
      }
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [commandInputRef])

  // Set initial room and execute look (routes through sendCommand for breach state detection)
  useEffect(() => {
    if (hackr?.current_room && !initialLoadDoneRef.current) {
      initialLoadDoneRef.current = true
      setCurrentRoomId(hackr.current_room.id)

      setOutput([`<div style="color: #a78bfa; font-size: 0.9em;">
════════════════════════════════════════════════════
  TACTICAL INTERFACE — THE PULSE GRID
════════════════════════════════════════════════════
</div>`])

      sendCommand('look')
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps -- sendCommand is stable (useCallback with []), initialLoadDoneRef guards against re-fire
  }, [hackr, setCurrentRoomId, setOutput])

  // ActionCable for room events (terminal output)
  const handleEvent = React.useCallback((event: GridEvent) => {
    const ts = new Date().toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit' })
    let message = ''

    switch (event.type) {
    case 'say':
      message = `\n<span style="color: #a78bfa;">[${event.hackr_alias}]</span>: ${event.message}`
      break
    case 'movement':
      if (event.to_room_id === currentRoomId) {
        message = `\n<span style="color: #22d3ee;">[${ts}] ${event.hackr_alias} arrives.</span>`
      } else if (event.from_room_id === currentRoomId) {
        message = `\n<span style="color: #22d3ee;">[${ts}] ${event.hackr_alias} departs.</span>`
      }
      break
    case 'take':
      message = `\n<span style="color: #fbbf24;">[${ts}] ${event.hackr_alias} takes the ${event.item_name}.</span>`
      break
    case 'drop':
      message = `\n<span style="color: #fbbf24;">[${ts}] ${event.hackr_alias} drops the ${event.item_name}.</span>`
      break
    case 'system_broadcast':
      message = `\n<span style="color: #f87171; font-weight: bold;">[${ts}] ${event.message}</span>`
      break
    }

    if (message) setOutput(prev => [...prev, message])
  }, [currentRoomId, setOutput])

  const { connectionStatus } = useActionCable({
    roomId: currentRoomId,
    onEvent: handleEvent,
    enabled: !!hackr && !!currentRoomId
  })

  return (
    <div style={{
      position: 'fixed',
      inset: 0,
      overflow: 'hidden',
      display: 'grid',
      gridTemplateAreas: '"topbar topbar" "leftcol map" "cmdinput cmdinput"',
      gridTemplateColumns: '50fr 50fr',
      gridTemplateRows: '44px 1fr 58px',
      background: '#0a0a0a',
      fontFamily: '\'Courier New\', Courier, monospace',
      color: '#d0d0d0'
    }}>
      <div style={{ gridArea: 'topbar' }}>
        <TacticalBar connectionStatus={connectionStatus} refreshToken={refreshToken} />
      </div>

      <div style={{
        gridArea: 'leftcol',
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden'
      }}>
        <div style={{ flex: 2, minHeight: 0, overflow: 'hidden', borderBottom: '1px solid #333' }}>
          <TacticalStatusPanel refreshToken={refreshToken} onCommand={sendCommand} hasVendor={hasVendor} />
        </div>
        <div style={{ flex: 3, minHeight: 0, overflow: 'hidden', padding: '6px' }}>
          <TacticalTerminal />
        </div>
      </div>

      <div style={{ gridArea: 'map', overflow: 'hidden', borderLeft: '1px solid #333', position: 'relative' }}>
        <ZoneMap
          refreshToken={refreshToken}
          currentRoomId={currentRoomId}
          onNavigate={(dir) => sendCommand(`go ${dir}`)}
          onBreachEncountersChange={handleBreachEncountersChange}
          onVendorPresenceChange={handleVendorPresenceChange}
          onTransitPresenceChange={handleTransitPresenceChange}
        />
        {!inBreach && breachEncounters.length > 0 && (
          <BreachTargetButtons
            encounters={breachEncounters}
            deckStatus={deckStatus}
            onSelect={setConfirmTarget}
          />
        )}
        <BreachPanel
          visible={inBreach}
          breachMeta={breachMeta}
          breachOutput={breachOutput}
          refreshToken={refreshToken}
          onCommand={sendCommand}
        />
        {hasTransit && !inBreach && !vendorOpen && !transitOpen && (
          <TransitHandle onClick={() => setTransitOpen(true)} />
        )}
        <TransitPanel
          visible={transitOpen && !inBreach}
          refreshToken={refreshToken}
          onCommand={sendCommand}
          onClose={() => setTransitOpen(false)}
        />
        {hasVendor && !inBreach && !vendorOpen && !transitOpen && (
          <VendorHandle onClick={() => setVendorOpen(true)} />
        )}
        <VendorPanel
          visible={vendorOpen && !inBreach}
          refreshToken={refreshToken}
          onCommand={sendCommand}
          onClose={() => setVendorOpen(false)}
        />
      </div>

      <div style={{
        gridArea: 'cmdinput',
        padding: '8px 12px',
        borderTop: '1px solid #333',
        background: '#111'
      }}>
        <div style={{ fontSize: '0.75em', color: '#555', textAlign: 'center' }}>
          {inBreach
            ? <>BREACH: exec [prog] [#], analyze [#], reroute [#], use [item], interface [gate] [ans], jackout, status, help</>
            : <>Commands: look, go [dir], take/drop [item], say [msg], talk/ask [npc], inventory, who, help, clear
              <span style={{ marginLeft: '10px', color: '#333' }}>|</span>
              <span style={{ marginLeft: '10px' }}>↑/↓ for history</span>
            </>
          }
        </div>
      </div>

      {confirmTarget && (
        <BreachConfirmModal
          encounter={confirmTarget}
          onConfirm={handleBreachConfirm}
          onCancel={() => setConfirmTarget(null)}
        />
      )}
    </div>
  )
}

export const GridTacticalPage: React.FC = () => {
  const { hackr, loading: authLoading } = useGridAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (!authLoading && !hackr) {
      navigate('/grid/login')
    }
  }, [hackr, authLoading, navigate])

  if (authLoading) {
    return (
      <div style={{
        position: 'fixed', inset: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        background: '#0a0a0a', color: '#a78bfa',
        fontFamily: '\'Courier New\', monospace'
      }}>
        Loading TACTICAL INTERFACE...
      </div>
    )
  }

  if (!hackr) return null

  return (
    <TacticalProvider>
      <TacticalInner />
    </TacticalProvider>
  )
}
