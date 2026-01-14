import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'

interface Album {
  id: number
  name: string
  slug: string
  release_date: string | null
  cover_url: string | null
  album_type?: string
}

interface Track {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  featured: boolean
  album: Album | null
  audio_url: string | null
  streaming_links?: Record<string, string>
}

interface Artist {
  id: number
  name: string
  slug: string
  genre: string
  tracks: Track[]
}

// Color schemes for different artists
const colorSchemes: Record<string, {
  primary: string
  secondary: string
  glow: string
  glowStrong: string
  background: string
}> = {
  xeraen: {
    primary: '#8B00FF',
    secondary: '#6B00CC',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)',
    background: '#0a0a0a'
  },
  thecyberpulse: {
    primary: '#8B00FF',
    secondary: '#9B59B6',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)',
    background: '#0a0a0a'
  }
}

const TrackListPage: React.FC = () => {
  const location = useLocation()
  const [artist, setArtist] = useState<Artist | null>(null)
  const [loading, setLoading] = useState(true)

  // Extract artist slug from pathname (e.g., /xeraen/trackz -> xeraen)
  const artistSlug = location.pathname.split('/')[1]
  const colorScheme = colorSchemes[artistSlug] || colorSchemes.xeraen

  useEffect(() => {
    if (!artistSlug) return

    apiJson<Artist>(`/api/artists/${artistSlug}`)
      .then(data => {
        setArtist(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching artist:', error)
        setLoading(false)
      })
  }, [artistSlug])

  if (loading) {
    return (
      <DefaultLayout>
        <div
          className="tui-window white-text"
          style={{
            maxWidth: '1200px',
            background: colorScheme.background,
            border: `2px solid ${colorScheme.primary}`,
            boxShadow: `0 0 30px ${colorScheme.glow}`
          }}
        >
          <fieldset style={{ borderColor: colorScheme.primary }}>
            <legend
              style={{
                color: colorScheme.primary,
                textShadow: `0 0 15px ${colorScheme.glowStrong}`,
                letterSpacing: '3px'
              }}
            >
              LOADING TRANSMISSIONS
            </legend>
            <div style={{ padding: '40px' }}>
              <LoadingSpinner message="Decoding signal frequencies..." color="purple-168-text" size="large" />
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  if (!artist) {
    return (
      <DefaultLayout>
        <div
          className="tui-window white-text"
          style={{
            maxWidth: '1200px',
            background: colorScheme.background,
            border: `2px solid ${colorScheme.primary}`,
            boxShadow: `0 0 30px ${colorScheme.glow}`
          }}
        >
          <fieldset style={{ borderColor: colorScheme.primary }}>
            <legend
              style={{
                color: colorScheme.primary,
                textShadow: `0 0 15px ${colorScheme.glowStrong}`,
                letterSpacing: '3px'
              }}
            >
              SIGNAL LOST
            </legend>
            <div style={{ padding: '40px', textAlign: 'center' }}>
              <p style={{ color: '#ff5555' }}>Artist frequency not found. The signal may have been disrupted.</p>
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  const tracks = artist.tracks || []
  const artistDisplayName = artist.name === 'XERAEN' ? 'XERAEN' : 'THE.CYBERPUL.SE'

  const platformOrder = ['bandcamp', 'youtube', 'spotify', 'apple_music', 'soundcloud']

  const formatPlatformName = (platform: string) => {
    if (platform.toLowerCase() === 'youtube') {
      return 'YouTube'
    }
    return platform.replace('_', ' ').split(' ').map(word =>
      word.charAt(0).toUpperCase() + word.slice(1)
    ).join(' ')
  }

  const sortStreamingLinks = (links: Record<string, string>) => {
    return Object.entries(links).sort((a, b) => {
      const indexA = platformOrder.indexOf(a[0].toLowerCase())
      const indexB = platformOrder.indexOf(b[0].toLowerCase())
      if (indexA !== -1 && indexB !== -1) return indexA - indexB
      if (indexA !== -1) return -1
      if (indexB !== -1) return 1
      return 0
    })
  }

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
          background: colorScheme.background,
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
            {artistDisplayName} :: TRACKZ
          </legend>

          <div>
            {/* Status Header */}
            <div
              style={{
                marginBottom: '30px',
                padding: '20px',
                background: 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 20px ${colorScheme.glow}, inset 0 0 15px rgba(139, 0, 255, 0.1)`
              }}
            >
              <div
                style={{
                  fontFamily: 'monospace',
                  marginBottom: '15px',
                  padding: '15px',
                  background: 'rgba(139, 0, 255, 0.1)',
                  border: `1px solid ${colorScheme.primary}`,
                  color: colorScheme.primary,
                  textShadow: `0 0 8px ${colorScheme.glow}`
                }}
              >
                [SIGNAL: ACTIVE]<br />
                [TRACKS: {tracks.length}]<br />
                [STATUS: TRANSMITTING]
              </div>
              <p style={{ color: '#ccc', textAlign: 'center' }}>
                Browse all available transmissions from {artistDisplayName}. Click any track to access full details.
              </p>
            </div>

            {/* Track List */}
            {tracks.length === 0 ? (
              <div
                style={{
                  padding: '30px',
                  textAlign: 'center',
                  background: 'rgba(139, 0, 255, 0.05)',
                  border: '1px solid rgba(139, 0, 255, 0.3)'
                }}
              >
                <p style={{ color: '#aaa' }}>No transmissions available yet. Signal frequency is being calibrated...</p>
              </div>
            ) : (
              tracks.map((track, index) => (
                <div
                  key={track.id}
                  style={{
                    marginBottom: '20px',
                    padding: '20px',
                    background: '#000000',
                    border: `1px solid ${colorScheme.primary}`,
                    boxShadow: '0 0 15px rgba(139, 0, 255, 0.15)',
                    transition: 'box-shadow 0.2s ease'
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.boxShadow = `0 0 25px ${colorScheme.glow}`
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.boxShadow = '0 0 15px rgba(139, 0, 255, 0.15)'
                  }}
                >
                  {/* Track Number & Title */}
                  <div style={{ display: 'flex', alignItems: 'flex-start', gap: '15px' }}>
                    <span
                      style={{
                        fontFamily: 'monospace',
                        color: colorScheme.primary,
                        textShadow: `0 0 8px ${colorScheme.glow}`,
                        fontSize: '1.2em',
                        minWidth: '40px'
                      }}
                    >
                      [{String(index + 1).padStart(2, '0')}]
                    </span>
                    <div style={{ flex: 1 }}>
                      <Link
                        to={`/${artistSlug}/trackz/${track.slug}`}
                        style={{
                          color: colorScheme.primary,
                          textDecoration: 'underline',
                          textUnderlineOffset: '4px',
                          fontSize: '1.3em',
                          fontWeight: 'bold',
                          letterSpacing: '1px',
                          textShadow: `0 0 10px ${colorScheme.glow}`,
                          display: 'inline-block',
                          marginBottom: '8px'
                        }}
                      >
                        {track.title}
                        {track.featured && (
                          <span
                            style={{
                              marginLeft: '10px',
                              padding: '2px 8px',
                              background: colorScheme.primary,
                              color: '#000',
                              fontSize: '0.7em',
                              fontWeight: 'bold',
                              letterSpacing: '1px'
                            }}
                          >
                            FEATURED
                          </span>
                        )}
                      </Link>

                      {/* Track Metadata */}
                      <p style={{ color: '#888', marginBottom: '12px', fontSize: '0.95em' }}>
                        {track.album?.name && (
                          <span style={{ color: '#aaa' }}>{track.album.name}</span>
                        )}
                        {track.album?.album_type && (
                          <span style={{ color: '#666' }}> ({track.album.album_type.toUpperCase()})</span>
                        )}
                        {track.album?.release_date && (
                          <span style={{ color: '#666' }}> • {track.album.release_date}</span>
                        )}
                        {track.duration && (
                          <span style={{ color: '#666' }}> • {track.duration}</span>
                        )}
                      </p>

                      {/* Action Buttons */}
                      <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                        <Link
                          to={`/fm/pulse_vault?filter=${encodeURIComponent(track.title)}`}
                          style={{
                            padding: '6px 12px',
                            background: colorScheme.primary,
                            color: '#fff',
                            textDecoration: 'none',
                            fontSize: '0.85em',
                            fontWeight: 'bold',
                            boxShadow: `0 0 10px ${colorScheme.glow}`
                          }}
                        >
                          ▶ PULSE VAULT
                        </Link>
                        {track.streaming_links && Object.keys(track.streaming_links).length > 0 && (
                          sortStreamingLinks(track.streaming_links).map(([platform, url]) => (
                            <a
                              key={platform}
                              href={url}
                              target="_blank"
                              rel="noopener noreferrer"
                              style={{
                                padding: '6px 12px',
                                background: '#222',
                                color: '#aaa',
                                textDecoration: 'none',
                                fontSize: '0.85em',
                                border: '1px solid #444'
                              }}
                            >
                              → {formatPlatformName(platform)}
                            </a>
                          ))
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}

            {/* Navigation Buttons */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to={artistSlug === 'xeraen' ? '/xeraen' : '/thecyberpulse'}
                style={{
                  padding: '10px 20px',
                  background: '#222',
                  color: '#888',
                  textDecoration: 'none',
                  border: '1px solid #444'
                }}
              >
                ← BACK TO {artistDisplayName}
              </Link>
              <Link
                to="/fm/pulse_vault"
                style={{
                  padding: '10px 20px',
                  background: colorScheme.primary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px ${colorScheme.glow}`
                }}
              >
                ALL TRACKS IN PULSE VAULT →
              </Link>
              <Link
                to="/fm/bands"
                style={{
                  padding: '10px 20px',
                  background: colorScheme.secondary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: '0 0 15px rgba(107, 0, 204, 0.6)'
                }}
              >
                ALL BANDS →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackListPage
