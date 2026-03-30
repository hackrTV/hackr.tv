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
  cover_urls?: { thumbnail: string; standard: string; full: string }
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
  vidz: { id: number; title: string; vod_url: string }[]
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
  const infoSection = getSectionStyle(sectionIndex++)
  const hasStreaming = track.streaming_links && Object.keys(track.streaming_links).length > 0
  const hasVidz = track.vidz && track.vidz.length > 0
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
            {/* Header: Player + Info side-by-side */}
            <div style={{ display: 'flex', gap: '25px', marginBottom: '25px', flexWrap: 'wrap' }}>
              {/* Left: Embedded Player */}
              <div style={{ flexShrink: 0 }}>
                <EmbeddedTrack trackId={track.slug} />
              </div>

              {/* Right: Track Info Table + Links */}
              <div style={{ flex: 1, minWidth: '280px' }}>
                <div
                  className="tui-window white-text"
                  style={{ display: 'block', background: '#000', border: `1px solid ${infoSection.color}` }}
                >
                  <fieldset style={{ borderColor: infoSection.color }}>
                    <legend
                      style={{
                        color: infoSection.color,
                        textShadow: `0 0 10px ${infoSection.glow}`,
                        letterSpacing: '2px'
                      }}
                    >
                      TRACK INFO
                    </legend>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                      <tbody>
                        <tr>
                          <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Title:</td>
                          <td style={{ padding: '6px 12px', color: '#ccc', fontWeight: 'bold' }}>{track.title}</td>
                        </tr>
                        <tr>
                          <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Artist:</td>
                          <td style={{ padding: '6px 12px' }}>
                            <Link
                              to={`/${artistSlug}`}
                              style={{
                                color: colorScheme.primary,
                                textDecoration: 'none',
                                textShadow: `0 0 8px ${colorScheme.glow}`
                              }}
                            >
                              {track.artist.name}
                            </Link>
                          </td>
                        </tr>
                        {track.release && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Release:</td>
                            <td style={{ padding: '6px 12px' }}>
                              <Link
                                to={`/${artistSlug}/releases/${track.release.slug}`}
                                style={{
                                  color: colorScheme.primary,
                                  textDecoration: 'none',
                                  textShadow: `0 0 8px ${colorScheme.glow}`
                                }}
                              >
                                {track.release.name}
                              </Link>
                            </td>
                          </tr>
                        )}
                        {track.release?.release_type && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Release Type:</td>
                            <td style={{ padding: '6px 12px', color: '#ccc' }}>{track.release.release_type.toUpperCase()}</td>
                          </tr>
                        )}
                        {track.release_date && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Release Date:</td>
                            <td style={{ padding: '6px 12px', color: '#ccc' }}>{track.release_date}</td>
                          </tr>
                        )}
                        {track.duration && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Duration:</td>
                            <td style={{ padding: '6px 12px', color: '#ccc' }}>{track.duration}</td>
                          </tr>
                        )}
                        {track.featured && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Status:</td>
                            <td style={{ padding: '6px 12px', color: infoSection.color, fontWeight: 'bold' }}>★ FEATURED</td>
                          </tr>
                        )}
                      </tbody>
                    </table>

                    {/* Streaming Links inline */}
                    {hasStreaming && (
                      <div style={{ padding: '10px 12px', display: 'flex', gap: '8px', flexWrap: 'wrap', borderTop: '1px solid #333', marginTop: '8px' }}>
                        <Link
                          to={`/vault?filter=${encodeURIComponent(track.title)}`}
                          style={{
                            padding: '6px 14px',
                            background: colorScheme.primary,
                            color: '#fff',
                            textDecoration: 'none',
                            fontWeight: 'bold',
                            fontSize: '0.85em',
                            boxShadow: `0 0 10px ${colorScheme.glow}`
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
                              padding: '6px 14px',
                              background: '#222',
                              color: '#aaa',
                              textDecoration: 'none',
                              border: '1px solid #444',
                              fontSize: '0.85em'
                            }}
                          >
                            → {titleize(platform)}
                          </a>
                        ))}
                      </div>
                    )}

                    {/* Vidz thumbnails */}
                    {hasVidz && (
                      <div style={{ padding: '10px 12px', display: 'flex', gap: '10px', flexWrap: 'wrap', borderTop: '1px solid #333' }}>
                        {track.vidz.map((vod) => {
                          const videoIdMatch = vod.vod_url?.match(/embed\/([a-zA-Z0-9_-]{11})/)
                          const thumbnailUrl = videoIdMatch
                            ? `https://img.youtube.com/vi/${videoIdMatch[1]}/mqdefault.jpg`
                            : null
                          return (
                            <Link
                              key={vod.id}
                              to={`/${artistSlug}/vidz/${vod.id}`}
                              style={{ textDecoration: 'none', color: 'inherit' }}
                              title={vod.title}
                            >
                              <div
                                style={{
                                  width: '160px',
                                  height: '90px',
                                  background: thumbnailUrl
                                    ? `url(${thumbnailUrl}) center / cover no-repeat`
                                    : '#222',
                                  borderRadius: '2px',
                                  position: 'relative',
                                  border: `1px solid ${infoSection.color}44`
                                }}
                              >
                                <div
                                  style={{
                                    position: 'absolute',
                                    top: '50%',
                                    left: '50%',
                                    transform: 'translate(-50%, -50%)',
                                    width: '30px',
                                    height: '30px',
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
                                      borderLeft: '10px solid #fff',
                                      borderTop: '6px solid transparent',
                                      borderBottom: '6px solid transparent',
                                      marginLeft: '2px'
                                    }}
                                  />
                                </div>
                              </div>
                            </Link>
                          )
                        })}
                      </div>
                    )}
                  </fieldset>
                </div>
              </div>
            </div>

            {/* Lyrics - full width below */}
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
                          <p style={{ margin: 0 }} {...props} />
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
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px', flexWrap: 'wrap' }}>
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
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TrackDetailPage
