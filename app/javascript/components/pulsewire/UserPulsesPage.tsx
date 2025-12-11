import React, { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import type { Pulse } from '../../types/pulse'
import { PulseCard } from './PulseCard'

interface ProfilePulse extends Pulse {
  is_echo_on_profile?: boolean
}

export const UserPulsesPage: React.FC = () => {
  const { username } = useParams<{ username: string }>()
  const [pulses, setPulses] = useState<ProfilePulse[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [authoredCount, setAuthoredCount] = useState(0)
  const [echoedCount, setEchoedCount] = useState(0)

  useEffect(() => {
    const fetchUserPulses = async () => {
      try {
        setIsLoading(true)

        // Fetch both authored pulses and echoed pulses in parallel
        const [authoredResponse, echoedResponse] = await Promise.all([
          fetch(`/api/pulses?hackr=${username}&filter=active&per_page=100&include_splices=true`, {
            credentials: 'include'
          }),
          fetch(`/api/pulses?echoed_by=${username}&filter=active&per_page=100&include_splices=true`, {
            credentials: 'include'
          })
        ])

        if (!authoredResponse.ok || !echoedResponse.ok) {
          throw new Error('Failed to load pulses')
        }

        const [authoredData, echoedData] = await Promise.all([
          authoredResponse.json(),
          echoedResponse.json()
        ])

        // Mark echoed pulses and merge
        const authoredPulses: ProfilePulse[] = authoredData.pulses.map((p: Pulse) => ({
          ...p,
          is_echo_on_profile: false
        }))

        const echoedPulses: ProfilePulse[] = echoedData.pulses
          // Filter out pulses that the user also authored (don't show both)
          .filter((p: Pulse) => p.grid_hackr.hackr_alias.toLowerCase() !== username?.toLowerCase())
          .map((p: Pulse) => ({
            ...p,
            is_echo_on_profile: true
          }))

        // Combine and sort by pulsed_at descending
        const combined = [...authoredPulses, ...echoedPulses].sort((a, b) =>
          new Date(b.pulsed_at).getTime() - new Date(a.pulsed_at).getTime()
        )

        setPulses(combined)
        setAuthoredCount(authoredPulses.length)
        setEchoedCount(echoedPulses.length)
        setIsLoading(false)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load user pulses')
        setIsLoading(false)
      }
    }

    if (username) {
      fetchUserPulses()
    }
  }, [username])

  const handleEchoToggle = (pulseId: number, newEchoCount: number, isEchoed: boolean) => {
    setPulses(prev => prev.map(p =>
      p.id === pulseId
        ? { ...p, echo_count: newEchoCount, is_echoed_by_current_hackr: isEchoed }
        : p
    ))
  }

  const handlePulseCreated = (newPulse: Pulse) => {
    setPulses(prev => [{ ...newPulse, is_echo_on_profile: false }, ...prev])
  }

  const handlePulseDeleted = (pulseId: number) => {
    setPulses(prev => prev.filter(p => p.id !== pulseId))
  }

  if (isLoading) {
    return (
      <DefaultLayout>
        <div className="white-168-text" style={{ textAlign: 'center', padding: '40px' }}>
          Loading pulses...
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
        <Link to="/wire" className="btn btn-primary">Back to Hotwire</Link>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div className="user-pulses-page white-168-text" style={{ maxWidth: '800px', margin: '0 auto', paddingTop: '30px' }}>
        <div className="user-header">
          <h1>@{username}</h1>
          <div className="user-stats">
            {authoredCount} {authoredCount === 1 ? 'pulse' : 'pulses'} · {echoedCount} {echoedCount === 1 ? 'echo' : 'echoes'}
          </div>
        </div>

        <div className="back-link" style={{ marginBottom: '20px', marginTop: '10px' }}>
          <Link to="/wire">← Back to the WIRE</Link>
        </div>

        <div className="user-timeline">
          {pulses.length === 0 ? (
            <div className="empty-state">
              <p>@{username} hasn't broadcast any pulses yet.</p>
            </div>
          ) : (
            pulses.map(pulse => (
              <div key={`${pulse.is_echo_on_profile ? 'echo-' : ''}${pulse.id}`}>
                {pulse.is_echo_on_profile && (
                  <div className="echo-indicator" style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                    fontSize: '0.9rem',
                    color: '#60a5fa',
                    padding: '8px 15px',
                    marginBottom: '-3px',
                    background: 'rgba(96, 165, 250, 0.1)',
                    borderLeft: '3px solid #60a5fa',
                    borderTop: '1px solid rgba(96, 165, 250, 0.3)',
                    borderRight: '1px solid rgba(96, 165, 250, 0.3)',
                    fontFamily: "'Courier New', Courier, monospace"
                  }}>
                    <span style={{ fontSize: '1.1rem' }}>↻</span>
                    <span>@{username} echoed</span>
                  </div>
                )}
                {pulse.is_splice && !pulse.is_echo_on_profile && (
                  <div
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      fontSize: '0.9rem',
                      color: '#a78bfa',
                      padding: '8px 15px',
                      marginBottom: '-3px',
                      background: 'rgba(167, 139, 250, 0.1)',
                      borderLeft: '3px solid #a78bfa',
                      borderTop: '1px solid rgba(167, 139, 250, 0.3)',
                      borderRight: '1px solid rgba(167, 139, 250, 0.3)',
                      fontFamily: "'Courier New', Courier, monospace"
                    }}
                  >
                    <span style={{ fontSize: '1.1rem' }}>↩</span>
                    <span>replying to <Link
                      to={`/wire/pulse/${pulse.thread_root_id || pulse.parent_pulse_id}`}
                      style={{ color: '#c4b5fd', textDecoration: 'underline' }}
                    >thread</Link></span>
                  </div>
                )}
                <PulseCard
                  pulse={pulse}
                  indentSplice={false}
                  onEchoToggle={handleEchoToggle}
                  onPulseCreated={handlePulseCreated}
                  onPulseDeleted={handlePulseDeleted}
                />
              </div>
            ))
          )}
        </div>

        <div className="back-link">
          <Link to="/wire">← Back to the WIRE</Link>
        </div>
      </div>
    </DefaultLayout>
  )
}
