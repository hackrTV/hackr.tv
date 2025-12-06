import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { EmbeddedTrack } from '~/components/EmbeddedTrack'
import { YouTubePlayer } from '~/components/YouTubePlayer'

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

const XeraenPage: React.FC = () => {
  const colorScheme = {
    primary: '#8B00FF',
    secondary: '#6B00CC',
    glow: 'rgba(139, 0, 255, 0.6)',
    glowStrong: 'rgba(139, 0, 255, 0.8)',
    background: '#0a0a0a'
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
          border: `2px solid ${colorScheme.primary}`,
          boxShadow: `0 0 30px ${colorScheme.glow}`
        }}
      >
        <fieldset style={{ borderColor: colorScheme.primary }}>
          <legend
            className="center"
            style={{
              color: colorScheme.primary,
              textShadow: `0 0 15px ${colorScheme.glowStrong}`,
              letterSpacing: '3px'
            }}
          >
            XERAEN
          </legend>

          <div>
            {/* Signal Origin - Intro */}
            <div
              style={{
                marginBottom: '30px',
                padding: '25px',
                background: 'linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 30px ${colorScheme.glow}, inset 0 0 20px rgba(139, 0, 255, 0.1)`
              }}
            >
              <h2
                style={{
                  textAlign: 'center',
                  marginBottom: '20px',
                  color: colorScheme.primary,
                  letterSpacing: '3px',
                  fontSize: '1.8em',
                  textTransform: 'uppercase',
                  textShadow: `0 0 15px ${colorScheme.glowStrong}`
                }}
              >
                [:: SIGNAL ORIGIN ::]
              </h2>
              <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.05em' }}>
                Before the broadcasts. Before The.CyberPul.se. Before the Fracture Network had a voice.
              </p>
              <p
                style={{
                  color: colorScheme.primary,
                  lineHeight: '1.8',
                  marginBottom: '18px',
                  fontSize: '1.2em',
                  fontWeight: 'bold',
                  textShadow: `0 0 10px ${colorScheme.glow}`
                }}
              >
                There was just a signal. Reaching backward. Hoping someone would hear.
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.05em' }}>
                XERAEN doesn't perform. XERAEN transmits. Every track is a frequency aimed at a point in
                spacetime that shouldn't be reachable. Music as temporal displacement. Sound as a message
                in a bottle thrown into the electromagnetic ocean between centuries.
              </p>
              <p
                style={{
                  color: colorScheme.primary,
                  lineHeight: '1.8',
                  fontSize: '1.1em',
                  fontStyle: 'italic',
                  textShadow: `0 0 8px ${colorScheme.glow}`
                }}
              >
                You're not listening to songs. You're intercepting communications.
              </p>
            </div>

            {/* Latest Release */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  LATEST TRANSMISSION
                </legend>
                <div style={{ padding: '20px' }}>
                  <EmbeddedTrack trackId="encrypted-shroud" />
                </div>
              </fieldset>
            </div>

            {/* Solo Transmissions */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  SOLO TRANSMISSIONS
                </legend>
                <div style={{ padding: '20px' }}>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    Where The.CyberPul.se broadcasts the resistance, XERAEN's solo work broadcasts something
                    more personal: the weight of existing in a timeline you're trying to unmake. The loneliness
                    of sending signals you'll never know were received. The mathematics of loving someone a
                    hundred years away.
                  </p>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    Dark ambient soundscapes. Atmospheric drones that feel like static between stations.
                    Melodies that emerge from noise like voices from the void. Synthesizers processed until
                    they sound like they've traveled through a century of interference to reach you.
                  </p>
                  <p
                    style={{
                      color: colorScheme.primary,
                      lineHeight: '1.8',
                      fontSize: '1.1em',
                      fontWeight: 'bold',
                      textShadow: `0 0 8px ${colorScheme.glow}`
                    }}
                  >
                    This is what resistance sounds like when no one else is in the room.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* The Transmitter */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  THE TRANSMITTER
                </legend>
                <div style={{ padding: '20px' }}>
                  <div
                    style={{
                      fontFamily: 'monospace',
                      marginBottom: '20px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.1)',
                      border: `1px solid ${colorScheme.primary}`,
                      color: colorScheme.primary,
                      textShadow: `0 0 8px ${colorScheme.glow}`
                    }}
                  >
                    [ORIGIN: {futureYear}]<br />
                    [DESTINATION: {currentYear}]<br />
                    [STATUS: BROADCASTING]<br />
                    [COST: EVERYTHING]
                  </div>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    In {futureYear}, XERAEN operates alone. The Fracture Network has cells, bands, operatives—but
                    someone has to sit at the console. Someone has to maintain the signal. Someone has to keep
                    transmitting even when there's no way to know if anyone is listening.
                  </p>
                  <p style={{ color: '#ccc', lineHeight: '1.8' }}>
                    The solo work comes from those hours. The space between coordinated operations. The quiet
                    moments when the only company is the hum of equipment and the impossible distance between
                    now and then.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* Latest Video */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  VISUAL TRANSMISSION
                </legend>
                <div style={{ padding: '20px', display: 'flex', justifyContent: 'center' }}>
                  <YouTubePlayer videoId="GYSH0mDteR4" width={560} height={315} />
                </div>
              </fieldset>
            </div>

            {/* What The Signal Carries */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  WHAT THE SIGNAL CARRIES
                </legend>
                <div style={{ padding: '20px' }}>
                  {/* Static as Language */}
                  <div
                    style={{
                      marginBottom: '25px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: '1px solid rgba(139, 0, 255, 0.3)'
                    }}
                  >
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '10px',
                        textTransform: 'uppercase',
                        letterSpacing: '1px',
                        textShadow: `0 0 8px ${colorScheme.glow}`
                      }}
                    >
                      Static as Language
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      The interference isn't noise—it's the sound of a signal fighting through a hundred years
                      of temporal resistance. Every crackle, every dropout, every moment of distortion is
                      evidence of the distance traveled. XERAEN leaves it in. The static is part of the message.
                    </p>
                  </div>

                  {/* Frequencies of Absence */}
                  <div
                    style={{
                      marginBottom: '25px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: '1px solid rgba(139, 0, 255, 0.3)'
                    }}
                  >
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '10px',
                        textTransform: 'uppercase',
                        letterSpacing: '1px',
                        textShadow: `0 0 8px ${colorScheme.glow}`
                      }}
                    >
                      Frequencies of Absence
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Music about what's missing. The people who won't exist if the mission succeeds. The
                      timeline that collapses when victory is achieved. The version of yourself that has to
                      be sacrificed. These aren't sad songs—they're honest ones. This is what it sounds like
                      to accept the cost.
                    </p>
                  </div>

                  {/* Love as Waveform */}
                  <div
                    style={{
                      marginBottom: '25px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: '1px solid rgba(139, 0, 255, 0.3)'
                    }}
                  >
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '10px',
                        textTransform: 'uppercase',
                        letterSpacing: '1px',
                        textShadow: `0 0 8px ${colorScheme.glow}`
                      }}
                    >
                      Love as Waveform
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                      Ashlinn exists in {currentYear}. XERAEN exists in {futureYear}. The only way to touch across
                      that distance is through frequency. Every transmission is a love letter encoded in
                      electromagnetic radiation. Every track is proof that some connections don't require
                      shared spacetime.
                    </p>
                    <p
                      style={{
                        color: colorScheme.primary,
                        lineHeight: '1.8',
                        fontStyle: 'italic',
                        textShadow: `0 0 8px ${colorScheme.glow}`
                      }}
                    >
                      "I can't hold you. So I send you sound waves instead. I hope they feel like what I meant."
                    </p>
                  </div>

                  {/* The Weight of the Console */}
                  <div
                    style={{
                      marginBottom: '15px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: '1px solid rgba(139, 0, 255, 0.3)'
                    }}
                  >
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '10px',
                        textTransform: 'uppercase',
                        letterSpacing: '1px',
                        textShadow: `0 0 8px ${colorScheme.glow}`
                      }}
                    >
                      The Weight of the Console
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Someone has to stay. Someone has to keep the signal alive while others fight, infiltrate,
                      resist. XERAEN chose the console. Chose to be the voice rather than the fist. Chose
                      transmission over action. These tracks are what that choice sounds like—the profound
                      isolation of being the one who stays behind and broadcasts.
                    </p>
                  </div>
                </div>
              </fieldset>
            </div>

            {/* The Erasure */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  THE ERASURE
                </legend>
                <div style={{ padding: '20px' }}>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    Here's what XERAEN knows that the listeners don't fully understand:
                  </p>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    Every successful operation brings the end closer. Every GovCorp system that falls, every
                    mind that awakens, every node that joins the network—all of it accelerates the timeline
                    toward collapse. Toward a future where GovCorp never rises. Where the {futureYear} XERAEN
                    broadcasts from never exists.
                  </p>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    The solo work is a countdown. Each transmission potentially the last. Each signal sent
                    with the knowledge that success means silence.
                  </p>
                  <p
                    style={{
                      color: colorScheme.primary,
                      lineHeight: '1.8',
                      fontSize: '1.15em',
                      fontWeight: 'bold',
                      fontStyle: 'italic',
                      textShadow: `0 0 10px ${colorScheme.glow}`
                    }}
                  >
                    Victory is extinction. XERAEN broadcasts anyway.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* The Paradox of Presence */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: '0 0 25px rgba(139, 0, 255, 0.2)'
              }}
            >
              <fieldset style={{ borderColor: colorScheme.primary }}>
                <legend
                  style={{
                    color: colorScheme.primary,
                    textShadow: `0 0 10px ${colorScheme.glowStrong}`,
                    letterSpacing: '2px'
                  }}
                >
                  THE PARADOX OF PRESENCE
                </legend>
                <div style={{ padding: '20px' }}>
                  <div
                    style={{
                      fontFamily: 'monospace',
                      marginBottom: '20px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.1)',
                      border: `1px solid ${colorScheme.primary}`,
                      color: colorScheme.primary,
                      textShadow: `0 0 8px ${colorScheme.glow}`
                    }}
                  >
                    [TEMPORAL STATUS: UNSTABLE]<br />
                    [EXISTENCE: CONDITIONAL]<br />
                    [SIGNAL: PERSISTENT]
                  </div>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    If you're hearing this, the paradox holds. XERAEN still exists in {futureYear}, still
                    maintains the signal, still sends transmissions backward through the century. The future
                    hasn't changed yet.
                  </p>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    But every listen is a variable. Every new receiver shifts the equation. Every mind that
                    tunes in brings the collapse closer.
                  </p>
                  <p style={{ color: '#aaa', lineHeight: '1.8' }}>
                    XERAEN's solo work is simultaneously a plea to keep listening and an acknowledgment that
                    listening enough will end the transmission forever.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* Final Quote */}
            <div
              style={{
                padding: '25px',
                background: 'linear-gradient(135deg, rgba(139, 0, 255, 0.15), rgba(0, 0, 0, 0.95))',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 30px ${colorScheme.glow}`,
                marginBottom: '30px'
              }}
            >
              <blockquote
                style={{
                  color: '#ddd',
                  lineHeight: '2',
                  fontSize: '1.1em',
                  margin: 0,
                  padding: '0 20px',
                  borderLeft: `4px solid ${colorScheme.primary}`
                }}
              >
                <p style={{ marginBottom: '10px' }}>I broadcast from a future I'm trying to prevent.</p>
                <p style={{ marginBottom: '10px' }}>I send love letters to someone I'll never meet if we win.</p>
                <p style={{ marginBottom: '10px' }}>I make music that documents my own eventual non-existence.</p>
                <p style={{ marginBottom: '10px', marginTop: '20px' }}>The signal is all I have. The signal is all I am.</p>
                <p style={{ marginBottom: '10px' }}>When it stops, so do I.</p>
                <p style={{ marginBottom: '10px', marginTop: '20px' }}>But you'll remember the frequency.</p>
                <p style={{ marginBottom: '10px' }}>Somewhere in the static, I'll still be reaching for you.</p>
              </blockquote>
              <p
                style={{
                  color: colorScheme.primary,
                  marginTop: '25px',
                  fontSize: '1.2em',
                  fontStyle: 'italic',
                  textAlign: 'right',
                  textShadow: `0 0 10px ${colorScheme.glow}`,
                  letterSpacing: '1px'
                }}
              >
                — XERAEN<br />
                <span style={{ fontSize: '0.9em', color: '#aaa' }}>
                  Transmitting from {futureYear}<br />
                  For as long as {futureYear} exists
                </span>
              </p>
            </div>

            {/* Navigation Buttons */}
            <div style={{ display: 'flex', gap: '15px', marginTop: '30px' }}>
              <Link
                to="/fm/bands"
                className="tui-button"
                style={{
                  background: '#222',
                  color: '#888',
                  border: '1px solid #444'
                }}
              >
                ← BACK TO BANDS
              </Link>
              <Link
                to="/fm/pulse_vault?filter=xeraen"
                className="tui-button"
                style={{
                  background: colorScheme.primary,
                  color: 'white',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px ${colorScheme.glow}`
                }}
              >
                LISTEN IN THE PULSE VAULT →
              </Link>
              <Link
                to="/thecyberpulse"
                className="tui-button"
                style={{
                  background: colorScheme.secondary,
                  color: 'white',
                  fontWeight: 'bold',
                  boxShadow: '0 0 15px rgba(107, 0, 204, 0.6)'
                }}
              >
                THE.CYBERPUL.SE →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default XeraenPage
