import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

interface Track {
  id: number
  title: string
  duration: string | null
}

interface Artist {
  id: number
  name: string
  slug: string
  tracks: Track[]
}

const WavelengthZeroPage: React.FC = () => {
  const [artist, setArtist] = useState<Artist | null>(null)

  useEffect(() => {
    fetch('/api/artists/wavelength_zero')
      .then(res => res.json())
      .then(data => {
        setArtist(data)
      })
      .catch(error => {
        console.error('Error fetching artist:', error)
      })
  }, [])

  const tracks = artist?.tracks || []
  const rainbowColors = ['#ff0080', '#ff8c00', '#00ff00', '#00d9ff', '#8b00ff']

  return (
    <DefaultLayout>
      {/* Rainbow gradient border wrapper */}
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          background: '#0a0a0a',
          border: '3px solid transparent',
          backgroundImage: 'linear-gradient(#0a0a0a, #0a0a0a), linear-gradient(90deg, #ff0080, #ff8c00, #ffed00, #00ff00, #00d9ff, #8b00ff)',
          backgroundOrigin: 'border-box',
          backgroundClip: 'padding-box, border-box'
        }}
      >
        <fieldset style={{ border: 'none' }}>
          {/* Rainbow gradient text legend */}
          <legend
            className="center"
            style={{
              background: 'linear-gradient(90deg, #ff0080, #ff8c00, #ffed00, #00ff00, #00d9ff, #8b00ff)',
              WebkitBackgroundClip: 'text',
              WebkitTextFillColor: 'transparent',
              backgroundClip: 'text',
              fontSize: '1.5em',
              fontWeight: 'bold'
            }}
          >
            WAVELENGTH ZERO
          </legend>

          <div>
            {/* Intro Section */}
            <div style={{ marginBottom: '30px', padding: '25px', background: '#000000', borderLeft: '5px solid #ff0080' }}>
              <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.1em' }}>
                When was the last time you felt something real?
              </p>
              <p style={{ color: '#aaa', lineHeight: '1.7', marginBottom: '15px' }}>
                They've given you comfort. Safety. A world where nothing hurts because nothing touches you.
                Every edge smoothed. Every color muted to gray. Every moment of chaos filtered into calm.
              </p>
              <p style={{ color: '#aaa', lineHeight: '1.7', marginBottom: '15px' }}>
                But you remember, don't you? Before the feeds. Before the filters. Before they convinced you
                that numbness was peace.
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.7', fontStyle: 'italic' }}>
                We're here to remind you what color looks like.
              </p>
            </div>

            {/* Album Section */}
            {tracks.length > 0 && (
              <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', borderLeft: '5px solid #00d9ff' }}>
                <fieldset style={{ border: '1px solid #333' }}>
                  <legend style={{ color: '#00d9ff' }}>ZERO LIGHT EP</legend>

                  <div style={{ padding: '20px' }}>
                    <div style={{ marginBottom: '20px' }}>
                      <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                        Five songs. Each one a prism breaking their manufactured darkness into the full spectrum
                        they've been hiding from you.
                      </p>
                      <p style={{ color: '#888', lineHeight: '1.7' }}>
                        They called it <span style={{ color: '#00d9ff' }}>Zero Light</span>—their perfect world with no shadows because
                        there's no light to cast them. We took their name and split it open. Inside their darkness,
                        we found every color they said didn't exist anymore.
                      </p>
                    </div>

                    <div className="tui-fieldset" style={{ borderColor: '#333' }}>
                      <legend style={{ color: '#888' }}>TRACKS</legend>
                      <table className="tui-table" style={{ width: '100%' }}>
                        <thead>
                          <tr>
                            <th style={{ textAlign: 'left', color: '#666' }}>#</th>
                            <th style={{ textAlign: 'left', color: '#888' }}>Track</th>
                            <th style={{ textAlign: 'left', color: '#666' }}>Duration</th>
                          </tr>
                        </thead>
                        <tbody>
                          {tracks.map((track, index) => (
                            <tr key={track.id} style={{ borderLeft: `3px solid ${rainbowColors[index % rainbowColors.length]}` }}>
                              <td style={{ color: '#666', paddingLeft: '10px' }}>{index + 1}</td>
                              <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                              <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </fieldset>
              </div>
            )}

            {/* Philosophy Section */}
            <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', borderLeft: '5px solid #8b00ff' }}>
              <fieldset style={{ border: '1px solid #333' }}>
                <legend style={{ color: '#8b00ff' }}>WHAT WE OFFER</legend>

                <div style={{ padding: '20px' }}>
                  <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid #222' }}>
                    <h3 style={{ color: '#ff0080', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em' }}>See</h3>
                    <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                      Bend light through a prism and watch it split. That's what we do with their lies—refract them
                      until you can see every hidden color. Gray isn't neutral. It's every wavelength dampened until
                      you can't distinguish truth from control.
                    </p>
                  </div>

                  <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid #222' }}>
                    <h3 style={{ color: '#00d9ff', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em' }}>Remember</h3>
                    <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                      They can edit your feeds. Curate your reality. Filter every input until the world fits their narrative.
                      But they can't touch what you've already felt. Your memories are the weapon they can't confiscate.
                      That ache in your chest when you think of something real? That's yours. Keep it.
                    </p>
                  </div>

                  <div style={{ marginBottom: '25px' }}>
                    <h3 style={{ color: '#00ff00', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em' }}>Feel</h3>
                    <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                      Their monochrome world is collapsing. You can feel it in the moments when the feed glitches and
                      something raw breaks through. That chaos terrifies them—but it's real. Pain is real. Joy is real.
                      Grief, hope, rage, love—all of it more real than the comfortable gray they're selling.
                    </p>
                  </div>

                  <p style={{ color: '#ddd', marginTop: '30px', padding: '20px', background: '#000000', borderLeft: '3px solid #ff0080', lineHeight: '1.8', fontStyle: 'italic' }}>
                    We're not asking you to fight.<br />
                    We're asking you to feel something.<br />
                    Everything else follows.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* Navigation Buttons */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to="/fm/bands"
                className="tui-button"
                style={{ background: '#1a1a1a', color: '#888', border: '1px solid #333' }}
              >
                ← BACK TO BANDS
              </Link>
              <Link
                to="/fm/pulse_vault?filter=wavelength%20zero"
                className="tui-button"
                style={{ background: 'linear-gradient(90deg, #ff0080, #8b00ff)', color: 'white', fontWeight: 'bold', border: 'none' }}
              >
                LISTEN IN THE PULSE VAULT →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default WavelengthZeroPage
