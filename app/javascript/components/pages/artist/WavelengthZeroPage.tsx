import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'

const WavelengthZeroPage: React.FC = () => {
  return (
    <DefaultLayout>
      {/* Rainbow gradient border wrapper */}
      <div
        className="tui-window white-text"
        style={{
          maxWidth: '1200px',
          margin: '0 auto',
          display: 'block',
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
            <div style={{ marginBottom: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(255, 0, 128, 0.08), rgba(139, 0, 255, 0.05))', borderLeft: '5px solid #ff0080', border: '2px solid rgba(255, 0, 128, 0.3)', boxShadow: '0 0 30px rgba(255, 0, 128, 0.2), inset 0 0 20px rgba(139, 0, 255, 0.1)' }}>
              <p style={{ color: '#ff0080', lineHeight: '1.9', marginBottom: '20px', fontSize: '1.3em', fontWeight: 'bold', textShadow: '0 0 15px rgba(255, 0, 128, 0.8)' }}>
                When was the last time you felt something real?
              </p>
              <p style={{ color: '#bbb', lineHeight: '1.8', marginBottom: '18px', fontSize: '1.05em' }}>
                They've given you comfort. Safety. A world where nothing hurts because nothing touches you.
                Every edge smoothed. Every color muted to gray. Every moment of chaos filtered into calm.
              </p>
              <p style={{ color: '#aaa', lineHeight: '1.8', marginBottom: '18px' }}>
                But you remember, don't you? Before the feeds. Before the filters. Before they convinced you
                that numbness was peace.
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8', fontStyle: 'italic', fontSize: '1.1em', textShadow: '0 0 10px rgba(255, 255, 255, 0.3)' }}>
                We're here to remind you what color looks like.
              </p>
            </div>

            {/* Philosophy Section */}
            <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(139, 0, 255, 0.05)', borderLeft: '5px solid #8b00ff', border: '2px solid rgba(139, 0, 255, 0.3)', boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)' }}>
              <fieldset style={{ border: 'none' }}>
                <legend style={{ color: '#8b00ff', letterSpacing: '1px', textShadow: '0 0 15px rgba(139, 0, 255, 0.8)', fontSize: '1.1em' }}>WHAT WE OFFER</legend>

                <div style={{ padding: '20px' }}>
                  <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(255, 0, 128, 0.1), rgba(255, 140, 0, 0.05))', border: '1px solid rgba(255, 0, 128, 0.3)', borderBottom: '2px solid rgba(255, 0, 128, 0.4)' }}>
                    <h3 style={{ color: '#ff0080', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em', letterSpacing: '1px', textShadow: '0 0 10px rgba(255, 0, 128, 0.7)' }}>See</h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Bend light through a prism and watch it split. That's what we do with their lies - refract them
                      until you can see every hidden color. Gray isn't neutral. It's every wavelength dampened until
                      you can't distinguish truth from control.
                    </p>
                  </div>

                  <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(0, 217, 255, 0.1), rgba(0, 255, 0, 0.05))', border: '1px solid rgba(0, 217, 255, 0.3)', borderBottom: '2px solid rgba(0, 217, 255, 0.4)' }}>
                    <h3 style={{ color: '#00d9ff', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em', letterSpacing: '1px', textShadow: '0 0 10px rgba(0, 217, 255, 0.7)' }}>Remember</h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      They can edit your feeds. Curate your reality. Filter every input until the world fits their narrative.
                      But they can't touch what you've already felt. Your memories are the weapon they can't confiscate.
                      That ache in your chest when you think of something real? That's yours. Keep it.
                    </p>
                  </div>

                  <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(0, 255, 0, 0.1), rgba(139, 0, 255, 0.05))', border: '1px solid rgba(0, 255, 0, 0.3)', borderBottom: '2px solid rgba(0, 255, 0, 0.4)' }}>
                    <h3 style={{ color: '#00ff00', marginBottom: '10px', textTransform: 'uppercase', fontSize: '1em', letterSpacing: '1px', textShadow: '0 0 10px rgba(0, 255, 0, 0.7)' }}>Feel</h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Their monochrome world is collapsing. You can feel it in the moments when the feed glitches and
                      something raw breaks through. That chaos terrifies them - but it's real. Pain is real. Joy is real.
                      Grief, hope, rage, love - all of it more real than the comfortable gray they're selling.
                    </p>
                  </div>

                  <p style={{ color: '#ddd', marginTop: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(255, 0, 128, 0.15), rgba(139, 0, 255, 0.1))', borderLeft: '4px solid #ff0080', border: '2px solid rgba(255, 0, 128, 0.4)', lineHeight: '1.9', fontStyle: 'italic', fontSize: '1.05em', boxShadow: '0 0 20px rgba(255, 0, 128, 0.3), inset 0 0 15px rgba(139, 0, 255, 0.1)' }}>
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
                to="/f/net"
                className="tui-button"
                style={{ background: '#1a1a1a', color: '#888', border: '1px solid #333' }}
              >
                ← BACK TO FRACTURE NETWORK
              </Link>
              <Link
                to="/wavelength-zero/releases"
                className="tui-button"
                style={{ background: 'linear-gradient(90deg, #ff0080, #8b00ff)', color: 'white', fontWeight: 'bold', border: 'none' }}
              >
                RELEASES
              </Link>
              <Link
                to="/vault?filter=wavelength%20zero"
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
