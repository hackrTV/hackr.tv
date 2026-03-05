import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { apiJson } from '~/utils/apiClient'
import { getArtistColors } from '~/utils/artistColors'

interface Release {
  id: number
  name: string
  slug: string
  release_date: string | null
  cover_url: string | null
  release_type?: string
}

interface Track {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  featured: boolean
  release: Release | null
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

const TrackListPage: React.FC = () => {
  const location = useLocation()
  const [artist, setArtist] = useState<Artist | null>(null)
  const [loading, setLoading] = useState(true)

  // Extract artist slug from pathname (e.g., /xeraen/trackz -> xeraen)
  const artistSlug = location.pathname.split('/')[1]
  const colorScheme = getArtistColors(artistSlug)
  const hasPrismatic = !!colorScheme.gradient

  const outerBorderStyle: React.CSSProperties = hasPrismatic
    ? {
      border: '3px solid transparent',
      backgroundImage: `linear-gradient(${colorScheme.background}, ${colorScheme.background}), ${colorScheme.gradient}`,
      backgroundOrigin: 'border-box',
      backgroundClip: 'padding-box, border-box',
      boxShadow: '0 0 30px rgba(255, 0, 128, 0.3)'
    }
    : {
      border: `2px solid ${colorScheme.primary}`,
      boxShadow: `0 0 30px ${colorScheme.glow}`
    }

  const legendStyle: React.CSSProperties = hasPrismatic
    ? {
      background: colorScheme.gradient,
      WebkitBackgroundClip: 'text',
      WebkitTextFillColor: 'transparent',
      backgroundClip: 'text',
      letterSpacing: '3px',
      fontWeight: 'bold'
    }
    : {
      color: colorScheme.primary,
      textShadow: `0 0 15px ${colorScheme.glowStrong}`,
      letterSpacing: '3px'
    }

  const getAccentColor = (index: number): string => {
    if (hasPrismatic && colorScheme.accentColors) {
      return colorScheme.accentColors[index % colorScheme.accentColors.length]
    }
    return colorScheme.primary
  }

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
            ...outerBorderStyle
          }}
        >
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
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
            ...outerBorderStyle
          }}
        >
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
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
  const artistDisplayName = artist.name

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

  // Header section gets first accent color
  const headerColor = getAccentColor(0)
  const headerGlow = hasPrismatic ? `${headerColor}99` : colorScheme.glow

  return (
    <DefaultLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
          background: colorScheme.background,
          ...outerBorderStyle
        }}
      >
        <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
          <legend
            className="center"
            style={legendStyle}
          >
            {artistDisplayName} :: TRACKZ
          </legend>

          <div>
            {/* Status Header */}
            <div
              style={{
                marginBottom: '30px',
                padding: '20px',
                background: hasPrismatic
                  ? `linear-gradient(135deg, ${headerColor}14, rgba(0, 0, 0, 0.95))`
                  : 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${headerColor}`,
                boxShadow: `0 0 20px ${headerGlow}, inset 0 0 15px ${headerColor}1a`
              }}
            >
              <div
                style={{
                  fontFamily: 'monospace',
                  marginBottom: '15px',
                  padding: '15px',
                  background: `${headerColor}1a`,
                  border: `1px solid ${headerColor}`,
                  color: headerColor,
                  textShadow: `0 0 8px ${headerGlow}`
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
              tracks.map((track, index) => {
                const trackColor = getAccentColor(index)
                const trackGlow = hasPrismatic ? `${trackColor}99` : colorScheme.glow

                return (
                  <div
                    key={track.id}
                    style={{
                      marginBottom: '20px',
                      padding: '20px',
                      background: '#000000',
                      border: `1px solid ${trackColor}`,
                      borderLeft: hasPrismatic ? `3px solid ${trackColor}` : `1px solid ${trackColor}`,
                      boxShadow: `0 0 15px ${trackColor}26`,
                      transition: 'box-shadow 0.2s ease'
                    }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.boxShadow = `0 0 25px ${trackGlow}`
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.boxShadow = `0 0 15px ${trackColor}26`
                    }}
                  >
                    {/* Track Number & Title */}
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '15px' }}>
                      <span
                        style={{
                          fontFamily: 'monospace',
                          color: trackColor,
                          textShadow: `0 0 8px ${trackGlow}`,
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
                            color: trackColor,
                            textDecoration: 'underline',
                            textUnderlineOffset: '4px',
                            fontSize: '1.3em',
                            fontWeight: 'bold',
                            letterSpacing: '1px',
                            textShadow: `0 0 10px ${trackGlow}`,
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
                                background: trackColor,
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
                          {track.release?.name && (
                            <span style={{ color: '#aaa' }}>{track.release.name}</span>
                          )}
                          {track.release?.release_type && (
                            <span style={{ color: '#666' }}> ({track.release.release_type.toUpperCase()})</span>
                          )}
                          {track.release?.release_date && (
                            <span style={{ color: '#666' }}> • {track.release.release_date}</span>
                          )}
                          {track.duration && (
                            <span style={{ color: '#666' }}> • {track.duration}</span>
                          )}
                        </p>

                        {/* Action Buttons */}
                        <div style={{ display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                          <Link
                            to={`/vault?filter=${encodeURIComponent(track.title)}`}
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
                )
              })
            )}

            {/* Navigation Buttons */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to={`/${artistSlug}`}
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
                to={`/${artistSlug}/releases`}
                style={{
                  padding: '10px 20px',
                  background: colorScheme.secondary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px ${colorScheme.glow}66`
                }}
              >
                RELEASES →
              </Link>
              <Link
                to="/vault"
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
                to="/f/net"
                style={{
                  padding: '10px 20px',
                  background: colorScheme.secondary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px ${colorScheme.glow}66`
                }}
              >
                FRACTURE NETWORK →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackListPage
