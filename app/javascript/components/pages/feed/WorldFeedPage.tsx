import React, { useEffect, useState, useRef, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { getActionCableConsumer } from '~/lib/actionCableConsumer'
import { useAppSettings } from '~/contexts/AppSettingsContext'

interface WorldEventData {
  new_clearance?: number
  mission_name?: string
  template_name?: string
  tier?: string
  faction_name?: string
  new_tier?: string
  direction?: string
  achievement_name?: string
  badge_icon?: string
  content?: string
  message?: string
}

interface WorldEvent {
  id: number
  event_type: string
  hackr_alias: string
  data: WorldEventData
  message: string
  created_at: string
}

const EVENT_COLORS: Record<string, string> = {
  clearance_up: '#fbbf24',
  mission_accepted: '#22d3ee',
  mission_completed: '#34d399',
  breach_completed: '#f97316',
  rep_tier_changed: '#a78bfa',
  achievement_unlocked: '#fbbf24',
  hackr_registered: '#22d3ee',
  wire_post: '#9ca3af',
  manual: '#d0d0d0'
}

const TYPING_SPEED_MS = 16
const MAX_LINES = 50

interface DisplayLine {
  key: number
  event: WorldEvent
  text: string
  typedLength: number
  done: boolean
}

let lineKeyCounter = 0

function formatEventText (event: WorldEvent): string {
  const d = event.data || {}
  const a = event.hackr_alias

  switch (event.event_type) {
  case 'clearance_up':
    return `${a} reached CLEARANCE ${d.new_clearance}`
  case 'mission_accepted':
    return `${a} accepted mission: ${d.mission_name}`
  case 'mission_completed':
    return `${a} completed mission: ${d.mission_name}`
  case 'breach_completed':
    return `${a} completed ${d.tier || 'standard'}-tier BREACH: ${d.template_name}`
  case 'rep_tier_changed': {
    const verb = d.direction === 'down' ? 'dropped to' : 'reached'
    return `${a} ${verb} ${d.new_tier} standing with ${d.faction_name}`
  }
  case 'achievement_unlocked': {
    const icon = d.badge_icon ? `${d.badge_icon} ` : ''
    return `${a} unlocked ${icon}${d.achievement_name}`
  }
  case 'hackr_registered':
    return `${a} jacked into THE PULSE GRID for the first time`
  case 'wire_post':
    return `${a} posted to THE WIRE: "${d.content}"`
  case 'manual':
    return d.message || `${a}: system event`
  default:
    return event.message || `${a}: ${event.event_type}`
  }
}

export const WorldFeedPage: React.FC = () => {
  const { isWorldFeedVisible, isLoading } = useAppSettings()
  const navigate = useNavigate()

  useEffect(() => {
    if (!isLoading && !isWorldFeedVisible) {
      navigate('/', { replace: true })
    }
  }, [isLoading, isWorldFeedVisible, navigate])

  // Inject @keyframes blink for cursor animation
  useEffect(() => {
    const id = 'world-feed-blink-keyframes'
    if (!document.getElementById(id)) {
      const style = document.createElement('style')
      style.id = id
      style.textContent = '@keyframes blink { 50% { opacity: 0; } }'
      document.head.appendChild(style)
    }
  }, [])

  const [lines, setLines] = useState<DisplayLine[]>([])
  const [connected, setConnected] = useState(false)
  const containerRef = useRef<HTMLDivElement>(null)

  // All typing state lives in refs to avoid stale closures and re-render churn
  const seenIdsRef = useRef<Set<number>>(new Set())
  const queueRef = useRef<WorldEvent[]>([])
  const typingRef = useRef(false)
  const mountedRef = useRef(true)
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)
  const timeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  const processQueue = useCallback(() => {
    if (!mountedRef.current || typingRef.current || queueRef.current.length === 0) return
    typingRef.current = true

    const event = queueRef.current.shift()!
    const text = formatEventText(event)
    const key = ++lineKeyCounter

    // Add line with 0 typed chars
    setLines(prev => [...prev, { key, event, text, typedLength: 0, done: false }].slice(-MAX_LINES))

    let charIdx = 0
    timerRef.current = setInterval(() => {
      if (!mountedRef.current) {
        clearInterval(timerRef.current!)
        return
      }
      charIdx++
      if (charIdx >= text.length) {
        // Done typing this line
        clearInterval(timerRef.current!)
        timerRef.current = null
        setLines(prev => prev.map(l =>
          l.key === key ? { ...l, typedLength: text.length, done: true } : l
        ))
        typingRef.current = false
        timeoutRef.current = setTimeout(processQueue, 150 + Math.random() * 300)
      } else {
        // Advance cursor
        setLines(prev => prev.map(l =>
          l.key === key ? { ...l, typedLength: charIdx } : l
        ))
      }
    }, TYPING_SPEED_MS)
  }, [])

  const addEvent = useCallback((event: WorldEvent) => {
    // Dedup — skip events already seen or already in queue
    if (seenIdsRef.current.has(event.id)) return
    seenIdsRef.current.add(event.id)
    // Cap seen set size to prevent unbounded growth
    if (seenIdsRef.current.size > 200) {
      const iter = seenIdsRef.current.values()
      for (let i = 0; i < 100; i++) iter.next()
      // Keep only the newer half — rebuild from iterator position
      const keep = new Set<number>()
      let next = iter.next()
      while (!next.done) { keep.add(next.value); next = iter.next() }
      seenIdsRef.current = keep
    }

    queueRef.current.push(event)
    processQueue()
  }, [processQueue])

  // Stable refs for ActionCable callback
  const addEventRef = useRef(addEvent)
  useEffect(() => { addEventRef.current = addEvent }, [addEvent])

  // Cleanup on unmount
  useEffect(() => {
    mountedRef.current = true
    return () => {
      mountedRef.current = false
      if (timerRef.current) clearInterval(timerRef.current)
      if (timeoutRef.current) clearTimeout(timeoutRef.current)
    }
  }, [])

  // ActionCable subscription — runs once, dedup handles strict mode double-fire
  useEffect(() => {
    const cable = getActionCableConsumer()
    const subscription = cable.subscriptions.create('WorldEventFeedChannel', {
      connected () { setConnected(true) },
      disconnected () { setConnected(false) },
      received (data: { type: string; event?: WorldEvent; events?: WorldEvent[] }) {
        if (data.type === 'initial_events' && data.events) {
          const initialLines: DisplayLine[] = data.events.map(e => {
            seenIdsRef.current.add(e.id)
            const text = formatEventText(e)
            return { key: ++lineKeyCounter, event: e, text, typedLength: text.length, done: true }
          })
          setLines(initialLines.slice(-MAX_LINES))
        } else if (data.type === 'world_event' && data.event) {
          addEventRef.current(data.event)
        }
      }
    })

    return () => { subscription.unsubscribe() }
  }, [])

  // Auto-scroll to bottom
  useEffect(() => {
    if (containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight
    }
  }, [lines])

  return (
    <DefaultLayout showAsciiArt={false}>
      <div style={styles.wrapper}>
        <div style={styles.screen}>
          <div style={styles.header}>
            <span style={styles.headerTitle}>HACKR.TV // WORLD FEED</span>
            <span style={{ ...styles.headerStatus, color: connected ? '#34d399' : '#ef4444' }}>
              {connected ? '[ CONNECTED ]' : '[ DISCONNECTED ]'}
            </span>
          </div>

          <div style={styles.scanlineOverlay} />

          <div ref={containerRef} style={styles.feedContainer}>
            {lines.map((line, idx) => {
              const age = lines.length - 1 - idx
              const opacity = age > 40 ? 0.2 : age > 30 ? 0.4 : age > 20 ? 0.6 : 1
              const accentColor = EVENT_COLORS[line.event.event_type] || '#d0d0d0'

              return (
                <div key={line.key} style={{ ...styles.line, opacity }}>
                  <span style={styles.linePrefix}>{'>'}</span>
                  <span style={{ color: accentColor }}>
                    {line.text.substring(0, line.typedLength)}
                  </span>
                  {!line.done && <span style={styles.cursor}>_</span>}
                </div>
              )
            })}

            {lines.length === 0 && (
              <div style={styles.emptyState}>
                <span style={{ color: '#666' }}>Awaiting signal...</span>
                <span style={styles.cursor}>_</span>
              </div>
            )}
          </div>

          <div style={styles.footer}>
            <span style={{ color: '#4b5563' }}>
              {lines.filter(l => l.done).length} events loaded
            </span>
            <span style={{ color: '#4b5563' }}>
              hackr.tv/feed
            </span>
          </div>
        </div>
      </div>
    </DefaultLayout>
  )
}

const styles: Record<string, React.CSSProperties> = {
  wrapper: {
    display: 'flex',
    justifyContent: 'center',
    padding: '20px',
    minHeight: '80vh'
  },
  screen: {
    width: '100%',
    maxWidth: '1000px',
    background: '#0a0a0a',
    border: '2px solid #22d3ee',
    borderRadius: '4px',
    position: 'relative' as const,
    overflow: 'hidden',
    display: 'flex',
    flexDirection: 'column' as const
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px 20px',
    borderBottom: '1px solid #1a3a3a',
    background: '#050505'
  },
  headerTitle: {
    color: '#22d3ee',
    fontFamily: 'monospace',
    fontSize: '16px',
    fontWeight: 'bold',
    letterSpacing: '2px'
  },
  headerStatus: {
    fontFamily: 'monospace',
    fontSize: '12px'
  },
  scanlineOverlay: {
    position: 'absolute' as const,
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 255, 255, 0.015) 2px, rgba(0, 255, 255, 0.015) 4px)',
    pointerEvents: 'none' as const,
    zIndex: 1
  },
  feedContainer: {
    flex: 1,
    padding: '16px 20px',
    overflowY: 'auto' as const,
    minHeight: '500px',
    maxHeight: '700px',
    fontFamily: '"Courier New", monospace',
    fontSize: '14px',
    lineHeight: '1.6'
  },
  line: {
    marginBottom: '2px',
    whiteSpace: 'nowrap' as const,
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    transition: 'opacity 0.5s ease-out'
  },
  linePrefix: {
    color: '#22d3ee',
    marginRight: '8px',
    fontWeight: 'bold'
  },
  cursor: {
    display: 'inline-block',
    color: '#22d3ee',
    animation: 'blink 0.6s step-end infinite'
  },
  emptyState: {
    display: 'flex',
    alignItems: 'center',
    gap: '4px',
    padding: '40px 0'
  },
  footer: {
    display: 'flex',
    justifyContent: 'space-between',
    padding: '8px 20px',
    borderTop: '1px solid #1a3a3a',
    background: '#050505',
    fontFamily: 'monospace',
    fontSize: '11px'
  }
}
