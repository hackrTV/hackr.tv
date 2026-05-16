import React, { useState, useEffect, useCallback } from 'react'
import { apiJson } from '~/utils/apiClient'
import { RestPodData } from '~/types/zoneMap'
import { useTactical } from '../TacticalContext'

interface RestPodPanelProps {
  visible: boolean
  refreshToken: number
  onCommand: (cmd: string) => void
  onClose: () => void
}

const VITALS = ['health', 'energy', 'psyche'] as const
type VitalKey = typeof VITALS[number]

const VITAL_LABELS: Record<VitalKey, string> = {
  health: 'HEALTH',
  energy: 'ENERGY',
  psyche: 'PSYCHE'
}

const VITAL_COLORS: Record<VitalKey, string> = {
  health: '#34d399',
  energy: '#60a5fa',
  psyche: '#c084fc'
}

export const RestPodPanel: React.FC<RestPodPanelProps> = ({
  visible, refreshToken, onCommand, onClose
}) => {
  const { executing } = useTactical()
  const [isRendered, setIsRendered] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [podData, setPodData] = useState<RestPodData | null>(null)
  const [allocs, setAllocs] = useState<Record<VitalKey, string>>({
    health: '', energy: '', psyche: ''
  })

  // Slide animation: mount first, then open; close first, then unmount
  useEffect(() => {
    if (visible) {
      setIsRendered(true)
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setIsOpen(true))
      })
      return () => cancelAnimationFrame(raf)
    } else {
      setIsOpen(false)
      const timer = setTimeout(() => setIsRendered(false), 300)
      return () => clearTimeout(timer)
    }
  }, [visible])

  // Fetch data when panel renders or refreshToken changes
  useEffect(() => {
    if (isRendered) {
      apiJson<RestPodData>('/api/grid/rest_pod').then(setPodData).catch(console.error)
    }
  }, [refreshToken, isRendered])

  // Reset allocations when panel closes
  useEffect(() => {
    if (!visible) {
      setAllocs({ health: '', energy: '', psyche: '' })
    }
  }, [visible])

  const getDeficit = (vital: VitalKey): number => {
    if (!podData) return 0
    const v = podData.vitals[vital]
    return Math.max(0, v.max - v.current)
  }

  const getPoints = (vital: VitalKey): number => {
    const raw = parseInt(allocs[vital], 10)
    if (!raw || raw <= 0) return 0
    return Math.min(raw, getDeficit(vital))
  }

  const totalPoints = VITALS.reduce((sum, v) => sum + getPoints(v), 0)
  const totalCred = podData ? Math.ceil(totalPoints / podData.rate) : 0
  const canAfford = podData ? totalCred <= podData.balance : false
  const hasAllocation = totalPoints > 0

  const handleFill = useCallback((vital: VitalKey) => {
    const deficit = getDeficit(vital)
    setAllocs(prev => ({ ...prev, [vital]: deficit > 0 ? String(deficit) : '' }))
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [podData])

  const handleFillAll = useCallback(() => {
    const next: Record<VitalKey, string> = { health: '', energy: '', psyche: '' }
    for (const v of VITALS) {
      const deficit = getDeficit(v)
      if (deficit > 0) next[v] = String(deficit)
    }
    setAllocs(next)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [podData])

  const handleConfirm = useCallback(() => {
    if (!podData || !canAfford || !hasAllocation) return
    const parts: string[] = []
    for (const v of VITALS) {
      const pts = getPoints(v)
      if (pts > 0) parts.push(`${pts} ${v}`)
    }
    if (parts.length === 0) return
    onCommand(`rest ${parts.join(' ')}`)
    onClose()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [allocs, podData, canAfford, hasAllocation, onCommand, onClose])

  const handleBackdropClick = useCallback((e: React.MouseEvent) => {
    e.stopPropagation()
    onClose()
  }, [onClose])

  if (!isRendered) return null

  return (
    <>
      <div
        onClick={handleBackdropClick}
        style={{
          position: 'absolute', inset: 0, zIndex: 29,
          background: isOpen ? 'rgba(0,0,0,0.2)' : 'transparent',
          transition: 'background 300ms ease-out'
        }}
      />
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          position: 'absolute', top: 0, right: 0, bottom: 0, width: '50%',
          zIndex: 30,
          transform: isOpen ? 'translateX(0%)' : 'translateX(100%)',
          transition: 'transform 300ms ease-out',
          display: 'flex', flexDirection: 'column',
          background: '#0d0d0d',
          borderLeft: '2px solid #34d399',
          fontFamily: '\'Courier New\', monospace'
        }}
      >
        {/* Header */}
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '8px 12px', background: '#111',
          borderBottom: '1px solid #333', flexShrink: 0
        }}>
          <div>
            <span style={{ color: '#34d399', fontWeight: 'bold', fontSize: '0.8em', letterSpacing: '1px' }}>
              REST POD
            </span>
            {podData && (
              <>
                <span style={{ color: '#444', margin: '0 8px' }}>::</span>
                <span style={{ color: '#fbbf24', fontSize: '0.7em' }}>{podData.balance} CRED</span>
                <span style={{ color: '#666', fontSize: '0.65em', marginLeft: '8px' }}>
                  {podData.rate} pts/CRED
                </span>
              </>
            )}
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'transparent', color: '#888', border: '1px solid #444',
              padding: '3px 10px', fontSize: '0.7em', cursor: 'pointer',
              borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
            }}
          >CLOSE</button>
        </div>

        {/* Body */}
        <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', padding: '12px 14px' }}>
          {!podData ? (
            <div style={{ color: '#555', fontSize: '0.8em' }}>Loading...</div>
          ) : (
            <>
              {VITALS.map(v => {
                const vi = podData.vitals[v]
                const deficit = getDeficit(v)
                const pts = getPoints(v)
                const color = VITAL_COLORS[v]
                const pct = vi.max > 0 ? (vi.current / vi.max) * 100 : 0

                return (
                  <div key={v} style={{ marginBottom: '18px' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
                      <span style={{ color, fontSize: '0.75em', fontWeight: 'bold', letterSpacing: '1px' }}>
                        {VITAL_LABELS[v]}
                      </span>
                      <span style={{ color: '#888', fontSize: '0.7em' }}>
                        {vi.current} / {vi.max}
                        {deficit > 0 && <span style={{ color: '#555' }}> ({deficit} missing)</span>}
                      </span>
                    </div>
                    {/* Bar */}
                    <div style={{ height: '4px', background: '#222', borderRadius: '2px', marginBottom: '8px', position: 'relative' }}>
                      <div style={{
                        height: '100%', borderRadius: '2px',
                        background: color,
                        width: `${pct}%`,
                        transition: 'width 300ms'
                      }} />
                      {pts > 0 && (
                        <div style={{
                          position: 'absolute', top: 0, height: '100%',
                          borderRadius: '2px',
                          background: color,
                          opacity: 0.35,
                          left: `${pct}%`,
                          width: `${(pts / vi.max) * 100}%`,
                          transition: 'width 300ms, left 300ms'
                        }} />
                      )}
                    </div>
                    {deficit > 0 ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <input
                          type="number"
                          min={0}
                          max={deficit}
                          placeholder="pts"
                          value={allocs[v]}
                          onChange={(e) => setAllocs(prev => ({ ...prev, [v]: e.target.value }))}
                          style={{
                            width: '72px', background: '#1a1a1a', border: '1px solid #333',
                            color: '#d0d0d0', padding: '4px 6px', fontSize: '0.75em',
                            fontFamily: '\'Courier New\', monospace', borderRadius: '3px',
                            outline: 'none'
                          }}
                        />
                        <span style={{ color: '#555', fontSize: '0.7em' }}>pts</span>
                        <button
                          onClick={() => handleFill(v)}
                          style={{
                            background: 'transparent', border: `1px solid ${color}`,
                            color, padding: '2px 8px', fontSize: '0.65em', cursor: 'pointer',
                            borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                          }}
                        >FULL</button>
                        {pts > 0 && (
                          <span style={{ color, fontSize: '0.7em' }}>
                            +{pts} → {vi.current + pts}/{vi.max}
                          </span>
                        )}
                      </div>
                    ) : (
                      <span style={{ color: '#34d399', fontSize: '0.7em' }}>FULL</span>
                    )}
                  </div>
                )
              })}

              {/* Footer: cost + buttons */}
              <div style={{ borderTop: '1px solid #222', paddingTop: '12px', marginTop: '8px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div>
                    <span style={{ color: '#888', fontSize: '0.75em' }}>
                      Total: <span style={{ color: hasAllocation ? (canAfford ? '#fbbf24' : '#f87171') : '#555' }}>
                        {totalPoints} pts → {totalCred} CRED
                      </span>
                    </span>
                    {!canAfford && totalCred > 0 && (
                      <div style={{ color: '#f87171', fontSize: '0.65em', marginTop: '4px' }}>Insufficient CRED</div>
                    )}
                  </div>
                  <div style={{ display: 'flex', gap: '8px' }}>
                    <button
                      onClick={handleFillAll}
                      style={{
                        background: 'transparent', border: '1px solid #555',
                        color: '#888', padding: '5px 12px', fontSize: '0.7em', cursor: 'pointer',
                        borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                      }}
                    >FILL ALL</button>
                    <button
                      onClick={handleConfirm}
                      disabled={!canAfford || !hasAllocation || executing}
                      style={{
                        background: canAfford && hasAllocation && !executing ? '#34d399' : '#333',
                        color: canAfford && hasAllocation && !executing ? '#0a0a0a' : '#666',
                        border: 'none', borderRadius: '3px', padding: '5px 16px',
                        fontSize: '0.8em', fontWeight: 'bold',
                        cursor: canAfford && hasAllocation && !executing ? 'pointer' : 'not-allowed',
                        fontFamily: '\'Courier New\', monospace'
                      }}
                    >RESTORE</button>
                  </div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </>
  )
}
