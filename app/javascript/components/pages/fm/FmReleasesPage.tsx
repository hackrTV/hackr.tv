import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { apiJson } from '~/utils/apiClient'

interface Release {
  id: number
  name: string
  slug: string
  release_type: string | null
  release_date: string | null
  catalog_number: string | null
  label: string | null
  artist: {
    id: number
    name: string
    slug: string
  }
  cover_url: string | null
  cover_urls?: { thumbnail: string; standard: string; full: string }
  track_count: number
}

export const FmReleasesPage: React.FC = () => {
  const { isMobile } = useMobileDetect()
  const [releases, setReleases] = useState<Release[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(false)

  useEffect(() => {
    apiJson<Release[]>('/api/releases')
      .then(data => {
        const fmReleases = data.filter(r => r.label === 'hackr.fm')
        fmReleases.sort((a, b) => {
          const dateA = a.release_date || ''
          const dateB = b.release_date || ''
          return dateB.localeCompare(dateA)
        })
        setReleases(fmReleases)
        setLoading(false)
      })
      .catch(error => {
        console.error('Error fetching releases:', error)
        setError(true)
        setLoading(false)
      })
  }, [])

  if (loading) {
    return (
      <FmLayout>
        <div
          className="tui-window white-text"
          style={{ maxWidth: isMobile ? '100%' : '1200px', margin: '0 auto', display: 'block', background: '#1a1a1a', border: '2px solid #7c3aed' }}
        >
          <fieldset style={{ borderColor: '#7c3aed' }}>
            <legend className="center" style={{ color: '#7c3aed' }}>RELEASES</legend>
            <div style={{ padding: '40px' }}>
              <LoadingSpinner message="Scanning release catalog..." color="purple-168-text" size="large" />
            </div>
          </fieldset>
        </div>
      </FmLayout>
    )
  }

  return (
    <FmLayout>
      <div
        className="tui-window white-text"
        style={{
          maxWidth: isMobile ? '100%' : '1200px',
          margin: '0 auto',
          display: 'block',
          background: '#1a1a1a',
          border: '2px solid #7c3aed'
        }}
      >
        <fieldset style={{ borderColor: '#7c3aed' }}>
          <legend className="center" style={{ color: '#7c3aed', letterSpacing: '3px' }}>
            hackr.fm :: RELEASES
          </legend>

          <div>
            {error ? (
              <div style={{ padding: '40px', textAlign: 'center', background: 'rgba(239, 68, 68, 0.05)', border: '1px solid rgba(239, 68, 68, 0.3)' }}>
                <p style={{ color: '#ef4444' }}>Signal lost — failed to load releases. Try again later.</p>
              </div>
            ) : releases.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', background: 'rgba(124, 58, 237, 0.05)', border: '1px solid rgba(124, 58, 237, 0.2)' }}>
                <p style={{ color: '#aaa' }}>No releases cataloged yet.</p>
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' }}>
                {releases.map(release => (
                  <Link
                    key={release.id}
                    to={`/${release.artist.slug}/releases/${release.slug}`}
                    style={{ textDecoration: 'none', color: 'inherit' }}
                  >
                    <div
                      style={{
                        background: '#0d0d0d',
                        border: '1px solid #7c3aed',
                        boxShadow: '0 0 10px rgba(124, 58, 237, 0.15)',
                        transition: 'box-shadow 0.2s ease',
                        cursor: 'pointer'
                      }}
                      onMouseEnter={e => { e.currentTarget.style.boxShadow = '0 0 20px rgba(124, 58, 237, 0.4)' }}
                      onMouseLeave={e => { e.currentTarget.style.boxShadow = '0 0 10px rgba(124, 58, 237, 0.15)' }}
                    >
                      <div style={{ width: '100%', aspectRatio: '1', background: '#111', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                        {release.cover_url ? (
                          <img src={release.cover_urls?.full || release.cover_url} alt={release.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                        ) : (
                          <div style={{ color: '#333', fontSize: '3em', fontFamily: 'monospace' }}>&#9834;</div>
                        )}
                      </div>
                      <div style={{ padding: '15px' }}>
                        <div style={{ color: '#7c3aed', fontWeight: 'bold', fontSize: '1.1em', marginBottom: '4px', textShadow: '0 0 8px rgba(124, 58, 237, 0.6)' }}>
                          {release.name}
                        </div>
                        <div style={{ color: '#999', fontSize: '0.85em', marginBottom: '6px' }}>
                          {release.artist.name}
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={{ color: '#666', fontSize: '0.8em' }}>
                            {release.release_type?.toUpperCase() || 'RELEASE'} · {release.track_count} track{release.track_count !== 1 ? 's' : ''}
                          </span>
                          {release.release_date && (
                            <span style={{ color: '#555', fontSize: '0.8em' }}>
                              {release.release_date}
                            </span>
                          )}
                        </div>
                        {release.catalog_number && (
                          <div style={{ color: '#555', fontSize: '0.8em', marginTop: '3px', fontFamily: 'monospace' }}>
                            {release.catalog_number}
                          </div>
                        )}
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            )}

            {/* Navigation */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px', flexWrap: 'wrap' }}>
              <Link
                to="/fm"
                style={{ padding: '10px 20px', background: '#222', color: '#888', textDecoration: 'none', border: '1px solid #444' }}
              >
                ← hackr.fm
              </Link>
              <Link
                to="/vault"
                style={{ padding: '10px 20px', background: '#7c3aed', color: 'white', textDecoration: 'none', fontWeight: 'bold', boxShadow: '0 0 15px rgba(124, 58, 237, 0.4)' }}
              >
                PULSE VAULT →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </FmLayout>
  )
}
