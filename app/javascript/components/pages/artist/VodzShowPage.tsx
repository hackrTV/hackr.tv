import React, { useEffect, useState } from 'react'
import { Link, useParams, useLocation } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { YouTubePlayer } from '~/components/YouTubePlayer'
import { formatFutureDate } from '~/utils/dateUtils'

interface Vod {
  id: number
  title: string | null
  vod_url: string
  live_url: string | null
  started_at: string | null
  ended_at: string | null
  was_livestream: boolean
  artist: {
    id: number
    name: string
    slug: string
  }
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

const VodzShowPage: React.FC = () => {
  const { id } = useParams<{ id: string }>()
  const location = useLocation()
  const [vod, setVod] = useState<Vod | null>(null)
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
    const fetchVod = async () => {
      try {
        setLoading(true)
        const response = await fetch(`/api/artists/${artistSlug}/vods/${id}`)
        if (!response.ok) {
          if (response.status === 404) {
            throw new Error('Video not found')
          }
          throw new Error('Failed to fetch video')
        }
        const json = await response.json()
        setVod(json)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Unknown error')
      } finally {
        setLoading(false)
      }
    }

    if (id) {
      fetchVod()
    }
  }, [artistSlug, id])

  if (loading) {
    return (
      <DefaultLayout>
        <LoadingSpinner message="Loading video..." />
      </DefaultLayout>
    )
  }

  if (error || !vod) {
    return (
      <DefaultLayout>
        <div className="tui-window red-168-text" style={{ maxWidth: '800px', margin: '0 auto' }}>
          <fieldset>
            <legend>Error</legend>
            <p>{error || 'Failed to load video'}</p>
            <Link
              to={`/${artistSlug}/vidz`}
              className="tui-button"
              style={{ marginTop: '20px', display: 'inline-block' }}
            >
              Back to Videos
            </Link>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  const videoId = extractVideoId(vod.vod_url)

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
            {vod.artist.name} :: VIDZ
          </legend>
          <div style={{ padding: '30px' }}>
            {/* Back link */}
            <Link
              to={`/${artistSlug}/vidz`}
              style={{
                color: colorScheme.primary,
                textDecoration: 'none',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
                marginBottom: '20px'
              }}
            >
              &larr; Back to Videos
            </Link>

            {/* Video title and badge */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginBottom: '15px' }}>
              <h2 style={{ margin: 0, color: '#fff' }}>
                {vod.title || 'Untitled Stream'}
              </h2>
              {vod.was_livestream && (
                <span
                  style={{
                    background: '#dc2626',
                    color: '#fff',
                    padding: '3px 10px',
                    borderRadius: '3px',
                    fontSize: '0.75rem',
                    fontWeight: 'bold',
                    textTransform: 'uppercase',
                    letterSpacing: '1px'
                  }}
                >
                  Livestream
                </span>
              )}
            </div>

            {/* Date */}
            <p style={{ margin: '0 0 25px', color: '#888' }}>
              {vod.started_at ? formatFutureDate(vod.started_at) : 'Unknown date'}
            </p>

            {/* Video player */}
            {videoId ? (
              <div
                style={{
                  position: 'relative',
                  width: '100%',
                  paddingBottom: '56.25%', // 16:9 aspect ratio
                  background: '#000',
                  borderRadius: '4px',
                  overflow: 'hidden'
                }}
              >
                <div
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%'
                  }}
                >
                  <YouTubePlayer
                    videoId={videoId}
                    responsive
                  />
                </div>
              </div>
            ) : (
              <div
                style={{
                  padding: '60px',
                  background: '#111',
                  borderRadius: '4px',
                  textAlign: 'center',
                  color: '#888'
                }}
              >
                <p>Unable to load video player.</p>
                <a
                  href={vod.vod_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="tui-button"
                  style={{
                    marginTop: '15px',
                    display: 'inline-block',
                    background: colorScheme.primary,
                    color: '#fff'
                  }}
                >
                  Watch on YouTube
                </a>
              </div>
            )}
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default VodzShowPage
