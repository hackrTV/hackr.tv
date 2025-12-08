import React, { useEffect, useState } from 'react'
import { Link, useLocation } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { formatFutureDate } from '~/utils/dateUtils'

interface Vod {
  id: number
  title: string | null
  vod_url: string
  live_url: string | null
  started_at: string | null
  ended_at: string | null
  was_livestream: boolean
}

interface Artist {
  id: number
  name: string
  slug: string
}

interface VodsResponse {
  artist: Artist
  vods: Vod[]
}

const extractVideoId = (url: string): string | null => {
  const patterns = [
    /youtube\.com\/embed\/([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
    /youtu\.be\/([a-zA-Z0-9_-]{11})/,
    /youtube\.com\/live\/([a-zA-Z0-9_-]{11})/
  ]

  for (const pattern of patterns) {
    const match = url.match(pattern)
    if (match) return match[1]
  }
  return null
}

const VodzPage: React.FC = () => {
  const location = useLocation()
  const [data, setData] = useState<VodsResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Determine artist slug from URL path
  const pathParts = location.pathname.split('/')
  const artistSlug = pathParts[1] // 'xeraen' or 'thecyberpulse'

  const colorScheme = {
    primary: '#8B00FF',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)'
  }

  useEffect(() => {
    const fetchVods = async () => {
      try {
        setLoading(true)
        const response = await fetch(`/api/artists/${artistSlug}/vods`)
        if (!response.ok) {
          throw new Error('Failed to fetch VODs')
        }
        const json = await response.json()
        setData(json)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    fetchVods()
  }, [artistSlug])

  if (loading) {
    return (
      <DefaultLayout>
        <LoadingSpinner message="Loading VODs..." />
      </DefaultLayout>
    )
  }

  if (error || !data) {
    return (
      <DefaultLayout>
        <div className="tui-window red-168-text" style={{ maxWidth: '800px', margin: '0 auto' }}>
          <fieldset>
            <legend>Error</legend>
            <p>{error || 'Failed to load VODs'}</p>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
          background: '#0a0a0a',
          border: `2px solid ${colorScheme.primary}`,
          boxShadow: `0 0 30px ${colorScheme.glow}`
        }}
      >
        <fieldset style={{ borderColor: colorScheme.primary }}>
          <legend
            className="center"
            style={{
              color: colorScheme.primary,
              textShadow: `0 0 15px ${colorScheme.glowStrong}`,
              letterSpacing: '3px'
            }}
          >
            {data.artist.name} :: VIDZ
          </legend>
          <div style={{ padding: '30px' }}>
            {data.vods.length === 0 ? (
              <p style={{ textAlign: 'center', color: '#888' }}>
                No videos available yet.
              </p>
            ) : (
              <div style={{ display: 'grid', gap: '20px' }}>
                {data.vods.map((vod) => {
                  const videoId = extractVideoId(vod.vod_url)
                  const thumbnailUrl = videoId
                    ? `https://img.youtube.com/vi/${videoId}/mqdefault.jpg`
                    : null

                  return (
                    <Link
                      key={vod.id}
                      to={`/${artistSlug}/vidz/${vod.id}`}
                      style={{
                        display: 'flex',
                        gap: '20px',
                        padding: '15px',
                        background: '#111',
                        border: '1px solid #333',
                        borderRadius: '4px',
                        textDecoration: 'none',
                        color: 'inherit',
                        transition: 'all 0.2s ease'
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.borderColor = colorScheme.primary
                        e.currentTarget.style.boxShadow = `0 0 15px ${colorScheme.glow}`
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.borderColor = '#333'
                        e.currentTarget.style.boxShadow = 'none'
                      }}
                    >
                      {thumbnailUrl && (
                        <div
                          style={{
                            width: '200px',
                            height: '112px',
                            flexShrink: 0,
                            backgroundImage: `url(${thumbnailUrl})`,
                            backgroundSize: 'cover',
                            backgroundPosition: 'center',
                            borderRadius: '2px',
                            position: 'relative'
                          }}
                        >
                          <div
                            style={{
                              position: 'absolute',
                              top: '50%',
                              left: '50%',
                              transform: 'translate(-50%, -50%)',
                              width: '40px',
                              height: '40px',
                              background: 'rgba(0, 0, 0, 0.7)',
                              borderRadius: '50%',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}
                          >
                            <div
                              style={{
                                width: 0,
                                height: 0,
                                borderLeft: '14px solid #fff',
                                borderTop: '8px solid transparent',
                                borderBottom: '8px solid transparent',
                                marginLeft: '3px'
                              }}
                            />
                          </div>
                        </div>
                      )}
                      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <h3 style={{ margin: 0, color: '#fff', fontSize: '1.1rem' }}>
                            {vod.title || 'Untitled Stream'}
                          </h3>
                          {vod.was_livestream && (
                            <span
                              style={{
                                background: '#dc2626',
                                color: '#fff',
                                padding: '2px 8px',
                                borderRadius: '3px',
                                fontSize: '0.7rem',
                                fontWeight: 'bold',
                                textTransform: 'uppercase',
                                letterSpacing: '1px'
                              }}
                            >
                              Livestream
                            </span>
                          )}
                        </div>
                        <p style={{ margin: 0, color: '#888', fontSize: '0.9rem' }}>
                          {vod.started_at ? formatFutureDate(vod.started_at) : 'Unknown date'}
                        </p>
                      </div>
                    </Link>
                  )
                })}
              </div>
            )}
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default VodzPage
