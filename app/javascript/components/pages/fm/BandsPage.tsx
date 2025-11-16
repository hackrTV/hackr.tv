import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'

interface Artist {
  id: number
  name: string
  slug: string
  genre: string
  track_count: number
}

export const BandsPage: React.FC = () => {
  const [artists, setArtists] = useState<Artist[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetch('/api/artists')
      .then(res => {
        if (!res.ok) throw new Error('Failed to load artists')
        return res.json()
      })
      .then(data => {
        setArtists(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message)
        setLoading(false)
      })
  }, [])

  const currentYear = new Date().getFullYear()

  const getProfilePath = (slug: string): string => {
    const profilePaths: { [key: string]: string } = {
      'xeraen': '/xeraen',
      'thecyberpulse': '/thecyberpulse',
      'system_rot': '/system_rot',
      'wavelength_zero': '/wavelength_zero',
      'voiceprint': '/voiceprint',
      'temporal_blue_drift': '/temporal_blue_drift'
    }
    return profilePaths[slug] || ''
  }

  return (
    <FmLayout>
      <div className="tui-window white-text" style={{ maxWidth: '1400px', background: '#1a1a1a', border: '2px solid #666' }}>
        <fieldset style={{ borderColor: '#666' }}>
          <legend className="center" style={{ color: '#10b981' }}>hackr.fm :: BANDS</legend>

          <div>
            <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#10b981' }}>
              [:: SECTOR X MEDIA ROSTER ::]
            </h2>

            {loading && <LoadingSpinner message="Loading Sector X Media roster..." color="green-255-text" />}

            {error && (
              <div style={{ padding: '40px', textAlign: 'center' }}>
                <p style={{ color: '#ff5555' }}>Error: {error}</p>
              </div>
            )}

            {!loading && !error && (
              <>
                <div style={{ marginBottom: '30px', padding: '15px', background: '#0a0a0a', border: '1px solid #444' }}>
                  <p style={{ color: '#999', textAlign: 'center' }}>
                    {artists.length} artists broadcasting from the underground | Each with a story, each with a mission
                  </p>
                </div>

                {artists.length > 0 ? (
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '20px' }}>
                    {artists.map((artist) => (
                      <div key={artist.id} className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #444' }}>
                        <fieldset style={{ borderColor: '#555' }}>
                          <legend style={{ color: '#10b981' }}>{artist.name.toUpperCase()}</legend>

                          <div style={{ padding: '15px' }}>
                            <div style={{ marginBottom: '15px' }}>
                              <p style={{ color: '#888', fontWeight: 'bold', marginBottom: '5px' }}>SLUG</p>
                              <p style={{ fontFamily: 'monospace', color: '#aaa' }}>/{artist.slug}</p>
                            </div>

                            <div style={{ marginBottom: '15px' }}>
                              <p style={{ color: '#888', fontWeight: 'bold', marginBottom: '5px' }}>TRACK COUNT</p>
                              <p style={{ color: '#aaa' }}>{artist.track_count} tracks available</p>
                            </div>

                            <div style={{ marginTop: '20px', display: 'flex', gap: '10px' }}>
                              {getProfilePath(artist.slug) ? (
                                <Link
                                  to={getProfilePath(artist.slug)}
                                  className="tui-button purple-168"
                                  style={{ flex: 1, textAlign: 'center' }}
                                >
                                  VIEW PROFILE
                                </Link>
                              ) : (
                                <button
                                  className="tui-button"
                                  style={{ flex: 1, opacity: 0.5, cursor: 'not-allowed' }}
                                  disabled
                                >
                                  COMING SOON
                                </button>
                              )}

                              {artist.track_count > 0 && (
                                <Link
                                  to={`/fm/pulse_vault?filter=${encodeURIComponent(artist.name.toLowerCase().trim())}`}
                                  className="tui-button cyan-168"
                                  style={{ flex: 1, textAlign: 'center' }}
                                >
                                  TRACKS
                                </Link>
                              )}
                            </div>
                          </div>
                        </fieldset>
                      </div>
                    ))}
                  </div>
                ) : (
                  <div style={{ padding: '40px', textAlign: 'center', background: '#1a1a1a' }}>
                    <p style={{ color: '#999', fontSize: '1.2em' }}>No bands in the roster yet.</p>
                  </div>
                )}

                <div style={{ marginTop: '30px', padding: '20px', background: '#0a0a0a', border: '1px solid #333' }}>
                  <h3 style={{ marginBottom: '10px', color: '#10b981' }}>[:: ABOUT SECTOR X MEDIA ::]</h3>
                  <p style={{ lineHeight: '1.6', color: '#888' }}>
                    Sector X Media represents the underground music collective broadcasting resistance through time.
                    Every artist here is part of THE PULSE GRID universe, fighting GovCorp control through
                    creativity, collaboration, and uncompromising artistic vision. From {currentYear} to {currentYear + 100}, the signal
                    continues.
                  </p>
                </div>
              </>
            )}
          </div>
        </fieldset>
      </div>
    </FmLayout>
  )
}
