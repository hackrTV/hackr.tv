import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { getArtistColors } from '~/utils/artistColors'
import { useAudio } from '~/contexts/AudioContext'
import { apiJson } from '~/utils/apiClient'

interface ReleaseTrack {
  id: number
  title: string
  slug: string
  track_number: number | null
  duration: string | null
  streaming_links: Record<string, string> | null
  audio_url: string | null
  vidz: { id: number; title: string }[]
}

interface ReleaseDetail {
  id: number
  name: string
  slug: string
  release_type: string | null
  release_date: string | null
  description: string | null
  catalog_number: string | null
  media_format: string | null
  classification: string | null
  label: string | null
  credits: string | null
  notes: string | null
  coming_soon: boolean
  streaming_links: Record<string, string> | null
  artist: {
    id: number
    name: string
    slug: string
    genre: string
  }
  cover_url: string | null
  cover_urls?: { thumbnail: string; standard: string; full: string }
  disc_length: string | null
  tracks: ReleaseTrack[]
}

const ReleaseDetailPage: React.FC = () => {
  const location = useLocation()
  const { audioPlayerAPI } = useAudio()
  const [release, setRelease] = useState<ReleaseDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [currentTrackId, setCurrentTrackId] = useState<number | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)

  const pathParts = location.pathname.split('/')
  const artistSlug = pathParts[1]
  const releaseSlug = pathParts[3]
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

  const getSectionStyle = (index: number): { borderColor: string; legendColor: string; glowColor: string } => {
    const color = getAccentColor(index)
    return {
      borderColor: color,
      legendColor: color,
      glowColor: hasPrismatic ? `${color}99` : colorScheme.glow
    }
  }

  useEffect(() => {
    if (!releaseSlug) return

    apiJson<ReleaseDetail>(`/api/releases/${releaseSlug}`)
      .then(data => {
        setRelease(data)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching release:', error)
        setLoading(false)
      })
  }, [releaseSlug])

  // Track play state
  useEffect(() => {
    const updatePlayState = () => {
      if (audioPlayerAPI.current) {
        const trackId = audioPlayerAPI.current.getCurrentTrackId()
        setCurrentTrackId(trackId ? parseInt(trackId) : null)
        setIsPlaying(audioPlayerAPI.current.isPlaying())
      }
    }
    const interval = setInterval(updatePlayState, 500)
    return () => clearInterval(interval)
  }, [audioPlayerAPI])

  const handlePlayTrack = (track: ReleaseTrack) => {
    if (!track.audio_url || !audioPlayerAPI.current || !release) return

    if (currentTrackId === track.id) {
      audioPlayerAPI.current.togglePlayPause()
    } else {
      const playableTracks = release.tracks
        .filter(t => t.audio_url)
        .map(t => ({
          id: t.id.toString(),
          url: t.audio_url!,
          title: t.title,
          artist: release.artist.name,
          coverUrl: release.cover_url || '',
          coverUrls: release.cover_urls
        }))

      audioPlayerAPI.current.setPlaylist(playableTracks)
      audioPlayerAPI.current.loadTrack({
        id: track.id.toString(),
        url: track.audio_url,
        title: track.title,
        artist: release.artist.name,
        coverUrl: release.cover_url || '',
        coverUrls: release.cover_urls
      })
    }
  }

  if (loading) {
    return (
      <DefaultLayout>
        <div className="tui-window white-text" style={{ maxWidth: '1200px', background: colorScheme.background, ...outerBorderStyle }}>
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
              LOADING RELEASE
            </legend>
            <div style={{ padding: '40px' }}>
              <LoadingSpinner message="Decoding release data..." color="purple-168-text" size="large" />
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  if (!release) {
    return (
      <DefaultLayout>
        <div className="tui-window white-text" style={{ maxWidth: '1200px', background: colorScheme.background, ...outerBorderStyle }}>
          <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
            <legend style={legendStyle}>
              SIGNAL LOST
            </legend>
            <div style={{ padding: '40px', textAlign: 'center' }}>
              <p style={{ color: '#ff5555' }}>Release not found.</p>
            </div>
          </fieldset>
        </div>
      </DefaultLayout>
    )
  }

  // Use release-level streaming links if present, otherwise aggregate from tracks
  const allStreamingLinks: Record<string, string> = {}
  if (release.streaming_links) {
    Object.assign(allStreamingLinks, release.streaming_links)
  } else {
    release.tracks.forEach(track => {
      if (track.streaming_links) {
        Object.entries(track.streaming_links).forEach(([platform, url]) => {
          if (!allStreamingLinks[platform]) {
            allStreamingLinks[platform] = url
          }
        })
      }
    })
  }

  const platformOrder = ['bandcamp', 'youtube', 'spotify', 'apple_music', 'soundcloud']
  const sortedLinks = Object.entries(allStreamingLinks).sort((a, b) => {
    const indexA = platformOrder.indexOf(a[0].toLowerCase())
    const indexB = platformOrder.indexOf(b[0].toLowerCase())
    if (indexA !== -1 && indexB !== -1) return indexA - indexB
    if (indexA !== -1) return -1
    if (indexB !== -1) return 1
    return 0
  })

  const titleize = (str: string) => {
    if (str.toLowerCase() === 'youtube') return 'YouTube'
    return str.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
  }

  // Section index counter for cycling accent colors
  let sectionIndex = 0
  const releaseInfoSection = getSectionStyle(sectionIndex++)
  const creditsSection = release.credits ? getSectionStyle(sectionIndex++) : null
  const tracklistSection = getSectionStyle(sectionIndex++)
  const notesSection = release.notes ? getSectionStyle(sectionIndex++) : null
  const streamingSection = sortedLinks.length > 0 ? getSectionStyle(sectionIndex++) : null

  return (
    <DefaultLayout>
      {release.coming_soon && (
        <style>{`
          @keyframes cs-scanline {
            0% { background-position: 0 0; }
            100% { background-position: 0 4px; }
          }
          @keyframes cs-glitch {
            0%, 100% { transform: translate(0) skew(0deg); }
            10% { transform: translate(-2px, 1px) skew(0.5deg); }
            30% { transform: translate(2px, -1px) skew(-0.5deg); }
            50% { transform: translate(-1px, 2px) skew(0.3deg); }
            70% { transform: translate(1px, -2px) skew(-0.3deg); }
            90% { transform: translate(-1px, 0) skew(0.2deg); }
          }
          @keyframes cs-flicker {
            0%, 100% { opacity: 1; }
            92% { opacity: 1; }
            93% { opacity: 0.3; }
            94% { opacity: 1; }
            96% { opacity: 0.5; }
            97% { opacity: 1; }
          }
          @keyframes cs-banner-pulse {
            0%, 100% { background-color: rgba(124, 58, 237, 0.15); border-color: #7c3aed; }
            50% { background-color: rgba(124, 58, 237, 0.25); border-color: #a855f7; }
          }
          @keyframes cs-text-glitch {
            0%, 100% { text-shadow: 0 0 10px #7c3aed; }
            25% { text-shadow: -2px 0 #ff0080, 2px 0 #00ffff; }
            50% { text-shadow: 0 0 10px #7c3aed; }
            75% { text-shadow: 2px 0 #ff0080, -2px 0 #00ffff; }
          }
          @keyframes cs-redact-pulse {
            0%, 100% { opacity: 0.6; }
            50% { opacity: 0.4; }
          }
        `}</style>
      )}
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
            {release.name.toUpperCase()}
          </legend>

          <div>
            {/* Coming Soon Banner */}
            {release.coming_soon && (
              <div style={{
                marginBottom: '25px',
                padding: '15px',
                border: '1px solid #7c3aed',
                textAlign: 'center',
                animation: 'cs-banner-pulse 2s ease-in-out infinite',
                position: 'relative',
                overflow: 'hidden'
              }}>
                <div style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 0, 0, 0.15) 2px, rgba(0, 0, 0, 0.15) 4px)',
                  animation: 'cs-scanline 0.5s linear infinite',
                  pointerEvents: 'none'
                }} />
                <div style={{
                  fontSize: '1.2em',
                  fontWeight: 'bold',
                  color: '#7c3aed',
                  letterSpacing: '4px',
                  animation: 'cs-text-glitch 4s ease-in-out infinite',
                  fontFamily: 'monospace'
                }}>
                  ◈ SIGNAL INCOMING — TRANSMISSION PENDING ◈
                </div>
                <div style={{ color: '#666', fontSize: '0.8em', marginTop: '8px', letterSpacing: '2px' }}>
                  RELEASE DATA PARTIALLY DECRYPTED — FULL SIGNAL LOCK PENDING
                </div>
              </div>
            )}
            {/* Release Header: Cover + Info */}
            <div style={{ display: 'flex', gap: '25px', marginBottom: '25px', flexWrap: 'wrap' }}>
              {/* Cover Image */}
              <div style={{
                flexShrink: 0,
                width: '250px',
                height: '250px',
                background: '#111',
                border: `1px solid ${getAccentColor(0)}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                overflow: 'hidden',
                position: 'relative',
                ...(release.coming_soon ? { animation: 'cs-flicker 8s ease-in-out infinite' } : {})
              }}>
                {release.cover_url ? (
                  <img
                    src={release.cover_urls?.full || release.cover_url}
                    alt={release.name}
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover',
                      ...(release.coming_soon ? { filter: 'saturate(0.4) brightness(0.6) contrast(1.2)' } : {})
                    }}
                  />
                ) : (
                  <div style={{ color: '#333', fontSize: '4em', fontFamily: 'monospace' }}>&#9834;</div>
                )}
                {release.coming_soon && (
                  <>
                    <div style={{
                      position: 'absolute',
                      inset: 0,
                      background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 0, 0, 0.3) 2px, rgba(0, 0, 0, 0.3) 4px)',
                      animation: 'cs-scanline 0.5s linear infinite',
                      pointerEvents: 'none'
                    }} />
                    <div style={{
                      position: 'absolute',
                      inset: 0,
                      background: 'rgba(124, 58, 237, 0.15)',
                      pointerEvents: 'none'
                    }} />
                  </>
                )}
              </div>

              {/* Release Info fieldset */}
              <div style={{ flex: 1, minWidth: '280px' }}>
                <div
                  className="tui-window white-text"
                  style={{ display: 'block', background: '#000', border: `1px solid ${releaseInfoSection.borderColor}` }}
                >
                  <fieldset style={{ borderColor: releaseInfoSection.borderColor }}>
                    <legend style={{ color: releaseInfoSection.legendColor, textShadow: `0 0 10px ${releaseInfoSection.glowColor}` }}>RELEASE INFO</legend>
                    <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                      <tbody>
                        <tr>
                          <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Title:</td>
                          <td style={{ padding: '6px 12px', color: '#ccc', fontWeight: 'bold' }}>{release.name}</td>
                        </tr>
                        <tr>
                          <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Artist:</td>
                          <td style={{ padding: '6px 12px' }}>
                            <Link to={`/${artistSlug}`} style={{ color: colorScheme.primary, textDecoration: 'none', textShadow: `0 0 8px ${colorScheme.glow}` }}>
                              {release.artist.name}
                            </Link>
                          </td>
                        </tr>
                        {(release.catalog_number || release.coming_soon) && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Catalog #:</td>
                            <td style={{ padding: '6px 12px', color: release.coming_soon ? '#444' : '#ccc', fontFamily: 'monospace' }}>
                              {release.coming_soon ? '███-███' : release.catalog_number}
                            </td>
                          </tr>
                        )}
                        {(release.release_date || release.coming_soon) && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Release Date:</td>
                            <td style={{ padding: '6px 12px', color: release.coming_soon ? '#7c3aed' : '#ccc' }}>
                              {release.coming_soon ? (
                                <span style={{ letterSpacing: '1px' }}>PENDING TRANSMISSION</span>
                              ) : release.release_date}
                            </td>
                          </tr>
                        )}
                        {(release.media_format || release.coming_soon) && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Media Format:</td>
                            <td style={{ padding: '6px 12px', color: release.coming_soon ? '#444' : '#ccc' }}>
                              {release.coming_soon ? '████████' : release.media_format}
                            </td>
                          </tr>
                        )}
                        {(release.classification || release.coming_soon) && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Classification:</td>
                            <td style={{ padding: '6px 12px', color: release.coming_soon ? '#444' : '#ccc' }}>
                              {release.coming_soon ? '[CLASSIFIED]' : release.classification}
                            </td>
                          </tr>
                        )}
                        {release.label && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Label:</td>
                            <td style={{ padding: '6px 12px', color: '#ccc' }}>{release.label}</td>
                          </tr>
                        )}
                        {release.release_type && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Release Type:</td>
                            <td style={{ padding: '6px 12px', color: '#ccc' }}>{release.release_type.toUpperCase()}</td>
                          </tr>
                        )}
                        {release.coming_soon && (
                          <tr>
                            <td style={{ padding: '6px 12px', color: '#888', whiteSpace: 'nowrap' }}>Status:</td>
                            <td style={{ padding: '6px 12px', color: '#7c3aed', fontFamily: 'monospace', letterSpacing: '1px' }}>SIGNAL INCOMING</td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </fieldset>
                </div>
              </div>
            </div>

            {/* Description */}
            {release.description && !release.coming_soon && (
              <div style={{ marginBottom: '25px', padding: '20px', background: '#000', border: `1px solid ${colorScheme.primary}33` }}>
                <p style={{ color: '#ccc', lineHeight: '1.7' }}>{release.description}</p>
              </div>
            )}

            {/* Credits */}
            {release.credits && creditsSection && !release.coming_soon && (
              <div className="tui-window white-text" style={{ display: 'block', marginBottom: '25px', background: '#000', border: `1px solid ${creditsSection.borderColor}` }}>
                <fieldset style={{ borderColor: creditsSection.borderColor }}>
                  <legend style={{ color: creditsSection.legendColor, textShadow: `0 0 10px ${creditsSection.glowColor}` }}>CREDITS</legend>
                  <div style={{ padding: '15px', color: '#ccc', lineHeight: '1.7', whiteSpace: 'pre-wrap' }}>
                    {release.credits}
                  </div>
                </fieldset>
              </div>
            )}

            {/* Tracklist */}
            <div className="tui-window white-text" style={{
              display: 'block',
              marginBottom: '25px',
              background: '#000',
              border: `1px solid ${tracklistSection.borderColor}`,
              position: 'relative'
            }}>
              <fieldset style={{ borderColor: tracklistSection.borderColor }}>
                <legend style={{ color: tracklistSection.legendColor, textShadow: `0 0 10px ${tracklistSection.glowColor}` }}>
                  {release.coming_soon ? 'TRACKLIST [ENCRYPTED]' : 'TRACKLIST'}
                </legend>
                <div style={{ padding: '10px' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <tbody>
                      {release.tracks.map((track, trackIndex) => {
                        const isActive = !release.coming_soon && currentTrackId === track.id && isPlaying
                        const trackAccent = getAccentColor(trackIndex)

                        if (release.coming_soon) {
                          const redactedNames = ['[SIGNAL ENCRYPTED]', '[DECRYPTING...]', '[LOCKED]', '[FREQUENCY MASKED]', '[INTERCEPTED]', '[AWAITING CLEARANCE]']
                          return (
                            <tr
                              key={track.id}
                              style={{
                                borderBottom: '1px solid #1a1a1a',
                                borderLeft: hasPrismatic ? `3px solid ${trackAccent}44` : 'none',
                                opacity: 0.5,
                                animation: `cs-redact-pulse ${3 + trackIndex * 0.5}s ease-in-out infinite`
                              }}
                            >
                              <td style={{ padding: '10px 12px', color: '#333', width: '40px', textAlign: 'right', fontFamily: 'monospace' }}>
                                {String(track.track_number || 0).padStart(2, '0')}
                              </td>
                              <td style={{ padding: '10px 12px', color: '#444', fontFamily: 'monospace', fontSize: '0.9em', letterSpacing: '1px' }}>
                                {redactedNames[trackIndex % redactedNames.length]}
                              </td>
                              <td style={{ padding: '10px 12px', width: '50px', textAlign: 'center' }}>
                                <span style={{ color: '#333', fontSize: '0.9em' }}>◌</span>
                              </td>
                              <td style={{ padding: '10px 12px', color: '#333', width: '60px', textAlign: 'right', fontFamily: 'monospace' }}>
                                ██:██
                              </td>
                              <td style={{ padding: '10px 12px' }} />
                            </tr>
                          )
                        }

                        return (
                          <tr
                            key={track.id}
                            style={{
                              borderBottom: '1px solid #222',
                              borderLeft: hasPrismatic ? `3px solid ${trackAccent}` : 'none',
                              cursor: track.audio_url ? 'pointer' : 'default',
                              backgroundColor: isActive ? `${trackAccent}22` : 'transparent',
                              opacity: track.audio_url ? 1 : 0.5
                            }}
                            onClick={() => track.audio_url && handlePlayTrack(track)}
                            onMouseEnter={(e) => {
                              if (track.audio_url && !isActive) e.currentTarget.style.backgroundColor = `${trackAccent}11`
                            }}
                            onMouseLeave={(e) => {
                              if (!isActive) e.currentTarget.style.backgroundColor = 'transparent'
                            }}
                          >
                            <td style={{ padding: '10px 12px', color: hasPrismatic ? trackAccent : '#666', width: '40px', textAlign: 'right', fontFamily: 'monospace' }}>
                              {String(track.track_number || 0).padStart(2, '0')}
                            </td>
                            <td style={{ padding: '10px 12px' }}>
                              <Link
                                to={`/${artistSlug}/trackz/${track.slug}`}
                                style={{ color: isActive ? '#00ffff' : '#ccc', textDecoration: 'none', fontWeight: isActive ? 'bold' : 'normal' }}
                                onClick={(e) => e.stopPropagation()}
                              >
                                {track.title}
                              </Link>
                            </td>
                            <td style={{ padding: '10px 12px', width: '50px', textAlign: 'center' }}>
                              {track.audio_url && (
                                <span style={{ color: isActive ? '#00ffff' : trackAccent, cursor: 'pointer', fontSize: '0.9em' }}>
                                  {isActive ? '❚❚' : '▶'}
                                </span>
                              )}
                            </td>
                            <td style={{ padding: '10px 12px', color: '#666', width: '60px', textAlign: 'right', fontFamily: 'monospace' }}>
                              {track.duration || '—'}
                            </td>
                            <td style={{ padding: '10px 12px', textAlign: 'center' }}>
                              {track.vidz?.length > 0 && (
                                <Link
                                  to={`/${artistSlug}/vidz/${track.vidz[0].id}`}
                                  style={{
                                    padding: '4px 10px',
                                    background: colorScheme.secondary,
                                    color: '#fff',
                                    textDecoration: 'none',
                                    fontWeight: 'bold',
                                    fontSize: '0.75em',
                                    letterSpacing: '1px',
                                    boxShadow: `0 0 8px ${trackAccent}66`
                                  }}
                                  title={track.vidz[0].title}
                                  onClick={(e) => e.stopPropagation()}
                                >
                                  ▶ VIDEO
                                </Link>
                              )}
                            </td>
                          </tr>
                        )
                      })}
                    </tbody>
                  </table>
                  {release.coming_soon ? (
                    <div style={{ textAlign: 'right', padding: '10px 12px', color: '#444', fontFamily: 'monospace', borderTop: '1px solid #1a1a1a', letterSpacing: '1px' }}>
                      Disc length&nbsp;&nbsp;██:██
                    </div>
                  ) : release.disc_length && (
                    <div style={{ textAlign: 'right', padding: '10px 12px', color: '#888', fontFamily: 'monospace', borderTop: '1px solid #333' }}>
                      Disc length&nbsp;&nbsp;{release.disc_length}
                    </div>
                  )}
                </div>
              </fieldset>
              {/* Scanline overlay for encrypted tracklist */}
              {release.coming_soon && (
                <div style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 0, 0, 0.1) 2px, rgba(0, 0, 0, 0.1) 4px)',
                  pointerEvents: 'none'
                }} />
              )}
            </div>

            {/* Notes */}
            {release.notes && notesSection && !release.coming_soon && (
              <div className="tui-window white-text" style={{ display: 'block', marginBottom: '25px', background: '#000', border: `1px solid ${notesSection.borderColor}` }}>
                <fieldset style={{ borderColor: notesSection.borderColor }}>
                  <legend style={{ color: notesSection.legendColor, textShadow: `0 0 10px ${notesSection.glowColor}` }}>NOTES</legend>
                  <div style={{ padding: '15px', color: '#ccc', lineHeight: '1.7', whiteSpace: 'pre-wrap' }}>
                    {release.notes}
                  </div>
                </fieldset>
              </div>
            )}

            {/* Streaming Links */}
            {release.coming_soon ? (
              <div className="tui-window white-text" style={{ display: 'block', marginBottom: '25px', background: '#000', border: '1px solid #333' }}>
                <fieldset style={{ borderColor: '#333' }}>
                  <legend style={{ color: '#444' }}>STREAMING FREQUENCIES</legend>
                  <div style={{ padding: '20px', textAlign: 'center' }}>
                    <div style={{ color: '#444', fontFamily: 'monospace', letterSpacing: '2px', fontSize: '0.9em' }}>
                      FREQUENCIES NOT YET ALLOCATED
                    </div>
                    <div style={{ color: '#333', fontSize: '0.75em', marginTop: '8px' }}>
                      Signal will be broadcast when transmission lock is acquired
                    </div>
                  </div>
                </fieldset>
              </div>
            ) : sortedLinks.length > 0 && streamingSection && (
              <div className="tui-window white-text" style={{ display: 'block', marginBottom: '25px', background: '#000', border: `1px solid ${streamingSection.borderColor}` }}>
                <fieldset style={{ borderColor: streamingSection.borderColor }}>
                  <legend style={{ color: streamingSection.legendColor, textShadow: `0 0 10px ${streamingSection.glowColor}` }}>STREAMING FREQUENCIES</legend>
                  <div style={{ padding: '15px', display: 'flex', gap: '10px', flexWrap: 'wrap' }}>
                    <Link
                      to={`/vault?filter=${encodeURIComponent(release.name)}`}
                      style={{
                        padding: '8px 16px',
                        background: colorScheme.primary,
                        color: '#fff',
                        textDecoration: 'none',
                        fontWeight: 'bold',
                        boxShadow: `0 0 15px ${colorScheme.glow}`,
                        fontSize: '0.9em'
                      }}
                    >
                      ▶ PULSE VAULT
                    </Link>
                    {sortedLinks.map(([platform, url]) => (
                      <a
                        key={platform}
                        href={url}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{
                          padding: '8px 16px',
                          background: '#222',
                          color: '#aaa',
                          textDecoration: 'none',
                          border: '1px solid #444',
                          fontSize: '0.9em'
                        }}
                      >
                        → {titleize(platform)}
                      </a>
                    ))}
                  </div>
                </fieldset>
              </div>
            )}

            {/* Navigation */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px', flexWrap: 'wrap' }}>
              <Link
                to={`/${artistSlug}`}
                style={{ padding: '10px 20px', background: '#222', color: '#888', textDecoration: 'none', border: '1px solid #444' }}
              >
                ← {release.artist.name}
              </Link>
              <Link
                to={`/${artistSlug}/releases`}
                style={{ padding: '10px 20px', background: colorScheme.secondary, color: 'white', textDecoration: 'none', fontWeight: 'bold' }}
              >
                ALL RELEASES
              </Link>
              <Link
                to="/vault"
                style={{ padding: '10px 20px', background: colorScheme.primary, color: 'white', textDecoration: 'none', fontWeight: 'bold', boxShadow: `0 0 15px ${colorScheme.glow}` }}
              >
                PULSE VAULT
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default ReleaseDetailPage
