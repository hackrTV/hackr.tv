import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import rehypeSanitize from 'rehype-sanitize'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { EmbeddedTrack } from '~/components/EmbeddedTrack'
import { transformMarkdownLinks } from '~/utils/codexLinks'
import { useCodexMappings } from '~/hooks/useCodexMappings'

interface Album {
  id: number
  name: string
  slug: string
  album_type: string | null
  release_date: string | null
  description: string | null
  cover_url: string | null
}

interface Artist {
  id: number
  name: string
  slug: string
  genre: string
}

interface Track {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  featured: boolean
  release_date: string | null
  lyrics: string | null
  streaming_links: Record<string, string> | null
  videos: Record<string, string> | null
  artist: Artist
  album: Album | null
  audio_url: string | null
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

const TrackDetailPage: React.FC = () => {
  const location = useLocation()
  const [track, setTrack] = useState<Track | null>(null)
  const [loading, setLoading] = useState(true)
  const { mappings } = useCodexMappings()

  // Extract artist slug and track slug from pathname
  const pathParts = location.pathname.split('/')
  const artistSlug = pathParts[1]
  const trackSlug = pathParts[3]
  const colorScheme = colorSchemes[artistSlug] || colorSchemes.xeraen

  useEffect(() => {
    if (!trackSlug) return

    fetch(`/api/tracks/${trackSlug}`)
      .then(res => res.json())
      .then(data => {
        setTrack(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching track:', error)
        setLoading(false)
      })
  }, [trackSlug])

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
              DECODING TRANSMISSION
            </legend>
            <div style={{ padding: '40px' }}>
              <LoadingSpinner message="Intercepting signal data..." color="purple-168-text" size="large" />
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  if (!track) {
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
              <p style={{ color: '#ff5555' }}>Track frequency not found. The transmission may have been intercepted.</p>
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  const artistDisplayName = track.artist.name === 'XERAEN' ? 'XERAEN' : 'THE.CYBERPUL.SE'
  const platformOrder = ['bandcamp', 'youtube', 'spotify', 'apple_music', 'soundcloud']

  const titleize = (str: string) => {
    if (str.toLowerCase() === 'youtube') {
      return 'YouTube'
    }
    return str.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
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
            {track.title.toUpperCase()}
          </legend>

          <div>
            {/* Track Header with Status */}
            <div
              style={{
                marginBottom: '30px',
                padding: '25px',
                background: 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 20px ${colorScheme.glow}, inset 0 0 15px rgba(139, 0, 255, 0.1)`
              }}
            >
              <div
                style={{
                  fontFamily: 'monospace',
                  marginBottom: '20px',
                  padding: '15px',
                  background: 'rgba(139, 0, 255, 0.1)',
                  border: `1px solid ${colorScheme.primary}`,
                  color: colorScheme.primary,
                  textShadow: `0 0 8px ${colorScheme.glow}`
                }}
              >
                [ARTIST: {track.artist.name}]<br />
                {track.album && <>[ALBUM: {track.album.name}]<br /></>}
                {track.album?.album_type && <>[TYPE: {track.album.album_type.toUpperCase()}]<br /></>}
                {track.release_date && <>[RELEASE: {track.release_date}]<br /></>}
                {track.duration && <>[DURATION: {track.duration}]<br /></>}
                [STATUS: TRANSMISSION ACTIVE]
              </div>

              {track.featured && (
                <div
                  style={{
                    textAlign: 'center',
                    padding: '10px',
                    background: colorScheme.primary,
                    color: '#000',
                    fontWeight: 'bold',
                    letterSpacing: '2px',
                    marginBottom: '15px'
                  }}
                >
                  ★ FEATURED TRANSMISSION ★
                </div>
              )}
            </div>

            {/* Embedded Player */}
            <div
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  TRANSMISSION
                </legend>
                <div style={{ padding: '20px' }}>
                  <EmbeddedTrack trackId={track.slug} />
                </div>
              </fieldset>
            </div>

            {/* Streaming Links */}
            {track.streaming_links && Object.keys(track.streaming_links).length > 0 && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${colorScheme.primary}`,
                  boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
                }}
              >
                <fieldset style={{ borderColor: colorScheme.primary }}>
                  <legend
                    style={{
                      color: colorScheme.primary,
                      textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                      letterSpacing: '2px'
                    }}
                  >
                    STREAMING FREQUENCIES
                  </legend>
                  <div style={{ padding: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <Link
                      to={`/fm/pulse_vault?filter=${encodeURIComponent(track.title)}`}
                      style={{
                        padding: '10px 20px',
                        background: colorScheme.primary,
                        color: '#fff',
                        textDecoration: 'none',
                        fontWeight: 'bold',
                        boxShadow: `0 0 15px ${colorScheme.glow}`
                      }}
                    >
                      ▶ PULSE VAULT
                    </Link>
                    {sortStreamingLinks(track.streaming_links).map(([platform, url]) => (
                      <a
                        key={platform}
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          padding: '10px 20px',
                          background: '#222',
                          color: '#aaa',
                          textDecoration: 'none',
                          border: '1px solid #444'
                        }}
                      >
                        → {titleize(platform)}
                      </a>
                    ))}
                  </div>
                </fieldset>
              </div>
            )}

            {/* Videos */}
            {track.videos && Object.keys(track.videos).length > 0 && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${colorScheme.primary}`,
                  boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
                }}
              >
                <fieldset style={{ borderColor: colorScheme.primary }}>
                  <legend
                    style={{
                      color: colorScheme.primary,
                      textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                      letterSpacing: '2px'
                    }}
                  >
                    VISUAL TRANSMISSIONS
                  </legend>
                  <div style={{ padding: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    {Object.entries(track.videos).map(([type, url]) => (
                      <a
                        key={type}
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          padding: '10px 20px',
                          background: colorScheme.secondary,
                          color: '#fff',
                          textDecoration: 'none',
                          fontWeight: 'bold',
                          boxShadow: '0 0 15px rgba(107, 0, 204, 0.6)'
                        }}
                      >
                        ▶ {titleize(type)} Video
                      </a>
                    ))}
                  </div>
                </fieldset>
              </div>
            )}

            {/* Lyrics */}
            {track.lyrics && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${colorScheme.primary}`,
                  boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
                }}
              >
                <fieldset style={{ borderColor: colorScheme.primary }}>
                  <legend
                    style={{
                      color: colorScheme.primary,
                      textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                      letterSpacing: '2px'
                    }}
                  >
                    DECODED LYRICS
                  </legend>
                  <div
                    style={{
                      padding: '25px',
                      whiteSpace: 'pre-wrap',
                      fontFamily: 'monospace',
                      lineHeight: '1.8',
                      color: '#ddd',
                      background: 'rgba(139, 0, 255, 0.03)'
                    }}
                  >
                    <ReactMarkdown
                      remarkPlugins={[remarkGfm]}
                      rehypePlugins={[rehypeSanitize]}
                      components={{
                        a: ({ ...props }) => (
                          <a
                            style={{
                              color: colorScheme.primary,
                              textDecoration: 'underline',
                              textShadow: `0 0 8px ${colorScheme.glow}`
                            }}
                            {...props}
                          />
                        ),
                        p: ({ ...props }) => (
                          <p style={{ marginBottom: '15px' }} {...props} />
                        )
                      }}
                    >
                      {transformMarkdownLinks(track.lyrics, mappings)}
                    </ReactMarkdown>
                  </div>
                </fieldset>
              </div>
            )}

            {/* Navigation Buttons */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to={`/${artistSlug}/trackz`}
                style={{
                  padding: '10px 20px',
                  background: '#222',
                  color: '#888',
                  textDecoration: 'none',
                  border: '1px solid #444'
                }}
              >
                ← BACK TO {artistDisplayName} TRACKZ
              </Link>
              <Link
                to={artistSlug === 'xeraen' ? '/xeraen' : '/thecyberpulse'}
                style={{
                  padding: '10px 20px',
                  background: colorScheme.secondary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: '0 0 15px rgba(107, 0, 204, 0.6)'
                }}
              >
                {artistDisplayName} HOME →
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
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackDetailPage
