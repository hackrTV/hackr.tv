import React, { useState, useEffect, useRef, useCallback } from 'react'
import { apiJson } from '~/utils/apiClient'
import { BreachMeta, BreachProtocolMeta } from '../TacticalContext'

interface DeckData {
  deck: {
    name: string
    rarity_color: string
    battery_current: number
    battery_max: number
  } | null
  software: {
    id: number
    name: string
    rarity_color: string
    software_category: string
    battery_cost: number
    effect_magnitude: number
    target_types: string[] | null
  }[]
}

interface BreachPanelProps {
  visible: boolean
  breachMeta: BreachMeta | null
  breachOutput: string[]
  refreshToken: number
  onCommand: (cmd: string) => void
}

const CATEGORY_COLORS: Record<string, string> = {
  offensive: '#f87171',
  defensive: '#60a5fa',
  utility: '#fbbf24',
  exploit: '#a78bfa'
}

const TargetSelector: React.FC<{
  protocols: BreachProtocolMeta[]
  label: string
  onSelect: (position: number) => void
  onCancel: () => void
}> = ({ protocols, label, onSelect, onCancel }) => {
  const aliveProtocols = protocols.filter(p => p.alive)

  return (
    <div style={{
      position: 'absolute', top: '100%', left: 0, marginTop: '4px',
      background: '#1a1a1a', border: '1px solid #444', borderRadius: '4px',
      padding: '8px', zIndex: 50, minWidth: '160px'
    }}>
      <div style={{ color: '#888', fontSize: '0.75em', marginBottom: '6px' }}>{label}</div>
      <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
        {aliveProtocols.map(p => (
          <button
            key={p.position}
            onClick={() => onSelect(p.position + 1)}
            style={{
              background: '#222',
              border: '1px solid #555',
              borderRadius: '3px',
              padding: '4px 10px',
              color: '#d0d0d0',
              fontSize: '0.8em',
              cursor: 'pointer',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            [{p.position + 1}] {p.type_label}
          </button>
        ))}
      </div>
      <button
        onClick={onCancel}
        style={{
          background: 'none', border: 'none', color: '#666',
          fontSize: '0.7em', cursor: 'pointer', marginTop: '4px',
          fontFamily: '\'Courier New\', monospace'
        }}
      >
        cancel
      </button>
    </div>
  )
}

export const BreachPanel: React.FC<BreachPanelProps> = ({
  visible, breachMeta, breachOutput, refreshToken, onCommand
}) => {
  const [deckData, setDeckData] = useState<DeckData | null>(null)
  const [isRendered, setIsRendered] = useState(false)
  const [isOpen, setIsOpen] = useState(false)
  const [activeSelector, setActiveSelector] = useState<{ type: 'exec'; softwareName: string } | { type: 'analyze' } | { type: 'reroute' } | null>(null)
  const [jackoutConfirm, setJackoutConfirm] = useState(false)
  const outputRef = useRef<HTMLDivElement>(null)

  // Slide animation: mount first, then open; close first, then unmount
  // Double-rAF ensures browser paints the closed state before transitioning to open
  useEffect(() => {
    if (visible) {
      setIsRendered(true) // eslint-disable-line react-hooks/set-state-in-effect -- must mount before animating
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

  // Fetch deck data when panel is rendered
  useEffect(() => {
    if (isRendered) {
      apiJson<DeckData>('/api/grid/deck').then(setDeckData).catch(console.error)
    }
  }, [refreshToken, isRendered])

  // Auto-scroll breach output
  useEffect(() => {
    if (outputRef.current) {
      outputRef.current.scrollTop = outputRef.current.scrollHeight
    }
  }, [breachOutput])

  // Dismiss target selector on outside click
  const dismissSelector = useCallback(() => setActiveSelector(null), [])

  if (!isRendered) return null

  const protocols = breachMeta?.protocols || []
  const deck = deckData?.deck
  const software = deckData?.software || []

  const batteryPct = deck && deck.battery_max > 0
    ? Math.round((deck.battery_current / deck.battery_max) * 100) : 0

  return (
    <div
      onClick={dismissSelector}
      style={{
        position: 'absolute',
        left: 0,
        right: 0,
        bottom: 0,
        top: '15%',
        zIndex: 30,
        transform: isOpen ? 'translateY(0%)' : 'translateY(100%)',
        transition: 'transform 300ms ease-out',
        display: 'flex',
        flexDirection: 'column',
        background: '#0d0d0d',
        borderTop: '2px solid #22d3ee',
        borderRadius: '8px 8px 0 0',
        fontFamily: '\'Courier New\', monospace'
      }}
    >
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '8px 12px',
        background: '#111',
        borderBottom: '1px solid #333',
        flexShrink: 0
      }}>
        <div>
          <span style={{ color: '#22d3ee', fontWeight: 'bold', fontSize: '0.8em', letterSpacing: '1px' }}>
            BREACH
          </span>
          {breachMeta && (
            <>
              <span style={{ color: '#444', margin: '0 8px' }}>::</span>
              <span style={{ color: '#d0d0d0', fontSize: '0.8em' }}>{breachMeta.template_name}</span>
              <span style={{ color: '#666', fontSize: '0.7em', marginLeft: '8px' }}>{breachMeta.tier_label}</span>
            </>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          {breachMeta && (
            <span style={{ color: '#9ca3af', fontSize: '0.7em' }}>
              R{breachMeta.round_number} &middot; {breachMeta.actions_remaining}/{breachMeta.actions_this_round} actions
            </span>
          )}
          <button
            onClick={() => setJackoutConfirm(true)}
            style={{
              background: '#dc2626',
              color: 'white',
              border: 'none',
              padding: '3px 10px',
              fontSize: '0.7em',
              cursor: 'pointer',
              borderRadius: '3px',
              fontFamily: '\'Courier New\', monospace'
            }}
          >
            JACKOUT
          </button>
        </div>
      </div>

      {/* DECK snapshot + Action bar */}
      <div style={{
        display: 'flex',
        gap: '0',
        borderBottom: '1px solid #333',
        flexShrink: 0,
        background: '#0f0f0f',
        position: 'relative',
        zIndex: 10
      }}>
        {/* DECK snapshot */}
        <div style={{ padding: '8px 12px', borderRight: '1px solid #333', minWidth: '180px', maxWidth: '200px' }}>
          {deck ? (
            <>
              <div style={{ color: deck.rarity_color, fontSize: '0.7em', fontWeight: 'bold', marginBottom: '4px' }}>
                {deck.name}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                <span style={{ color: '#fbbf24', fontSize: '0.65em' }}>BAT</span>
                <div style={{
                  background: '#1a1a1a', borderRadius: '2px', height: '5px',
                  flex: 1, border: '1px solid #333', overflow: 'hidden'
                }}>
                  <div style={{
                    width: `${batteryPct}%`, height: '100%', borderRadius: '2px',
                    background: batteryPct > 25 ? '#34d399' : '#f87171'
                  }} />
                </div>
                <span style={{ color: '#888', fontSize: '0.6em' }}>{deck.battery_current}/{deck.battery_max}</span>
              </div>
            </>
          ) : (
            <div style={{ color: '#555', fontSize: '0.7em' }}>No DECK</div>
          )}
        </div>

        {/* Software action bar */}
        <div style={{
          flex: 1, padding: '6px 12px',
          display: 'flex', flexWrap: 'wrap', gap: '4px', alignItems: 'center', alignContent: 'flex-start'
        }}>
          {software.map(sw => {
            const catColor = CATEGORY_COLORS[sw.software_category] || '#9ca3af'
            return (
              <div key={sw.id} style={{ position: 'relative' }}>
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    setActiveSelector(
                      activeSelector?.type === 'exec' && activeSelector.softwareName === sw.name
                        ? null
                        : { type: 'exec', softwareName: sw.name }
                    )
                  }}
                  style={{
                    background: '#1a1a1a',
                    border: `1px solid ${catColor}44`,
                    borderRadius: '3px',
                    padding: '3px 8px',
                    color: sw.rarity_color,
                    fontSize: '0.65em',
                    cursor: 'pointer',
                    fontFamily: '\'Courier New\', monospace',
                    whiteSpace: 'nowrap'
                  }}
                  title={`${sw.software_category} · PWR:${sw.battery_cost} DMG:${sw.effect_magnitude}`}
                >
                  {sw.name}
                  <span style={{ color: '#666', marginLeft: '4px' }}>
                    {sw.battery_cost > 0 ? `⚡${sw.battery_cost}` : ''}
                  </span>
                </button>
                {activeSelector?.type === 'exec' && activeSelector.softwareName === sw.name && (
                  <TargetSelector
                    protocols={protocols}
                    label={`EXEC ${sw.name} →`}
                    onSelect={(pos) => { onCommand(`exec ${sw.name} ${pos}`); setActiveSelector(null) }}
                    onCancel={() => setActiveSelector(null)}
                  />
                )}
              </div>
            )
          })}

          {/* Quick action buttons */}
          <span style={{ color: '#333', margin: '0 2px' }}>|</span>
          {(['analyze', 'reroute'] as const).map(cmd => (
            <div key={cmd} style={{ position: 'relative' }}>
              <button
                onClick={(e) => {
                  e.stopPropagation()
                  setActiveSelector(activeSelector?.type === cmd ? null : { type: cmd })
                }}
                style={{
                  background: '#1a1a1a', border: '1px solid #333', borderRadius: '3px',
                  padding: '3px 8px', color: '#22d3ee', fontSize: '0.65em', cursor: 'pointer',
                  fontFamily: '\'Courier New\', monospace'
                }}
              >
                {cmd.toUpperCase()}
              </button>
              {activeSelector?.type === cmd && (
                <TargetSelector
                  protocols={protocols}
                  label={`${cmd.toUpperCase()} \u2192`}
                  onSelect={(pos) => { onCommand(`${cmd} ${pos}`); setActiveSelector(null) }}
                  onCancel={() => setActiveSelector(null)}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Breach output */}
      <div
        ref={outputRef}
        style={{
          flex: 1,
          minHeight: 0,
          overflowY: 'auto',
          overflowX: 'hidden',
          padding: '8px 12px',
          fontSize: '0.75em',
          lineHeight: '1.2',
          whiteSpace: 'pre-wrap',
          wordBreak: 'break-word',
          color: '#d0d0d0'
        }}
      >
        <style>{`
          @keyframes rainbow-cycle {
            0%   { color: #ff6b6b; }
            17%  { color: #fbbf24; }
            33%  { color: #34d399; }
            50%  { color: #22d3ee; }
            67%  { color: #60a5fa; }
            83%  { color: #a78bfa; }
            100% { color: #ff6b6b; }
          }
          .rarity-unicorn {
            animation: rainbow-cycle 3s linear infinite;
            font-weight: bold;
          }
        `}</style>
        {breachOutput.map((line, i) => (
          <div key={i} dangerouslySetInnerHTML={{ __html: line || '&nbsp;' }} />
        ))}
      </div>

      {jackoutConfirm && (
        <div
          style={{
            position: 'fixed', inset: 0, zIndex: 200,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'rgba(0,0,0,0.7)'
          }}
          onClick={() => setJackoutConfirm(false)}
        >
          <div
            style={{
              background: '#1a1a1a',
              border: '1px solid #444',
              borderRadius: '6px',
              padding: '24px 28px',
              maxWidth: '420px',
              fontFamily: '\'Courier New\', monospace'
            }}
            onClick={e => e.stopPropagation()}
          >
            <div style={{ color: '#f87171', fontWeight: 'bold', fontSize: '1.1em', marginBottom: '16px' }}>
              JACK OUT
            </div>
            <div style={{ color: '#888', fontSize: '0.85em', marginBottom: '20px' }}>
              Abort the current BREACH? Clean exit costs 5 EN. Past PNR costs 10 HP, 15 EN, 15 PS.
            </div>
            <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setJackoutConfirm(false)}
                style={{
                  background: 'transparent', color: '#888', border: '1px solid #444',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontFamily: '\'Courier New\', monospace'
                }}
              >
                CANCEL
              </button>
              <button
                onClick={() => { onCommand('jackout'); setJackoutConfirm(false) }}
                style={{
                  background: '#dc2626', color: 'white', border: 'none',
                  padding: '8px 20px', fontSize: '0.9em', cursor: 'pointer',
                  borderRadius: '3px', fontWeight: 'bold', fontFamily: '\'Courier New\', monospace'
                }}
              >
                JACKOUT
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
