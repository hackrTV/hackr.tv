import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { apiJson } from '~/utils/apiClient'

interface Release {
  id: number
  name: string
  slug: string
  release_type: string | null
  release_date: string | null
  artist: {
    id: number
    name: string
    slug: string
    genre: string
  }
  cover_url: string | null
  track_count: number
  label: string | null
}

export const FmLandingPage: React.FC = () => {
  const { isMobile } = useMobileDetect()
  const currentYear = new Date().getFullYear()
  const futureYear = currentYear + 100
  const [latestReleases, setLatestReleases] = useState<Release[]>([])

  useEffect(() => {
    apiJson<Release[]>('/api/releases')
      .then(data => {
        const labelReleases = data
          .filter(r => r.label?.toLowerCase() === 'hackr.fm' && r.cover_url)
          .slice(0, 3)
        setLatestReleases(labelReleases)
      })
      .catch(error => console.error('Error fetching releases:', error))
  }, [])

  return (
    <FmLayout>
      <div className="tui-window white-text" style={{ maxWidth: isMobile ? '100%' : '1000px', margin: '0 auto', display: 'block', background: '#1a1a1a', border: '2px solid #7c3aed' }}>
        <fieldset style={{ borderColor: '#7c3aed' }}>
          <legend className="center" style={{ color: '#7c3aed' }}>hackr.fm</legend>

          <div style={{ padding: isMobile ? '15px' : '30px' }}>
            {/* Header */}
            <h2 style={{ textAlign: 'center', marginBottom: '5px', color: '#7c3aed', fontSize: isMobile ? '1.3em' : '1.8em' }}>
              [:: hackr.fm ::]
            </h2>
            <p style={{ textAlign: 'center', color: '#666', marginBottom: '30px', fontSize: '0.9em' }}>
              MUSIC LABEL &amp; BROADCAST NETWORK
            </p>

            {/* Lore narrative */}
            <div style={{ marginBottom: '30px', padding: isMobile ? '15px' : '20px', background: '#0a0a0a', border: '1px solid #333', lineHeight: '1.8' }}>
              <p style={{ color: '#ccc', marginBottom: '15px' }}>
                In {currentYear}, hackr.fm opened as a frequency — a channel tuned to something that was already
                there, carrying music that refused to be owned, cataloged, or silenced. By {futureYear}, it will
                become the backbone of the Fracture Network's broadcast infrastructure: a decentralized label
                transmitting from nodes scattered across the grid.
              </p>
              <p style={{ color: '#aaa', marginBottom: '15px' }}>
                Every artist on hackr.fm operates under one principle: <span style={{ color: '#7c3aed' }}>the music carries the signal, not the system's approval</span>.
                No RIDE-approved playlists. No managed reality. No substitute for the real thing. Just
                uncompromising sound moving directly from creator to listener — because what it carries
                is something GovCorp has never been able to counterfeit.
              </p>
              <p style={{ color: '#888' }}>
                This is the home frequency. From here, you can tune into live broadcasts, explore the vault
                of everything we've ever released, or connect with the artists who make up
                the Fracture Network. The signal is always on. You just have to listen.
              </p>
            </div>

            {/* Latest Releases */}
            {latestReleases.length > 0 && (
              <div style={{ marginBottom: '30px' }}>
                <h3 style={{ color: '#7c3aed', textAlign: 'center', marginBottom: '20px', fontSize: '1.1em', letterSpacing: '2px' }}>
                  LATEST RELEASES
                </h3>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: isMobile ? '1fr' : 'repeat(3, 1fr)',
                  gap: isMobile ? '15px' : '20px'
                }}>
                  {latestReleases.map(release => (
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
                            <img src={release.cover_url} alt={release.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                          ) : (
                            <div style={{ color: '#333', fontSize: '3em', fontFamily: 'monospace' }}>&#9834;</div>
                          )}
                        </div>
                        <div style={{ padding: '12px' }}>
                          <div style={{ color: '#7c3aed', fontWeight: 'bold', fontSize: '1em', marginBottom: '4px' }}>
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
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}

            {/* Navigation cards */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: isMobile ? '1fr' : 'repeat(3, 1fr)',
              gap: isMobile ? '15px' : '20px',
              marginBottom: '30px'
            }}>
              {/* Radio */}
              <Link to="/fm/radio" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #ef4444', cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: '#ef4444', height: '100%' }}>
                    <legend style={{ color: '#ef4444' }}>RADIO</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: '#ef4444', fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ▶ RADIO
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        Live stations broadcasting around the clock — raw frequencies, unfiltered.
                        Tune in{isMobile ? '.' : ' and let the signal find you.'}
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* Vault */}
              <Link to="/vault" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #a855f7', cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: '#a855f7', height: '100%' }}>
                    <legend style={{ color: '#a855f7' }}>VAULT</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: '#a855f7', fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ◆ VAULT
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        The complete archive. Every track ever released on hackr.fm — searchable
                        and ready to play on demand.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>

              {/* FNet */}
              <Link to="/f/net" style={{ textDecoration: 'none' }}>
                <div className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #10b981', cursor: 'pointer', height: '100%' }}>
                  <fieldset style={{ borderColor: '#10b981', height: '100%' }}>
                    <legend style={{ color: '#10b981' }}>FNET</legend>
                    <div style={{ padding: isMobile ? '10px' : '15px' }}>
                      <p style={{ color: '#10b981', fontSize: '1.4em', marginBottom: '10px', textAlign: 'center' }}>
                        ◈ FNET
                      </p>
                      <p style={{ color: '#999', fontSize: '0.9em', lineHeight: '1.6' }}>
                        The Fracture Network roster. Meet the artists who carry the signal
                        through sound — each with a story and a frequency.
                      </p>
                    </div>
                  </fieldset>
                </div>
              </Link>
            </div>

            {/* Footer tagline */}
            <div style={{ textAlign: 'center', padding: '15px', borderTop: '1px solid #333' }}>
              <p style={{ color: '#555', fontSize: '0.85em' }}>
                hackr.fm — the signal is always on
              </p>
            </div>
          </div>
        </fieldset>
      </div>
    </FmLayout>
  )
}
