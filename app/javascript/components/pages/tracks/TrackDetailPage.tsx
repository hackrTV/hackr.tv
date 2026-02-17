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
import { apiJson } from '~/utils/apiClient'
import { getArtistColors } from '~/utils/artistColors'

interface Release {
  id: number
  name: string
  slug: string
  release_type: string | null
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
  release: Release | null
  audio_url: string | null
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

  const getSectionStyle = (index: number): { color: string; glow: string } => {
    const color = getAccentColor(index)
    return {
      color,
      glow: hasPrismatic ? `${color}99` : colorScheme.glow
    }
  }

  useEffect(() => {
    if (!trackSlug) return

    apiJson<Track>(`/api/tracks/${trackSlug}`)
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
            ...outerBorderStyle
          }}
        >
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
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
            ...outerBorderStyle
          }}
        >
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
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

  const artistDisplayName = track.artist.name
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

  // Section index counter for cycling accent colors
  let sectionIndex = 0
  const headerSection = getSectionStyle(sectionIndex++)
  const transmissionSection = getSectionStyle(sectionIndex++)
  const hasStreaming = track.streaming_links && Object.keys(track.streaming_links).length > 0
  const streamingSection = hasStreaming ? getSectionStyle(sectionIndex++) : null
  const hasVideos = track.videos && Object.keys(track.videos).length > 0
  const videosSection = hasVideos ? getSectionStyle(sectionIndex++) : null
  const lyricsSection = track.lyrics ? getSectionStyle(sectionIndex++) : null

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
            {track.title.toUpperCase()}
          </legend>

          <div>
            {/* Track Header with Status */}
            <div
              style={{
                marginBottom: '30px',
                padding: '25px',
                background: hasPrismatic
                  ? `linear-gradient(135deg, ${headerSection.color}14, rgba(0, 0, 0, 0.95))`
                  : 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${headerSection.color}`,
                boxShadow: `0 0 20px ${headerSection.glow}, inset 0 0 15px ${headerSection.color}1a`
              }}
            >
              <div
                style={{
                  fontFamily: 'monospace',
                  marginBottom: '20px',
                  padding: '15px',
                  background: `${headerSection.color}1a`,
                  border: `1px solid ${headerSection.color}`,
                  color: headerSection.color,
                  textShadow: `0 0 8px ${headerSection.glow}`
                }}
              >
                [ARTIST: {track.artist.name}]<br />
                {track.release && <>[RELEASE: {track.release.name}]<br /></>}
                {track.release?.release_type && <>[TYPE: {track.release.release_type.toUpperCase()}]<br /></>}
                {track.release_date && <>[RELEASE: {track.release_date}]<br /></>}
                {track.duration && <>[DURATION: {track.duration}]<br /></>}
                [STATUS: TRANSMISSION ACTIVE]
              </div>

              {track.featured && (
                <div
                  style={{
                    textAlign: 'center',
                    padding: '10px',
                    background: headerSection.color,
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
                border: `2px solid ${transmissionSection.color}`,
                boxShadow: `0 0 25px ${transmissionSection.glow}33`
              }}
            >
              <fieldset style={{ borderColor: transmissionSection.color }}>
                <legend
                  style={{
                    color: transmissionSection.color,
                    textShadow: `0 0 10px ${transmissionSection.glow}`,
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
            {hasStreaming && streamingSection && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${streamingSection.color}`,
                  boxShadow: `0 0 25px ${streamingSection.glow}33`
                }}
              >
                <fieldset style={{ borderColor: streamingSection.color }}>
                  <legend
                    style={{
                      color: streamingSection.color,
                      textShadow: `0 0 10px ${streamingSection.glow}`,
                      letterSpacing: '2px'
                    }}
                  >
                    STREAMING FREQUENCIES
                  </legend>
                  <div style={{ padding: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <Link
                      to={`/fm/pulse-vault?filter=${encodeURIComponent(track.title)}`}
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
                    {sortStreamingLinks(track.streaming_links!).map(([platform, url]) => (
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
            {hasVideos && videosSection && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${videosSection.color}`,
                  boxShadow: `0 0 25px ${videosSection.glow}33`
                }}
              >
                <fieldset style={{ borderColor: videosSection.color }}>
                  <legend
                    style={{
                      color: videosSection.color,
                      textShadow: `0 0 10px ${videosSection.glow}`,
                      letterSpacing: '2px'
                    }}
                  >
                    VISUAL TRANSMISSIONS
                  </legend>
                  <div style={{ padding: '20px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    {Object.entries(track.videos!).map(([type, url]) => (
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
                          boxShadow: `0 0 15px ${videosSection.glow}66`
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
            {track.lyrics && lyricsSection && (
              <div
                style={{
                  marginBottom: '30px',
                  background: '#000000',
                  border: `2px solid ${lyricsSection.color}`,
                  boxShadow: `0 0 25px ${lyricsSection.glow}33`
                }}
              >
                <fieldset style={{ borderColor: lyricsSection.color }}>
                  <legend
                    style={{
                      color: lyricsSection.color,
                      textShadow: `0 0 10px ${lyricsSection.glow}`,
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
                      background: `${lyricsSection.color}08`
                    }}
                  >
                    <ReactMarkdown
                      remarkPlugins={[remarkGfm]}
                      rehypePlugins={[rehypeSanitize]}
                      components={{
                        a: ({ ...props }) => (
                          <a
                            style={{
                              color: lyricsSection.color,
                              textDecoration: 'underline',
                              textShadow: `0 0 8px ${lyricsSection.glow}`
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
                to={`/${artistSlug}`}
                style={{
                  padding: '10px 20px',
                  background: colorScheme.secondary,
                  color: 'white',
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px ${colorScheme.glow}66`
                }}
              >
                {artistDisplayName} HOME →
              </Link>
              {track.release && (
                <Link
                  to={`/${artistSlug}/releases/${track.release.slug}`}
                  style={{
                    padding: '10px 20px',
                    background: '#222',
                    color: '#aaa',
                    textDecoration: 'none',
                    border: '1px solid #444'
                  }}
                >
                  RELEASE: {track.release.name} →
                </Link>
              )}
              <Link
                to="/fm/pulse-vault"
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
