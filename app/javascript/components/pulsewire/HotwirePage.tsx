import React, { useState, useEffect, useCallback, useRef } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import type { Pulse, PulseWireMessage, GridHackr } from '../../types/pulse'
import { PulseComposer } from './PulseComposer'
import { PulseCard } from './PulseCard'
import { usePulseWire } from '../../hooks/usePulseWire'

export const HotwirePage: React.FC = () => {
  const [pulses, setPulses] = useState<Pulse[]>([])
  const [currentHackr, setCurrentHackr] = useState<GridHackr | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [page, setPage] = useState(1)
  const [hasMore, setHasMore] = useState(true)
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const loadedPulseIds = useRef<Set<number>>(new Set())

  const fetchPulses = useCallback(async (pageNum: number = 1) => {
    try {
      const response = await fetch(`/api/pulses?page=${pageNum}&per_page=50&filter=active`, {
        credentials: 'include'
      })

      if (!response.ok) {
        throw new Error('Failed to load pulses')
      }

      const data = await response.json()

      // Set current hackr on initial load
      if (pageNum === 1 && data.current_hackr !== undefined) {
        setCurrentHackr(data.current_hackr)
      }

      if (pageNum === 1) {
        // Initial load - replace all pulses
        setPulses(data.pulses)
        loadedPulseIds.current = new Set(data.pulses.map((p: Pulse) => p.id))
      } else {
        // Load more - append unique pulses
        const newPulses = data.pulses.filter((p: Pulse) => !loadedPulseIds.current.has(p.id))
        setPulses(prev => [...prev, ...newPulses])
        newPulses.forEach((p: Pulse) => loadedPulseIds.current.add(p.id))
      }

      setHasMore(data.meta.page < data.meta.total_pages)
      setIsLoading(false)
      setIsLoadingMore(false)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load the Hotwire')
      setIsLoading(false)
      setIsLoadingMore(false)
    }
  }, [])

  // Initial load
  useEffect(() => {
    fetchPulses(1)
  }, [fetchPulses])

  // Real-time updates via Action Cable
  const handleWireMessage = useCallback((message: PulseWireMessage) => {
    switch (message.type) {
    case 'new_pulse':
      if (message.pulse && !loadedPulseIds.current.has(message.pulse.id)) {
        setPulses(prev => [message.pulse!, ...prev])
        loadedPulseIds.current.add(message.pulse.id)
      }
      break

    case 'pulse_deleted':
    case 'pulse_dropped':
      if (message.pulse_id) {
        setPulses(prev => prev.filter(p => p.id !== message.pulse_id))
        loadedPulseIds.current.delete(message.pulse_id)
      }
      break

    case 'echo_created':
    case 'echo_removed':
      if (message.pulse_id && message.echo_count !== undefined) {
        setPulses(prev => prev.map(p =>
          p.id === message.pulse_id
            ? { ...p, echo_count: message.echo_count!, is_echoed_by_current_hackr: message.type === 'echo_created' }
            : p
        ))
      }
      break
    }
  }, [])

  const { isConnected } = usePulseWire({
    onMessage: handleWireMessage,
    enabled: true
  })

  const handlePulseCreated = (newPulse: Pulse) => {
    // Pulse will be added via WebSocket, but add locally for instant feedback
    if (!loadedPulseIds.current.has(newPulse.id)) {
      setPulses(prev => [newPulse, ...prev])
      loadedPulseIds.current.add(newPulse.id)
    }
  }

  const handleEchoToggle = (pulseId: number, newEchoCount: number, isEchoed: boolean) => {
    setPulses(prev => prev.map(p =>
      p.id === pulseId
        ? { ...p, echo_count: newEchoCount, is_echoed_by_current_hackr: isEchoed }
        : p
    ))
  }

  const handlePulseDeleted = (pulseId: number) => {
    setPulses(prev => prev.filter(p => p.id !== pulseId))
    loadedPulseIds.current.delete(pulseId)
  }

  const handleLoadMore = useCallback(() => {
    if (!isLoadingMore && hasMore) {
      setIsLoadingMore(true)
      const nextPage = page + 1
      setPage(nextPage)
      fetchPulses(nextPage)
    }
  }, [isLoadingMore, hasMore, page, fetchPulses])

  // Infinite scroll detection
  useEffect(() => {
    const handleScroll = () => {
      if (isLoadingMore || !hasMore) return

      const scrollPosition = window.innerHeight + window.scrollY
      const bottomPosition = document.documentElement.scrollHeight - 500

      if (scrollPosition >= bottomPosition) {
        handleLoadMore()
      }
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [isLoadingMore, hasMore, handleLoadMore])

  if (isLoading) {
    return (
      <DefaultLayout>
        <div className="white-168-text" style={{ textAlign: 'center', padding: '40px' }}>
          Loading the Hotwire...
        </div>
      </DefaultLayout>
    )
  }

  if (error) {
    return (
      <DefaultLayout>
        <div className="red-255-text" style={{ padding: '20px', border: '1px solid #ff0000', marginBottom: '20px' }}>
          {error}
        </div>
        <button className="btn btn-primary" onClick={() => fetchPulses(1)}>Retry</button>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div className="hotwire-page white-168-text" style={{ maxWidth: '800px', margin: '0 auto', paddingTop: '30px' }}>
        <div className="hotwire-header">
          <h1 title="Wideband Information Relay Emitter">The WIRE</h1>
          <div className="wire-status">
            {isConnected ? (
              <span className="status-connected">● LIVE</span>
            ) : (
              <span className="status-disconnected">○ OFFLINE</span>
            )}
          </div>
        </div>

        <div className="pulse-composer-section">
          {currentHackr ? (
            <PulseComposer onPulseCreated={handlePulseCreated} />
          ) : (
            <div className="login-prompt" style={{
              padding: '20px',
              textAlign: 'center',
              background: 'rgba(124, 58, 237, 0.1)',
              border: '1px solid #7c3aed',
              marginBottom: '30px'
            }}>
              <p style={{ margin: '0 0 10px 0', color: '#a78bfa' }}>
                <Link to="/grid/login" style={{ color: '#60a5fa', textDecoration: 'none' }}>
                Log in
                </Link>
                {' '}to broadcast on the WIRE
              </p>
              <p style={{ margin: 0, color: '#666', fontSize: '0.8rem', fontFamily: "'Courier New', monospace" }}>
                Wideband Information Relay Emitter
              </p>
            </div>
          )}
        </div>

        <div className="hotwire-timeline">
          {pulses.length === 0 ? (
            <div className="empty-state">
              <p>The WIRE is silent. Broadcast the first pulse.</p>
              <p style={{ color: '#444', fontSize: '0.8rem', marginTop: '10px' }}>
                Wideband Information Relay Emitter
              </p>
            </div>
          ) : (
            <>
              {pulses.map(pulse => (
                <PulseCard
                  key={pulse.id}
                  pulse={pulse}
                  onEchoToggle={handleEchoToggle}
                  onPulseCreated={handlePulseCreated}
                  onPulseDeleted={handlePulseDeleted}
                />
              ))}

              {isLoadingMore && (
                <div className="loading-more">Loading more pulses...</div>
              )}

              {!hasMore && pulses.length > 0 && (
                <div className="end-of-feed">
                  <p>End of the WIRE</p>
                  <p style={{ color: '#444', fontSize: '0.75rem', marginTop: '10px' }}>
                    W.I.R.E. // Wideband Information Relay Emitter
                  </p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    </DefaultLayout>
  )
}
