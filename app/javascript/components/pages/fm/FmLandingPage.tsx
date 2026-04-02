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
  }
  cover_url: string
  cover_urls?: { thumbnail: string; standard: string; full: string }
  track_count: number
}

export const FmLandingPage: React.FC = () => {
  const { isMobile } = useMobileDetect()
  const currentYear = new Date().getFullYear()
  const futureYear = currentYear + 100
  const [latestReleases, setLatestReleases] = useState<Release[]>([])
  const [comingSoon, setComingSoon] = useState<Release[]>([])

  useEffect(() => {
    apiJson<Release[]>('/api/releases/latest')
      .then(data => setLatestReleases(data))
      .catch(error => console.error('Error fetching releases:', error))
    apiJson<Release[]>('/api/releases/coming_soon')
      .then(data => setComingSoon(data))
      .catch(error => console.error('Error fetching coming soon:', error))
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
                          transition: 'box-shadow 0.2s ease, transform 0.2s ease',
                          cursor: 'pointer'
                        }}
                        onMouseEnter={e => { e.currentTarget.style.boxShadow = '0 0 20px rgba(124, 58, 237, 0.4)'; e.currentTarget.style.transform = 'scale(1.02)' }}
                        onMouseLeave={e => { e.currentTarget.style.boxShadow = '0 0 10px rgba(124, 58, 237, 0.15)'; e.currentTarget.style.transform = 'scale(1)' }}
                      >
                        <div style={{ width: '100%', aspectRatio: '1', background: '#111', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                          {release.cover_url ? (
                            <img src={release.cover_urls?.full || release.cover_url} alt={release.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
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
                <div style={{ textAlign: 'center', marginTop: '20px' }}>
                  <Link
                    to="/fm/releases"
                    style={{
                      display: 'inline-block',
                      padding: '10px 25px',
                      background: 'transparent',
                      color: '#7c3aed',
                      textDecoration: 'none',
                      border: '1px solid #7c3aed',
                      letterSpacing: '2px',
                      fontSize: '0.9em',
                      transition: 'background 0.2s ease, color 0.2s ease'
                    }}
                    onMouseEnter={e => { e.currentTarget.style.background = '#7c3aed'; e.currentTarget.style.color = 'white' }}
                    onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.color = '#7c3aed' }}
                  >
                    VIEW ALL RELEASES →
                  </Link>
                </div>
              </div>
            )}

            {/* Coming Soon */}
            {comingSoon.length > 0 && (
              <div style={{ marginBottom: '30px' }}>
                <div style={{ borderTop: '1px solid #333', marginBottom: '25px' }} />
                <style>{`
                  @keyframes signal-pulse {
                    0%, 100% { opacity: 1; text-shadow: 0 0 10px #7c3aed, 0 0 20px #7c3aed; }
                    50% { opacity: 0.7; text-shadow: 0 0 5px #7c3aed; }
                  }
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
                <h3 style={{
                  color: '#7c3aed',
                  textAlign: 'center',
                  marginBottom: '20px',
                  fontSize: '1.1em',
                  letterSpacing: '3px',
                  animation: 'signal-pulse 2s ease-in-out infinite'
                }}>
                  ◈ SIGNAL INCOMING ◈
                </h3>
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: isMobile ? 'repeat(2, 1fr)' : `repeat(${Math.min(comingSoon.length, 4)}, 1fr)`,
                  gap: isMobile ? '10px' : '15px'
                }}>
                  {comingSoon.map(release => (
                    <Link
                      key={release.id}
                      to={`/${release.artist.slug}/releases/${release.slug}`}
                      style={{ textDecoration: 'none', color: 'inherit' }}
                    >
                      <div
                        style={{
                          background: '#0a0a0a',
                          border: '1px solid #7c3aed',
                          animation: 'border-glow 3s ease-in-out infinite',
                          transition: 'transform 0.2s ease',
                          position: 'relative',
                          overflow: 'hidden'
                        }}
                        onMouseEnter={e => {
                          e.currentTarget.style.transform = 'scale(1.02)'
                          const img = e.currentTarget.querySelector('img') as HTMLElement
                          if (img) img.style.animation = 'glitch-shift 0.3s ease-in-out 3'
                        }}
                        onMouseLeave={e => {
                          e.currentTarget.style.transform = 'scale(1)'
                          const img = e.currentTarget.querySelector('img') as HTMLElement
                          if (img) img.style.animation = 'none'
                        }}
                      >
                        {/* Cover with scanline overlay */}
                        <div style={{ width: '100%', aspectRatio: '1', background: '#111', position: 'relative', overflow: 'hidden' }}>
                          {release.cover_url ? (
                            <img
                              src={release.cover_urls?.standard || release.cover_url}
                              alt={release.name}
                              style={{
                                width: '100%',
                                height: '100%',
                                objectFit: 'cover',
                                filter: 'saturate(0.5) brightness(0.6) contrast(1.1)'
                              }}
                            />
                          ) : (
                            <div style={{ color: '#333', fontSize: '2em', fontFamily: 'monospace', display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}>&#9834;</div>
                          )}
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
                        </div>
                        <div style={{ padding: '10px' }}>
                          <div style={{ color: '#7c3aed', fontWeight: 'bold', fontSize: '0.9em', marginBottom: '3px' }}>
                            {release.name}
                          </div>
                          <div style={{ color: '#888', fontSize: '0.75em', marginBottom: '4px' }}>
                            {release.artist.name}
                          </div>
                          <div style={{ color: '#555', fontSize: '0.7em', letterSpacing: '1px' }}>
                            {release.release_type?.toUpperCase() || 'RELEASE'} · {release.track_count} track{release.track_count !== 1 ? 's' : ''}
                          </div>
                        </div>
                      </div>
                    </Link>
                  ))}
                </div>
              </div>
            )}

            {/* Navigation cards */}
            <div style={{ borderTop: '1px solid #333', marginBottom: '25px' }} />
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
