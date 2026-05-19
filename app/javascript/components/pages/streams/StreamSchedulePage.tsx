import React, { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { apiJson } from '~/utils/apiClient'
import { formatFutureDate } from '~/utils/dateUtils'

interface ScheduleArtist {
  id: number
  name: string
  slug: string
}

interface ScheduleStream {
  id: number
  title: string | null
  artist: ScheduleArtist
  scheduled_at: string | null
  started_at: string | null
  ended_at: string | null
  vod_url: string | null
  display_state: string
}

interface ScheduleResponse {
  upcoming: ScheduleStream[]
  past: ScheduleStream[]
}

const STATE_BADGES: Record<string, { label: string; color: string }> = {
  upcoming: { label: 'UPCOMING', color: '#06b6d4' },
  starting_soon: { label: 'STARTING SOON', color: '#f59e0b' },
  live: { label: 'LIVE', color: '#00ff00' },
  ended: { label: 'ENDED', color: '#666' },
  cancelled: { label: 'CANCELLED', color: '#ff4444' },
  expired: { label: 'EXPIRED', color: '#888' },
  unscheduled: { label: 'ON-DEMAND', color: '#888' }
}

const formatDate = (iso: string | null): string => {
  if (!iso) return '—'
  return formatFutureDate(iso, true)
}

const formatDuration = (start: string | null, end: string | null): string => {
  if (!start || !end) return '—'
  const diffMs = new Date(end).getTime() - new Date(start).getTime()
  const minutes = Math.floor(diffMs / 60000)
  if (minutes < 60) return `${minutes}m`
  const hours = Math.floor(minutes / 60)
  const remainingMins = minutes % 60
  return `${hours}h ${remainingMins}m`
}

export const StreamSchedulePage: React.FC = () => {
  const [data, setData] = useState<ScheduleResponse | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchSchedule = async () => {
      try {
        const result = await apiJson<ScheduleResponse>('/api/streams/schedule')
        setData(result)
      } catch (error) {
        console.error('Failed to fetch stream schedule:', error)
      } finally {
        setLoading(false)
      }
    }
    fetchSchedule()
  }, [])

  if (loading) {
    return (
      <DefaultLayout>
        <div style={{ textAlign: 'center', padding: '60px 0', color: '#888' }}>
          Loading schedule...
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      <div style={{ maxWidth: '1000px', margin: '0 auto', padding: '0 20px' }}>
        <h1 style={{
          color: '#06b6d4',
          fontSize: '1.4em',
          fontWeight: 'bold',
          marginBottom: '8px',
          letterSpacing: '0.1em'
        }}>
          STREAM SCHEDULE
        </h1>
        <p style={{ color: '#666', marginBottom: '30px', fontSize: '0.9em' }}>
          Upcoming livestreams and past broadcasts
        </p>

        {/* Upcoming Streams */}
        <h2 style={{
          color: '#06b6d4',
          fontSize: '1.1em',
          borderBottom: '1px solid #06b6d4',
          paddingBottom: '6px',
          marginBottom: '16px'
        }}>
          [:: UPCOMING ::]
        </h2>

        {data && data.upcoming.length > 0 ? (
          <div style={{ marginBottom: '40px' }}>
            {data.upcoming.map(stream => {
              const badge = STATE_BADGES[stream.display_state] || STATE_BADGES.upcoming
              return (
                <div key={stream.id} style={{
                  background: '#0a0a0a',
                  border: '1px solid #1a1a1a',
                  borderLeft: `3px solid ${badge.color}`,
                  padding: '14px 18px',
                  marginBottom: '8px'
                }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
                    <div>
                      <span style={{ color: badge.color, fontWeight: 'bold', fontSize: '0.8em', marginRight: '10px' }}>
                        [{badge.label}]
                      </span>
                      <span style={{ color: '#e0f2fe', fontWeight: 'bold' }}>
                        {stream.title || 'Untitled Stream'}
                      </span>
                      <span style={{ color: '#888', margin: '0 8px' }}>—</span>
                      <span style={{ color: '#aaa' }}>{stream.artist.name}</span>
                    </div>
                    <div style={{ color: '#67e8f9', fontSize: '0.9em' }}>
                      {formatDate(stream.scheduled_at)}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>
        ) : (
          <p style={{ color: '#444', padding: '20px 0', marginBottom: '40px' }}>
            No upcoming streams scheduled.
          </p>
        )}

        {/* Past Broadcasts */}
        <h2 style={{
          color: '#888',
          fontSize: '1.1em',
          borderBottom: '1px solid #333',
          paddingBottom: '6px',
          marginBottom: '16px'
        }}>
          [:: PAST BROADCASTS ::]
        </h2>

        {data && data.past.length > 0 ? (
          <div style={{ marginBottom: '40px' }}>
            {data.past.map(stream => (
              <div key={stream.id} style={{
                background: '#0a0a0a',
                border: '1px solid #1a1a1a',
                borderLeft: '3px solid #333',
                padding: '14px 18px',
                marginBottom: '8px'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '8px' }}>
                  <div>
                    <span style={{ color: '#aaa', fontWeight: 'bold' }}>
                      {stream.title || 'Untitled Stream'}
                    </span>
                    <span style={{ color: '#666', margin: '0 8px' }}>—</span>
                    <span style={{ color: '#777' }}>{stream.artist.name}</span>
                  </div>
                  <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                    <span style={{ color: '#666', fontSize: '0.85em' }}>
                      {formatDate(stream.started_at)}
                    </span>
                    {stream.started_at && stream.ended_at && (
                      <span style={{ color: '#555', fontSize: '0.85em' }}>
                        ({formatDuration(stream.started_at, stream.ended_at)})
                      </span>
                    )}
                    {stream.vod_url && (
                      <Link
                        to={`/${stream.artist.slug}/vidz/${stream.id}`}
                        style={{ color: '#7c3aed', fontSize: '0.85em', textDecoration: 'none' }}
                      >
                        [VOD]
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p style={{ color: '#444', padding: '20px 0' }}>
            No past broadcasts yet.
          </p>
        )}
      </div>
    </DefaultLayout>
  )
}
