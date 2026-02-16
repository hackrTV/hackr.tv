import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { FmLayout } from '~/components/layouts/FmLayout'
import { LoadingSpinner } from '~/components/shared/LoadingSpinner'
import { useMobileDetect } from '~/hooks/useMobileDetect'
import { apiJson } from '~/utils/apiClient'
import { getArtistProfilePath } from '~/utils/artistPaths'

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
  const { isMobile } = useMobileDetect()

  useEffect(() => {
    apiJson<Artist[]>('/api/artists')
      .then(data => {
        const sorted = [...data].sort((a: Artist, b: Artist) =>
          a.name.toLowerCase().localeCompare(b.name.toLowerCase())
        )
        setArtists(sorted)
        setLoading(false)
      })
      .catch(err => {
        setError(err instanceof Error ? err.message : 'Unknown error')
        setLoading(false)
      })
  }, [])

  const currentYear = new Date().getFullYear()

  const getProfilePath = getArtistProfilePath

  const getBandDescription = (slug: string): string => {
    const futureYear = currentYear + 100
    const descriptions: { [key: string]: string } = {
      'thecyberpulse': `The original Fracture Network band, forging metal manifestos from ${futureYear} with brutal precision.`,
      'xeraen': 'OMNIWAVE Genesis Vector - Electronic exploration with rhythmic guitars',
      'injection-vector': 'Physical infiltration specialists. When stealth fails, deathcore brutality prevails.',
      'wavelength-zero': 'Where technical precision meets raw emotion in perfect destructive atmospheric harmony.',
      'cipher-protocol': 'Data couriers wielding djent as encryption. No vocals. Pure instrumental algorithmic assault.',
      'system-rot': 'Decay is the message. Entropy is the method. Hardcore punk collapse is inevitable.',
      'temporal-blue-drift': 'Math rock time travelers proving complexity is the most beautiful form of resistance.',
      'offline': 'Unplugged, authentic, and gloriously disconnected from the grid. Analog hearts never die.',
      'apex-overdrive': 'Euphoric hardstyle, honed into a weapon. Promoting unity as power. Victory coded into every beat.',
      'voiceprint': 'Liquid DnB resistance. Your voice is your weapon, your identity eternally unbreakable.',
      'neon-hearts': 'Kawaii camouflage hiding radical resistance. J-Pop cuteness is the ultimate Trojan horse.',
      'ethereality': 'Consciousness expansion through classic vocal trance. Inner freedom transcends all control.',
      'blitzbeam': 'Maximum velocity hypertrance. SPEED IS LIFE! Physics are merely suggestions.',
      'heartbreak-havoc': 'Weaponized heartbreak at Nightcore speed. Corrupting RIDE nodes with overclocked romantic chaos.'
    }
    return descriptions[slug] || 'Broadcasting resistance through sound.'
  }

  return (
    <FmLayout>
      <div className="tui-window white-text" style={{ maxWidth: isMobile ? '100%' : '1400px', margin: '0 auto', display: 'block', background: '#1a1a1a', border: '2px solid #666' }}>
        <fieldset style={{ borderColor: '#666' }}>
          <legend className="center" style={{ color: '#10b981' }}>{isMobile ? 'BANDS' : 'hackr.fm :: BANDS'}</legend>

          <div>
            <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#10b981' }}>
              [:: FRACTURE NETWORK BANDS ::]
            </h2>

            {loading && <LoadingSpinner message="Loading Fracture Network bands..." color="green-255-text" />}

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
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fit, minmax(400px, 1fr))',
                    gap: isMobile ? '15px' : '20px'
                  }}>
                    {artists.map((artist) => (
                      <div key={artist.id} className="tui-window white-text" style={{ background: '#0d0d0d', border: '1px solid #444' }}>
                        <fieldset style={{ borderColor: '#555' }}>
                          <legend style={{ color: '#10b981' }}>{artist.name.toUpperCase()}</legend>

                          <div style={{ padding: isMobile ? '10px' : '15px' }}>
                            <div style={{ marginBottom: isMobile ? '12px' : '20px' }}>
                              <p style={{ color: '#aaa', lineHeight: '1.6', fontStyle: 'italic', fontSize: isMobile ? '0.9em' : '1em' }}>
                                {getBandDescription(artist.slug)}
                              </p>
                            </div>

                            <div style={{ marginBottom: '15px', padding: '10px', background: '#0a0a0a', border: '1px solid #333' }}>
                              <p style={{ color: '#666', fontSize: '0.85em' }}>
                                <span style={{ color: '#888', fontWeight: 'bold' }}>{artist.genre}</span> • {artist.track_count} tracks
                              </p>
                            </div>

                            <div style={{ marginTop: isMobile ? '12px' : '20px', display: 'flex', gap: '10px' }}>
                              {getProfilePath(artist.slug) ? (
                                <Link
                                  to={getProfilePath(artist.slug)}
                                  className="tui-button purple-168"
                                  style={{ flex: 1, textAlign: 'center', fontSize: isMobile ? '0.85em' : '1em' }}
                                >
                                  {isMobile ? 'PROFILE' : 'VIEW PROFILE'}
                                </Link>
                              ) : (
                                <button
                                  className="tui-button"
                                  style={{ flex: 1, opacity: 0.5, cursor: 'not-allowed', fontSize: isMobile ? '0.85em' : '1em' }}
                                  disabled
                                >
                                  SOON
                                </button>
                              )}

                              <Link
                                to={`/${artist.slug}/releases`}
                                className="tui-button cyan-168"
                                style={{ flex: 1, textAlign: 'center', fontSize: isMobile ? '0.85em' : '1em' }}
                              >
                                RELEASES
                              </Link>
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
                  <h3 style={{ marginBottom: '10px', color: '#10b981' }}>[:: ABOUT THE FRACTURE NETWORK ::]</h3>
                  <p style={{ lineHeight: '1.6', color: '#888' }}>
                    These bands broadcast resistance through time under the loose banner of the Fracture Network.
                    Every artist here is connected to THE PULSE GRID, fighting GovCorp control through
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
