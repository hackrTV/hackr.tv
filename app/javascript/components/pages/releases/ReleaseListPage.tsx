import React, { useState, useEffect } from 'react'
import { useLocation, Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { getArtistColors } from '~/utils/artistColors'
import { apiJson } from '~/utils/apiClient'

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
  artist: {
    id: number
    name: string
    slug: string
    genre: string
  }
  cover_url: string | null
  track_count: number
}

const ReleaseListPage: React.FC = () => {
  const location = useLocation()
  const [releases, setReleases] = useState<Release[]>([])
  const [loading, setLoading] = useState(true)
  const [artistName, setArtistName] = useState('')

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

  useEffect(() => {
    if (!artistSlug) return

    apiJson<Release[]>('/api/releases')
      .then(data => {
        const artistReleases = data.filter(r => r.artist.slug === artistSlug)
        if (artistReleases.length > 0) {
          setArtistName(artistReleases[0].artist.name)
        }
        artistReleases.sort((a, b) => {
          const dateA = a.release_date || ''
          const dateB = b.release_date || ''
          return dateB.localeCompare(dateA)
        })
        setReleases(artistReleases)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching releases:', error)
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
            {releases.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', background: `rgba(${colorScheme.primary}, 0.05)`, border: `1px solid ${colorScheme.primary}33` }}>
                <p style={{ color: '#aaa' }}>No releases cataloged yet.</p>
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' }}>
                {releases.map((release, index) => {
                  const accentColor = hasPrismatic && colorScheme.accentColors
                    ? colorScheme.accentColors[index % colorScheme.accentColors.length]
                    : colorScheme.primary
                  const accentGlow = hasPrismatic ? `${accentColor}99` : colorScheme.glow

                  return (
                    <Link
                      key={release.id}
                      to={`/${artistSlug}/releases/${release.slug}`}
                      style={{ textDecoration: 'none', color: 'inherit' }}
                    >
                      <div
                        style={{
                          background: '#000',
                          border: `1px solid ${accentColor}`,
                          boxShadow: `0 0 15px ${accentColor}33`,
                          transition: 'box-shadow 0.2s ease, border-color 0.2s ease',
                          cursor: 'pointer'
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.boxShadow = `0 0 25px ${accentGlow}`
                          e.currentTarget.style.borderColor = accentColor
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.boxShadow = `0 0 15px ${accentColor}33`
                        }}
                      >
                        {/* Cover Image */}
                        <div style={{ width: '100%', aspectRatio: '1', background: '#111', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                          {release.cover_url ? (
                            <img
                              src={release.cover_url}
                              alt={release.name}
                              style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                            />
                          ) : (
                            <div style={{ color: '#333', fontSize: '3em', fontFamily: 'monospace' }}>&#9834;</div>
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
                          {release.release_date && (
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
                to={`/${artistSlug}/trackz`}
                style={{ padding: '10px 20px', background: colorScheme.secondary, color: 'white', textDecoration: 'none', fontWeight: 'bold' }}
              >
                ALL TRACKZ →
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
