import React, { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import type { Pulse } from '../../types/pulse'
import { PulseCard } from './PulseCard'

export const UserPulsesPage: React.FC = () => {
  const { username } = useParams<{ username: string }>()
  const [pulses, setPulses] = useState<Pulse[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchUserPulses = async () => {
      try {
        setIsLoading(true)
        const response = await fetch(`/api/pulses?hackr=${username}&filter=active&per_page=100`, {
          credentials: 'include'
        })

        if (!response.ok) {
          throw new Error('Failed to load pulses')
        }

        const data = await response.json()
        setPulses(data.pulses)
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
    setPulses(prev => [newPulse, ...prev])
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
          {pulses.length} {pulses.length === 1 ? 'pulse' : 'pulses'}
        </div>
      </div>

      <div className="back-link" style={{ marginBottom: '20px', marginTop: '10px' }}>
        <Link to="/wire">← Back to the Wire</Link>
      </div>

      <div className="user-timeline">
        {pulses.length === 0 ? (
          <div className="empty-state">
            <p>@{username} hasn't broadcast any pulses yet.</p>
          </div>
        ) : (
          pulses.map(pulse => (
            <PulseCard
              key={pulse.id}
              pulse={pulse}
              onEchoToggle={handleEchoToggle}
              onPulseCreated={handlePulseCreated}
              onPulseDeleted={handlePulseDeleted}
            />
          ))
        )}
      </div>

      <div className="back-link">
        <Link to="/wire">← Back to the Wire</Link>
      </div>
      </div>
    </DefaultLayout>
  )
}
