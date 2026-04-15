import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { getArtistColors } from '~/utils/artistColors'
import { apiFetch, apiJson } from '~/utils/apiClient'
import { useGridAuth } from '~/hooks/useGridAuth'
import { useHackrScopedDedupSet } from '~/hooks/useHackrScopedDedup'

interface Release {
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
  coming_soon?: boolean
  artist: {
    id: number
    name: string
    slug: string
    genre: string
  }
  cover_url: string | null
  cover_urls?: { thumbnail: string; standard: string; full: string }
  track_count: number
}

const ReleaseListPage: React.FC = () => {
  const location = useLocation()
  const { hackr } = useGridAuth()
  const [releases, setReleases] = useState<Release[]>([])
  const [comingSoon, setComingSoon] = useState<Release[]>([])
  const [loading, setLoading] = useState(true)
  const [artistName, setArtistName] = useState('')

  const artistSlug = location.pathname.split('/')[1] ?? ''
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

  useEffect(() => {
    if (!artistSlug) return

    Promise.all([
      apiJson<Release[]>('/api/releases'),
      apiJson<Release[]>('/api/releases/coming_soon')
    ])
      .then(([releasesData, comingSoonData]) => {
        const artistReleases = releasesData.filter(r => r.artist.slug === artistSlug)
        const artistComingSoon = comingSoonData.filter(r => r.artist.slug === artistSlug)
        if (artistReleases.length > 0) {
          setArtistName(artistReleases[0]!.artist.name)
        } else if (artistComingSoon.length > 0) {
          setArtistName(artistComingSoon[0]!.artist.name)
        }
        artistReleases.sort((a, b) => {
          const dateA = a.release_date || ''
          const dateB = b.release_date || ''
          return dateB.localeCompare(dateA)
        })
        setReleases(artistReleases)
        setComingSoon(artistComingSoon)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching releases:', error)
        setLoading(false)
      })
  }, [artistSlug])

  // Credit the release-index view once both artistSlug and auth have
  // resolved. Handles the case where auth lands after the releases
  // API call completes. Dedup scoped to hackr.id so logout/login
  // swap resets cleanly.
  const creditedSlugsRef = useHackrScopedDedupSet<string>(hackr?.id)
  useEffect(() => {
    if (!hackr || !artistSlug) return
    if (creditedSlugsRef.current.has(artistSlug)) return
    creditedSlugsRef.current.add(artistSlug)
    apiFetch(`/api/artists/${encodeURIComponent(artistSlug)}/release_index_viewed`, { method: 'POST' })
      .catch(() => { /* fire-and-forget */ })
  }, [hackr, artistSlug, creditedSlugsRef])

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
              LOADING RELEASES
            </legend>
            <div style={{ padding: '40px' }}>
              <LoadingSpinner message="Scanning release catalog..." color="purple-168-text" size="large" />
            </div>
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
          background: colorScheme.background,
          ...outerBorderStyle
        }}
      >
        <fieldset style={{ borderColor: hasPrismatic ? 'transparent' : colorScheme.primary, ...(hasPrismatic ? { border: 'none' } : {}) }}>
          <legend
            className="center"
            style={legendStyle}
          >
            {artistName || artistSlug.toUpperCase()} :: RELEASES
          </legend>

          <div>
            {comingSoon.length > 0 && (
              <style>{`
                @keyframes scanline-move {
                  0% { background-position: 0 0; }
                  100% { background-position: 0 4px; }
                }
                @keyframes glitch-shift {
                  0%, 100% { transform: translate(0); }
                  20% { transform: translate(-2px, 1px); }
                  40% { transform: translate(2px, -1px); }
                  60% { transform: translate(-1px, -1px); }
                  80% { transform: translate(1px, 2px); }
                }
                @keyframes border-glow {
                  0%, 100% { border-color: #7c3aed; box-shadow: 0 0 8px rgba(124, 58, 237, 0.3); }
                  50% { border-color: #a855f7; box-shadow: 0 0 15px rgba(168, 85, 247, 0.5); }
                }
              `}</style>
            )}

            {releases.length === 0 && comingSoon.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', background: `rgba(${colorScheme.primary}, 0.05)`, border: `1px solid ${colorScheme.primary}33` }}>
                <p style={{ color: '#aaa' }}>No releases cataloged yet.</p>
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' }}>
                {[...comingSoon.map(r => ({ ...r, _comingSoon: true as const })), ...releases.map(r => ({ ...r, _comingSoon: false as const }))].map((release, index) => {
                  const isComingSoon = release._comingSoon
                  const accentColor: string = isComingSoon ? '#7c3aed'
                    : hasPrismatic && colorScheme.accentColors
                      ? colorScheme.accentColors[index % colorScheme.accentColors.length] ?? colorScheme.primary
                      : colorScheme.primary
                  const accentGlow = isComingSoon ? 'rgba(124, 58, 237, 0.5)'
                    : hasPrismatic ? `${accentColor}99` : colorScheme.glow

                  return (
                    <Link
                      key={release.id}
                      to={`/${artistSlug}/releases/${release.slug}`}
                      style={{ textDecoration: 'none', color: 'inherit', display: 'flex' }}
                    >
                      <div
                        style={{
                          width: '100%',
                          background: isComingSoon ? '#0a0a0a' : '#000',
                          border: `1px solid ${accentColor}`,
                          ...(isComingSoon
                            ? { animation: 'border-glow 3s ease-in-out infinite' }
                            : { boxShadow: `0 0 15px ${accentColor}33` }),
                          transition: 'box-shadow 0.2s ease, border-color 0.2s ease, transform 0.2s ease',
                          cursor: 'pointer',
                          position: 'relative',
                          overflow: 'hidden'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = 'scale(1.02)'
                          if (!isComingSoon) {
                            e.currentTarget.style.boxShadow = `0 0 25px ${accentGlow}`
                            e.currentTarget.style.borderColor = accentColor
                          }
                          const img = e.currentTarget.querySelector('img') as HTMLElement
                          if (img && isComingSoon) img.style.animation = 'glitch-shift 0.3s ease-in-out 3'
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = 'scale(1)'
                          if (!isComingSoon) {
                            e.currentTarget.style.boxShadow = `0 0 15px ${accentColor}33`
                          }
                          const img = e.currentTarget.querySelector('img') as HTMLElement
                          if (img && isComingSoon) img.style.animation = 'none'
                        }}
                      >
                        {/* Cover Image */}
                        <div style={{ width: '100%', aspectRatio: '1', background: '#111', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden', position: 'relative' }}>
                          {release.cover_url ? (
                            <img
                              src={(isComingSoon ? release.cover_urls?.standard : release.cover_urls?.full) || release.cover_url}
                              alt={release.name}
                              style={{
                                width: '100%',
                                height: '100%',
                                objectFit: 'cover',
                                ...(isComingSoon ? { filter: 'saturate(0.5) brightness(0.6) contrast(1.1)' } : {})
                              }}
                            />
                          ) : (
                            <div style={{ color: '#333', fontSize: '3em', fontFamily: 'monospace' }}>&#9834;</div>
                          )}
                          {isComingSoon && (
                            <>
                              {/* Scanline overlay */}
                              <div style={{
                                position: 'absolute',
                                inset: 0,
                                background: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(0, 0, 0, 0.3) 2px, rgba(0, 0, 0, 0.3) 4px)',
                                animation: 'scanline-move 0.5s linear infinite',
                                pointerEvents: 'none'
                              }} />
                              {/* Purple tint overlay */}
                              <div style={{
                                position: 'absolute',
                                inset: 0,
                                background: 'rgba(124, 58, 237, 0.15)',
                                pointerEvents: 'none'
                              }} />
                              {/* INCOMING badge */}
                              <div style={{
                                position: 'absolute',
                                top: '8px',
                                right: '8px',
                                background: 'rgba(124, 58, 237, 0.85)',
                                color: '#fff',
                                padding: '2px 8px',
                                fontSize: '0.65em',
                                letterSpacing: '2px',
                                fontWeight: 'bold'
                              }}>
                                INCOMING
                              </div>
                            </>
                          )}
                        </div>

                        {/* Release Info */}
                        <div style={{ padding: '15px' }}>
                          <div style={{ color: accentColor, fontWeight: 'bold', fontSize: '1.1em', marginBottom: '5px', textShadow: `0 0 8px ${accentGlow}` }}>
                            {release.name}
                          </div>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <span style={{ color: '#888', fontSize: '0.9em' }}>
                              {release.release_type?.toUpperCase() || 'RELEASE'}
                            </span>
                            <span style={{ color: '#666', fontSize: '0.85em' }}>
                              {release.track_count} track{release.track_count !== 1 ? 's' : ''}
                            </span>
                          </div>
                          {release.release_date && !isComingSoon && (
                            <div style={{ color: '#555', fontSize: '0.85em', marginTop: '5px' }}>
                              {release.release_date}
                            </div>
                          )}
                          {release.catalog_number && (
                            <div style={{ color: '#555', fontSize: '0.8em', marginTop: '3px', fontFamily: 'monospace' }}>
                              {release.catalog_number}
                            </div>
                          )}
                        </div>
                      </div>
                    </Link>
                  )
                })}
              </div>
            )}

            {/* Navigation */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to={`/${artistSlug}`}
                style={{ padding: '10px 20px', background: '#222', color: '#888', textDecoration: 'none', border: '1px solid #444' }}
              >
                ← {artistName || artistSlug.toUpperCase()}
              </Link>
              <Link
                to="/vault"
                style={{ padding: '10px 20px', background: colorScheme.primary, color: 'white', textDecoration: 'none', fontWeight: 'bold', boxShadow: `0 0 15px ${colorScheme.glow}` }}
              >
                PULSE VAULT →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default ReleaseListPage
