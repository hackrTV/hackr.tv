import React, { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import type { Pulse } from '../../types/pulse'
import { ThreadView } from './ThreadView'
import { apiJson } from '~/utils/apiClient'

export const SinglePulsePage: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const [pulse, setPulse] = useState<Pulse | null>(null)
  const [thread, setThread] = useState<Pulse[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchPulseAndThread = async () => {
      try {
        setIsLoading(true)
        const data = await apiJson<{ pulse: Pulse; thread: Pulse[] }>(`/api/pulses/${id}`)
        setPulse(data.pulse)
        setThread(data.thread)
        setIsLoading(false)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load pulse')
        setIsLoading(false)
      }
    }

    if (id) {
      fetchPulseAndThread()
    }
  }, [id])

  const handleEchoToggle = (pulseId: number, newEchoCount: number, isEchoed: boolean) => {
    setThread(prev => prev.map(p =>
      p.id === pulseId
        ? { ...p, echo_count: newEchoCount, is_echoed_by_current_hackr: isEchoed }
        : p
    ))

    if (pulse && pulse.id === pulseId) {
      setPulse({ ...pulse, echo_count: newEchoCount, is_echoed_by_current_hackr: isEchoed })
    }
  }

  const handlePulseCreated = (newPulse: Pulse) => {
    setThread(prev => [...prev, newPulse])
  }

  const handlePulseDeleted = (pulseId: number) => {
    setThread(prev => prev.filter(p => p.id !== pulseId))
  }

  if (isLoading) {
    return (
      <DefaultLayout>
        <div className="white-168-text" style={{ textAlign: 'center', padding: '40px' }}>
          Loading thread...
        </div>
      </DefaultLayout>
    )
  }

  if (error || !pulse) {
    return (
      <DefaultLayout>
        <div className="red-255-text" style={{ padding: '20px', border: '1px solid #ff0000', marginBottom: '20px' }}>
          {error || 'Pulse not found'}
        </div>
        <Link to="/wire" className="btn btn-primary">Back to Hotwire</Link>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout showAsciiArt={false}>
      <div className="single-pulse-page white-168-text" style={{ maxWidth: '800px', margin: '0 auto', paddingTop: '30px' }}>
        <ThreadView
          thread={thread}
          rootPulse={pulse}
          onEchoToggle={handleEchoToggle}
          onPulseCreated={handlePulseCreated}
          onPulseDeleted={handlePulseDeleted}
        />

        <div className="back-link">
          <Link to="/wire">← Back to the WIRE</Link>
        </div>
      </div>
    </DefaultLayout>
  )
}
