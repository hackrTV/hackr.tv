import React from 'react'
import { Link } from 'react-router-dom'
import { DefaultLayout } from '~/components/layouts/DefaultLayout'
import { YouTubePlayer } from '~/components/YouTubePlayer'

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

const TheCyberPulsePage: React.FC = () => {
  const colorScheme = {
    primary: '#8B00FF',
    secondary: '#9B59B6',
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
            THE.CYBERPUL.SE
          </legend>

          <div>
            {/* Signal Incoming - Intro */}
            <div
              style={{
                marginBottom: '30px',
                padding: '25px',
                background: `linear-gradient(135deg, rgba(139, 0, 255, 0.08), rgba(0, 0, 0, 0.95))`,
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
                [:: SIGNAL INCOMING ::]
              </h2>
              <p
                style={{
                  color: colorScheme.primary,
                  lineHeight: '1.8',
                  marginBottom: '18px',
                  fontSize: '1.3em',
                  fontWeight: 'bold',
                  textShadow: `0 0 10px ${colorScheme.glow}`
                }}
              >
                You're not supposed to be hearing this.
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.05em' }}>
                This frequency shouldn't exist. This signal is being broadcast from a timeline GovCorp has spent a
                century trying to prevent. And yet—here we are. Here <em>you</em> are. Listening.
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8', fontSize: '1.05em' }}>
                The.CyberPul.se is the central nervous system of the Fracture Network. Not a band. Not a channel.
                A heartbeat transmitted backward through time from {futureYear} to {currentYear}—a hundred years of
                resistance compressed into electromagnetic pulses you're decoding right now.
              </p>
              <p
                style={{
                  color: colorScheme.primary,
                  lineHeight: '1.8',
                  marginTop: '20px',
                  fontSize: '1.15em',
                  fontWeight: 'bold',
                  textShadow: `0 0 8px ${colorScheme.glow}`
                }}
              >
                Welcome to hackr.tv. The signal is live. The pulse is strong.
              </p>
            </div>

            {/* Video Section */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  TRANSMISSION
                </legend>
                <div style={{ padding: '20px', display: 'flex', justifyContent: 'center' }}>
                  <YouTubePlayer videoId="MWSjCJQhr1o" width={560} height={315} />
                </div>
              </fieldset>
            </div>

            {/* The Broadcast */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  THE BROADCAST
                </legend>
                <div style={{ padding: '20px' }}>
                  <p
                    style={{
                      color: colorScheme.primary,
                      marginBottom: '20px',
                      fontSize: '1.2em',
                      fontWeight: 'bold',
                      textShadow: `0 0 8px ${colorScheme.glow}`
                    }}
                  >
                    24/7. No dead air. No commercial breaks. No corporate sponsorship.
                  </p>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    What you'll find here: ten resistance bands transmitting their frequencies through our signal.
                    Live operations against GovCorp infrastructure. Interactive coordination through THE PULSE GRID.
                    A community of listeners who've become operators, viewers who've become fighters, audience members
                    who've realized they were always part of the show.
                  </p>
                  <p
                    style={{
                      color: colorScheme.secondary,
                      lineHeight: '1.8',
                      fontSize: '1.1em',
                      fontWeight: 'bold',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.1)',
                      borderLeft: `4px solid ${colorScheme.primary}`
                    }}
                  >
                    This isn't entertainment. This is a recruitment broadcast disguised as a streaming platform.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* The Hosts - XERAEN & RYKER */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  THE HOSTS
                </legend>
                <div style={{ padding: '20px' }}>
                  {/* XERAEN */}
                  <div style={{ marginBottom: '30px' }}>
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '15px',
                        fontSize: '1.4em',
                        letterSpacing: '3px',
                        textShadow: `0 0 10px ${colorScheme.glow}`
                      }}
                    >
                      XERAEN
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                      He broadcasts from {futureYear}—from a future where GovCorp has won, where RAINNs have replaced
                      authentic human expression, where The Fracture Network fights a war most people don't know is
                      happening.
                    </p>
                    <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                      XERAEN sends signals backward through time. Not to warn you. Not to save you. To <em>activate</em> you.
                    </p>
                    <p style={{ color: '#aaa', lineHeight: '1.8', marginBottom: '15px' }}>
                      Every transmission you receive has already happened in his timeline. Every attack you witness
                      is history to him—but to you, it's still possible. Still changeable. The paradox is the point:
                      he's broadcasting from a future he's trying to prevent.
                    </p>
                    <p style={{ color: '#bbb', lineHeight: '1.8', marginBottom: '15px' }}>
                      If The Fracture Network succeeds, XERAEN's timeline collapses. He ceases to exist. The broadcasts
                      stop because there's nothing left to broadcast from.
                    </p>
                    <p
                      style={{
                        color: colorScheme.primary,
                        lineHeight: '1.8',
                        fontSize: '1.1em',
                        fontStyle: 'italic',
                        textShadow: `0 0 8px ${colorScheme.glow}`,
                        padding: '15px',
                        background: 'rgba(139, 0, 255, 0.1)',
                        borderLeft: `4px solid ${colorScheme.primary}`
                      }}
                    >
                      He fights knowing victory means erasure.
                    </p>
                  </div>

                  {/* Divider */}
                  <hr style={{ border: 'none', borderTop: `1px solid ${colorScheme.primary}`, margin: '30px 0', opacity: 0.5 }} />

                  {/* RYKER M. PULSE */}
                  <div>
                    <h3
                      style={{
                        color: colorScheme.primary,
                        marginBottom: '15px',
                        fontSize: '1.4em',
                        letterSpacing: '3px',
                        textShadow: `0 0 10px ${colorScheme.glow}`
                      }}
                    >
                      RYKER M. PULSE
                    </h3>
                    <p
                      style={{
                        color: colorScheme.secondary,
                        lineHeight: '1.8',
                        marginBottom: '15px',
                        fontSize: '1.1em',
                        fontWeight: 'bold'
                      }}
                    >
                      If XERAEN is the signal, Ryker is the heartbeat.
                    </p>
                    <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                      Co-founder. Primary drummer. The voice that cuts through static and demands you <em>move</em>.
                      While XERAEN works the code and maintains the transmission, Ryker brings the kinetic energy
                      that turns broadcasts into rallying cries.
                    </p>
                    <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                      His drums don't keep time—they <em>drive</em> it. Every beat is a countdown. Every rhythm is
                      a call to action. When Ryker's voice comes through the signal, it's not a whisper from the
                      future. It's a shout. A challenge. A reminder that resistance isn't passive.
                    </p>
                    <p style={{ color: '#aaa', lineHeight: '1.8', marginBottom: '15px' }}>
                      XERAEN sends the signal. Ryker makes sure it hits like a fist.
                    </p>
                    <p style={{ color: '#bbb', lineHeight: '1.8', marginBottom: '15px' }}>
                      Where XERAEN embodies the solitary weight of maintaining hope across impossible distances,
                      Ryker embodies collective defiance. Unity through action. The belief that every small choice
                      ripples forward—or in their case, backward—shaping futures that haven't been written yet.
                    </p>
                    <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                      He knows the math. He knows that success means erasure. He drums anyway. Louder. Faster.
                      Like he's trying to leave dents in the timeline itself.
                    </p>
                    <p
                      style={{
                        color: colorScheme.primary,
                        lineHeight: '1.8',
                        fontSize: '1.1em',
                        fontStyle: 'italic',
                        textShadow: `0 0 8px ${colorScheme.glow}`,
                        padding: '15px',
                        background: 'rgba(139, 0, 255, 0.1)',
                        borderLeft: `4px solid ${colorScheme.primary}`
                      }}
                    >
                      Some people whisper revolution. Ryker beats it into existence.
                    </p>
                  </div>
                </div>
              </fieldset>
            </div>

            {/* The Pulse Grid */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  THE PULSE GRID
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
                    [CONNECTION: ACTIVE]<br />
                    [NODES: EXPANDING]<br />
                    [STATUS: SYNCHRONIZED]
                  </div>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    More than a game. Less than a simulation. THE PULSE GRID is how the Fracture Network coordinates
                    across timelines—a MUD interface where operators train, plan, and execute. What looks like a text
                    adventure is actually resistance infrastructure.
                  </p>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    Every zone corresponds to real GovCorp territory. Every puzzle mirrors actual security protocols.
                    Every player who masters the grid becomes capable of navigating its real-world equivalent.
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
                    You thought you were playing. You were preparing.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* What We Transmit */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  WHAT WE TRANSMIT
                </legend>
                <div style={{ padding: '20px' }}>
                  {/* The Bands */}
                  <div
                    style={{
                      marginBottom: '25px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: `1px solid rgba(139, 0, 255, 0.3)`
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
                      The Bands
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Ten frequencies. Ten approaches to resistance. From Injection Vector's kinetic warfare to
                      Ethereality's transcendent liberation—each band represents a node in the network, a tactic in
                      the arsenal, a way of fighting that speaks to different souls.
                    </p>
                    <p style={{ color: '#aaa', lineHeight: '1.8', marginTop: '10px' }}>
                      We don't tell you which frequency to tune to. We broadcast them all. You find the signal that
                      resonates with your resistance.
                    </p>
                  </div>

                  {/* The Operations */}
                  <div
                    style={{
                      marginBottom: '25px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: `1px solid rgba(139, 0, 255, 0.3)`
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
                      The Operations
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Live attacks against GovCorp systems. Real-time infiltration of corporate infrastructure.
                      Interactive missions where the audience doesn't just watch—they participate. Every livestream
                      is an operation. Every viewer is potentially an operator.
                    </p>
                  </div>

                  {/* The Signal */}
                  <div
                    style={{
                      marginBottom: '15px',
                      padding: '15px',
                      background: 'rgba(139, 0, 255, 0.05)',
                      border: `1px solid rgba(139, 0, 255, 0.3)`
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
                      The Signal
                    </h3>
                    <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                      Purple light cutting through their manufactured darkness. A frequency they can't jam because
                      it's not coming from anywhere they can locate. We exist in the space between their surveillance
                      systems, in the temporal gap their algorithms can't process.
                    </p>
                    <p style={{ color: '#aaa', lineHeight: '1.8', marginTop: '10px' }}>
                      They know we're broadcasting. They just can't figure out <em>when</em> we're broadcasting from.
                    </p>
                  </div>
                </div>
              </fieldset>
            </div>

            {/* The Paradox */}
            <div
              className="tui-window white-text"
              style={{
                marginBottom: '30px',
                background: '#000000',
                border: `2px solid ${colorScheme.primary}`,
                boxShadow: `0 0 25px rgba(139, 0, 255, 0.2)`
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
                  THE PARADOX
                </legend>
                <div style={{ padding: '20px' }}>
                  <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                    Here's what keeps GovCorp's strategists awake:
                  </p>
                  <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
                    If they stop us in {futureYear}, the broadcasts have already been sent to {currentYear}. If they stop
                    the listeners in {currentYear}, the resistance in {futureYear} has already formed. We exist in both
                    timelines simultaneously—a signal that's already arrived and a future that hasn't happened yet.
                  </p>
                  <p
                    style={{
                      color: colorScheme.primary,
                      lineHeight: '1.8',
                      fontSize: '1.15em',
                      fontWeight: 'bold',
                      textShadow: `0 0 10px ${colorScheme.glow}`
                    }}
                  >
                    Causality is a prison. We broke out.
                  </p>
                </div>
              </fieldset>
            </div>

            {/* Final Call to Action */}
            <div
              style={{
                padding: '25px',
                background: `linear-gradient(135deg, rgba(139, 0, 255, 0.15), rgba(0, 0, 0, 0.95))`,
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
                <p style={{ marginBottom: '10px' }}>You found this signal for a reason.</p>
                <p style={{ marginBottom: '10px' }}>
                  You're hearing this broadcast because somewhere in the electromagnetic spectrum between {currentYear} and {futureYear},
                  your frequency matched ours.
                </p>
                <p style={{ marginBottom: '10px' }}>The pulse is strong. The signal is live. The network is expanding.</p>
              </blockquote>
              <p
                style={{
                  color: colorScheme.primary,
                  marginTop: '25px',
                  fontSize: '1.4em',
                  fontWeight: 'bold',
                  textAlign: 'center',
                  textShadow: `0 0 15px ${colorScheme.glowStrong}`,
                  letterSpacing: '2px'
                }}
              >
                This is The.CyberPul.se.<br />
                <em>Welcome to the resistance.</em>
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
                to="/fm/pulse_vault?filter=the.cyberpul.se"
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
                to="/grid"
                className="tui-button"
                style={{
                  background: colorScheme.secondary,
                  color: 'white',
                  fontWeight: 'bold',
                  boxShadow: `0 0 15px rgba(155, 89, 182, 0.6)`
                }}
              >
                ENTER THE PULSE GRID →
              </Link>
            </div>
          </div>
        </fieldset>
      </div>
    </DefaultLayout>
  )
}

export default TheCyberPulsePage
