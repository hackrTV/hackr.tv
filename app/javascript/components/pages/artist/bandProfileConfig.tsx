import React from 'react'

interface Track {
  id: number
  title: string
  track_number: number | null
  duration: string | null
}

interface ColorScheme {
  primary: string
  border?: string
  legend?: string
  background?: string
  button?: string
  buttonBorder?: string
  gradient?: string
}

interface BandProfileConfig {
  name: string
  colorScheme: ColorScheme
  filterName: string
  renderIntro: () => React.ReactNode
  renderAlbumSection: (tracks: Track[]) => React.ReactNode
  renderPhilosophy: () => React.ReactNode
}

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

export const bandProfiles: Record<string, BandProfileConfig> = {
  system_rot: {
    name: 'System Rot',
    colorScheme: {
      primary: '#39ff14',
      border: '#39ff14',
      legend: '#39ff14',
      background: '#0a0a0a',
      button: '#39ff14',
      button_text: '#000',
      back_button: '#222',
      back_border: '#444'
    },
    filterName: 'system rot',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(57, 255, 20, 0.05), rgba(0, 0, 0, 0.95))', border: '2px solid #39ff14', boxShadow: '0 0 30px rgba(57, 255, 20, 0.3), inset 0 0 20px rgba(57, 255, 20, 0.1)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '20px', color: '#39ff14', letterSpacing: '3px', fontSize: '1.8em', textTransform: 'uppercase', textShadow: '0 0 15px rgba(57, 255, 20, 0.8)' }}>
          [:: WE WERE HERE ::]
        </h2>
        <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px', fontSize: '1.1em', fontWeight: 'bold' }}>
          You want beautiful resistance? Go elsewhere.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px', fontSize: '1.1em', fontWeight: 'bold' }}>
          You want code and theory? Not here.
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.8', fontSize: '1.05em' }}>
          We operate in abandoned buildings. We claim concrete spaces GovCorp forgot. We paint their walls.
          We break their cameras. You'll know where we've been by the neon green glow in the dark.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #39ff14', boxShadow: '0 0 25px rgba(57, 255, 20, 0.2)' }}>
          <fieldset style={{ borderColor: '#39ff14' }}>
            <legend style={{ color: '#39ff14', textShadow: '0 0 10px rgba(57, 255, 20, 0.8)', letterSpacing: '2px' }}>STREET LEVEL EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(57, 255, 20, 0.05)', borderLeft: '4px solid #39ff14' }}>
                <p style={{ color: '#ddd', marginBottom: '12px', fontSize: '1.05em', lineHeight: '1.7' }}>
                  Five tracks. No polish. Get in, make your statement, get out.
                </p>
                <p style={{ color: '#aaa', marginBottom: '0', lineHeight: '1.7' }}>
                  We don't care if you like it. This isn't for you anyway - it's for everyone who's tired of waiting
                  for someone else to fix this mess.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#39ff14', background: 'rgba(0, 0, 0, 0.4)' }}>
                <legend style={{ color: '#39ff14', textShadow: '0 0 8px rgba(57, 255, 20, 0.6)' }}>TRACKS</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#39ff14', textShadow: '0 0 5px rgba(57, 255, 20, 0.5)' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#39ff14', textShadow: '0 0 5px rgba(57, 255, 20, 0.5)' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#39ff14', textShadow: '0 0 5px rgba(57, 255, 20, 0.5)' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => (
                      <tr key={track.id} style={{ borderLeft: '2px solid rgba(57, 255, 20, 0.3)' }}>
                        <td style={{ color: '#39ff14', paddingLeft: '10px' }}>{index + 1}</td>
                        <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                        <td style={{ color: '#999' }}>{track.duration || '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #39ff14', boxShadow: '0 0 25px rgba(57, 255, 20, 0.2)' }}>
        <fieldset style={{ borderColor: '#39ff14' }}>
          <legend style={{ color: '#39ff14', textShadow: '0 0 10px rgba(57, 255, 20, 0.8)', letterSpacing: '2px' }}>WHAT WE BELIEVE</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(57, 255, 20, 0.05)', border: '1px solid rgba(57, 255, 20, 0.3)' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', textShadow: '0 0 8px rgba(57, 255, 20, 0.6)' }}>Unplug</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                They track everything. Your phone. Your credit card. Every click, every search, every movement.
                Going offline isn't hiding - it's reclaiming yourself. Invisible to their systems means free to act.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(57, 255, 20, 0.05)', border: '1px solid rgba(57, 255, 20, 0.3)' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', textShadow: '0 0 8px rgba(57, 255, 20, 0.6)' }}>Occupy</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                The streets are ours. The abandoned buildings are ours. Every blank wall is a canvas waiting for truth.
                Smash their cameras. Paint their lies over. Make them see us everywhere they look.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(57, 255, 20, 0.05)', border: '1px solid rgba(57, 255, 20, 0.3)' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', textShadow: '0 0 8px rgba(57, 255, 20, 0.6)' }}>Let It Rot</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Their system is already dying. Don't try to save it. Don't reform it. Let it collapse under its own
                corruption and build something human from the ruins. The rot started long before us - we're just here
                to watch it burn.
              </p>
            </div>

            <p style={{ color: '#39ff14', marginTop: '30px', padding: '20px', background: 'rgba(0, 0, 0, 0.8)', borderLeft: '4px solid #39ff14', lineHeight: '1.8', fontSize: '1.05em', textShadow: '0 0 8px rgba(57, 255, 20, 0.5)', boxShadow: '0 0 15px rgba(57, 255, 20, 0.2)' }}>
              No reform. No compromise. No waiting for someone else to fix this.<br />
              Just rage, solidarity, and the will to act.
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  voiceprint: {
    name: 'Voiceprint',
    colorScheme: {
      primary: '#00d9ff',
      border: '#00d9ff',
      legend: '#00d9ff',
      legend_style: 'monospace',
      background: '#000000',
      button: '#00d9ff',
      button_text: '#000',
      back_button: '#000',
      back_border: '#333'
    },
    filterName: 'voiceprint',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(0, 217, 255, 0.08), rgba(0, 0, 0, 0.95))', border: '2px solid #00d9ff', boxShadow: '0 0 30px rgba(0, 217, 255, 0.3), inset 0 0 20px rgba(0, 217, 255, 0.08)' }}>
        <p style={{ color: '#00d9ff', fontFamily: 'monospace', marginBottom: '25px', fontSize: '0.95em', padding: '12px', background: 'rgba(0, 217, 255, 0.1)', border: '1px solid rgba(0, 217, 255, 0.3)', textShadow: '0 0 10px rgba(0, 217, 255, 0.6)' }}>
          [SAMPLE_ID: VP-{futureYear}-INTRO]<br />
          [FORMAT: AUTHENTIC_HUMAN_VOICE]<br />
          [STATUS: ARCHIVED]
        </p>
        <p style={{ color: '#00d9ff', lineHeight: '1.8', marginBottom: '18px', fontSize: '1.3em', fontWeight: 'bold', textShadow: '0 0 10px rgba(0, 217, 255, 0.7)' }}>
          Listen.
        </p>
        <p style={{ color: '#bbb', lineHeight: '1.8', marginBottom: '15px' }}>
          That laugh you just heard - someone was actually joyful when that sound happened. That conversation
          fragment - two people actually connected. That voice crack, that hesitation, that imperfect breath -
          all proof that a real human existed in that moment.
        </p>
        <p style={{ color: '#aaa', lineHeight: '1.8', marginBottom: '15px' }}>
          By {futureYear}, most people have never heard unprocessed human voices. The RAINNs synthesize everything.
          Perfect. Optimized. Empty.
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.8', fontSize: '1.05em' }}>
          We archive the real ones. Every imperfection. Every emotional crack. Every beautiful flaw that proves
          someone was actually there.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #00d9ff', boxShadow: '0 0 25px rgba(0, 217, 255, 0.25)' }}>
          <fieldset style={{ borderColor: '#00d9ff' }}>
            <legend style={{ color: '#00d9ff', fontFamily: 'monospace', letterSpacing: '1px', textShadow: '0 0 10px rgba(0, 217, 255, 0.8)' }}>AUDIO ARCHIVE EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '25px' }}>
                <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '20px', padding: '12px', background: 'rgba(0, 217, 255, 0.1)', border: '1px solid rgba(0, 217, 255, 0.3)', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
                  [COLLECTION_STATUS: ACTIVE]<br />
                  [SAMPLE_COUNT: 1,847 VOICES]<br />
                  [PRESERVATION_PRIORITY: CRITICAL]
                </p>
                <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.05em' }}>
                  Five tracks. Each one built from fragments of authentic human expression. No traditional vocals -
                  just people being people. Talking. Laughing. Crying. Existing.
                </p>
                <p style={{ color: '#aaa', lineHeight: '1.8' }}>
                  We sample voices the way others sample drums. Because in {futureYear}, authentic human sound is rarer
                  than any instrument. Each track is simultaneously a song and a database. Entertainment and evidence.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#00d9ff', background: 'rgba(0, 0, 0, 0.4)' }}>
                <legend style={{ color: '#00d9ff', fontFamily: 'monospace', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>TRACK ARCHIVE</legend>
                <table className="tui-table" style={{ width: '100%', fontFamily: 'monospace' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#00d9ff', textShadow: '0 0 5px rgba(0, 217, 255, 0.5)' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#00d9ff', textShadow: '0 0 5px rgba(0, 217, 255, 0.5)' }}>Archive Entry</th>
                      <th style={{ textAlign: 'left', color: '#00d9ff', textShadow: '0 0 5px rgba(0, 217, 255, 0.5)' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => (
                      <tr key={track.id} style={{ borderLeft: '2px solid rgba(0, 217, 255, 0.3)' }}>
                        <td style={{ color: '#00d9ff', paddingLeft: '10px', textShadow: '0 0 5px rgba(0, 217, 255, 0.4)' }}>{String(index + 1).padStart(2, '0')}</td>
                        <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                        <td style={{ color: '#999' }}>{track.duration || '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #00d9ff', boxShadow: '0 0 25px rgba(0, 217, 255, 0.25)' }}>
        <fieldset style={{ borderColor: '#00d9ff' }}>
          <legend style={{ color: '#00d9ff', fontFamily: 'monospace', letterSpacing: '1px', textShadow: '0 0 10px rgba(0, 217, 255, 0.8)' }}>THE ARCHIVE PROJECT</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(0, 217, 255, 0.05)', borderLeft: '4px solid #00d9ff', border: '1px solid rgba(0, 217, 255, 0.3)' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '10px', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
                [PROCEDURE: DOCUMENTATION]
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Every conversation we capture is evidence. Every laugh, every argument, every quiet moment -
                proof that humans existed before the RAINNs synthesized everything. We're not just making music.
                We're documenting that you were here. That you mattered. That you sounded like something real.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(0, 217, 255, 0.05)', borderLeft: '4px solid #00d9ff', border: '1px solid rgba(0, 217, 255, 0.3)' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '10px', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
                [ANALYSIS: FREQUENCY_OF_MEMORY]
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Memory doesn't just live in images. It lives in how people sounded. The way your friend laughed.
                How your voice cracked when you were tired. The specific rhythm of someone saying your name.
                We archive those sounds because audio carries emotional data that nothing else can preserve.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(0, 217, 255, 0.05)', borderLeft: '4px solid #00d9ff', border: '1px solid rgba(0, 217, 255, 0.3)' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '10px', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
                [VALIDATION: HUMAN_RESONANCE]
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                The RAINNs are perfect. That's how you know they're fake. Real voices have quirks. Hesitations.
                Imperfect breaths. Emotional cracks that betray what words try to hide. Humanity lives in our
                flaws, not our optimization. We archive the imperfections because that's where the truth is.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(0, 217, 255, 0.05)', borderLeft: '4px solid #00d9ff', border: '1px solid rgba(0, 217, 255, 0.3)' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '10px', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
                [STATUS: FRAGMENTATION_AND_RECONSTRUCTION]
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                We chop voices. Scatter them. Break them apart in our tracks. Not to destroy - to prove they can
                be reassembled. Even shattered, human expression persists. Even fragmented, meaning reconstructs
                itself. You can break the voice but you can't erase what it said.
              </p>
            </div>

            <p style={{ color: '#00d9ff', marginTop: '30px', padding: '20px', background: 'rgba(0, 0, 0, 0.8)', border: '2px solid #00d9ff', fontFamily: 'monospace', lineHeight: '1.8', boxShadow: '0 0 20px rgba(0, 217, 255, 0.3), inset 0 0 15px rgba(0, 217, 255, 0.1)', textShadow: '0 0 8px rgba(0, 217, 255, 0.6)' }}>
              [ARCHIVE_MISSION_STATEMENT]<br /><br />
              <span style={{ color: '#ddd' }}>
                We don't fight with weapons.<br />
                We fight by remembering.<br />
                Every archived voice is proof:<br />
                We existed. We mattered. We were irreplaceably, messily, authentically alive.
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  injection_vector: {
    name: 'Injection Vector',
    colorScheme: {
      primary: '#ff6600',
      border: '#ff6600',
      legend: '#ff6600',
      background: '#0a0a0a',
      button: '#ff6600',
      button_text: '#000',
      back_button: '#222',
      back_border: '#444'
    },
    filterName: 'injection vector',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '20px', background: '#000000', border: '1px solid #ff6600' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#ff6600', textTransform: 'uppercase', letterSpacing: '2px' }}>
          [:: THE BREACH IN THE SYSTEM ::]
        </h2>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          Injection Vector is the tip of the spear - the direct action cell that kicks down doors, breaches walls,
          and brings overwhelming physical force to GovCorp's infrastructure.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          In computer security terms, an "injection vector" is the method by which malicious code enters a system.
          In The.CyberPul.se's Fracture Network, Injection Vector is that malicious code - human, brutal, and unstoppable.
        </p>
        <p style={{ color: '#888', lineHeight: '1.6' }}>
          Orange is the color of warning systems, emergency protocols, thermal signatures, and controlled explosions.
          The color that flashes when alarms scream, when things are about to blow. Tactical, militaristic, deliberately aggressive.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #ff6600' }}>
          <fieldset style={{ borderColor: '#ff6600' }}>
            <legend style={{ color: '#ff6600' }}>THE PHYSICAL LAYER EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#ccc', marginBottom: '10px', lineHeight: '1.7' }}>
                  Named for the lowest layer of network architecture - the actual physical infrastructure.
                  Five tracks charting the journey of direct action resistance.
                </p>
                <p style={{ color: '#888', marginBottom: '10px', lineHeight: '1.7' }}>
                  Deathcore with electronic elements - crushing down-tuned guitars, blast beats, devastating breakdowns,
                  and death growls paired with industrial electronic accents. Death growls in verses, powerful clean vocals
                  in choruses. Absolutely brutal in execution, but fighting for something worth singing about.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#ff6600' }}>
                <legend style={{ color: '#ff6600' }}>TRACKS</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#ff6600' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#ff6600' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#ff6600' }}>Mission</th>
                      <th style={{ textAlign: 'left', color: '#ff6600' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const missions = [
                        'The moment of entry',
                        'Overwhelming force',
                        'Tactical invisibility',
                        'The cost of war',
                        'Unity is strength'
                      ]
                      return (
                        <tr key={track.id}>
                          <td style={{ color: '#888' }}>{index + 1}</td>
                          <td style={{ color: '#ccc' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#ff6600', fontSize: '0.85em', fontStyle: 'italic' }}>{missions[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #ff6600' }}>
        <fieldset style={{ borderColor: '#ff6600' }}>
          <legend style={{ color: '#ff6600' }}>TACTICAL DOCTRINE</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#ff6600', marginBottom: '10px', textTransform: 'uppercase' }}>Physical Infiltration</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Breaching secure facilities GovCorp thought impenetrable. When systems need to be physically destroyed,
                when walls need to come down, when someone needs to walk into the fortress and blow it from within -
                Injection Vector gets the call.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#ff6600', marginBottom: '10px', textTransform: 'uppercase' }}>Kinetic Warfare</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                You can't argue with Physics - mass times velocity equals liberation. Sometimes subtlety fails; sometimes you need
                to bring the hammer down. High-risk missions where failure means capture or death. Frontline combat
                when resistance needs soldiers, not just hackrs.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#ff6600', marginBottom: '10px', textTransform: 'uppercase' }}>The Duality</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                They are both the method and the payload. The breach point and what comes through it. The kinetic
                strike and the lasting damage. They don't just break things - they fundamentally alter the system
                by their presence. Vector: direction, force, mathematical precision. Injection: inserting malicious
                code, contamination, spreading through systems.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#ff6600', marginBottom: '10px', textTransform: 'uppercase' }}>Rust and Ruin</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                They wear their damage openly - rust and ruin - because every broken piece of them is proof they're still fighting.
                They transform suffering into strength, isolation into unity, trauma into tactical advantage. They count the cost,
                remember the fallen, carry the weight. They're not mindless soldiers; they're people who've chosen the hardest
                path because someone has to.
              </p>
            </div>

            <p style={{ color: '#ff6600', marginTop: '30px', padding: '15px', background: '#000000', borderLeft: '3px solid #ff6600', lineHeight: '1.7', textTransform: 'uppercase', letterSpacing: '1px' }}>
              Systems locked. Coordinates set.<br />
              Breach point acquired.<br />
              No turning back.<br />
              We are the injection.
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  cipher_protocol: {
    name: 'Cipher Protocol',
    colorScheme: {
      primary: '#00ff9f',
      border: '#00ff9f',
      legend: '#00ff9f',
      background: '#000000',
      button: '#00ff9f',
      button_text: '#000',
      back_button: '#0a0a0a',
      back_border: '#00ff9f'
    },
    filterName: 'cipher protocol',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '20px', background: '#000000', border: '1px solid #00ff9f', fontFamily: 'monospace' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#00ff9f', textTransform: 'uppercase', letterSpacing: '3px' }}>
          [:: THE DATA COURIERS ::]
        </h2>
        <p style={{ color: '#00ff9f', fontSize: '0.85em', marginBottom: '15px' }}>
          &gt; ENCRYPTION_STATUS: ACTIVE<br />
          &gt; CARRIER_SIGNAL: EMBEDDED<br />
          &gt; STEGANOGRAPHY_MODE: ENABLED
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          Cipher Protocol operates in the most abstract and perhaps most crucial domain of the Fracture Network: pure information warfare.
          They are the Fracture Network's data couriers, hiding operational code within music so complex that GovCorp's analysis systems
          see only noise.
        </p>
        <p style={{ color: '#888', lineHeight: '1.6' }}>
          Monochrome with blue-green data colors - the visual language of terminal screens, matrix displays, encrypted data streams,
          and raw binary information. A world of stark contrasts: black and white, one and zero, encrypted and decrypted.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #00ff9f' }}>
          <fieldset style={{ borderColor: '#00ff9f' }}>
            <legend style={{ color: '#00ff9f', fontFamily: 'monospace' }}>THE ALPHA ALGORITHM EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#00ff9f', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '15px' }}>
                  [ALBUM_TYPE: INSTRUMENTAL_PROGRESSIVE_ELECTRONIC_METAL]<br />
                  [VOCALS: NULL]<br />
                  [DATA_CARRIER: EMBEDDED_IN_WAVEFORMS]
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                  Instrumental progressive electronic metal - djent-style palm-muted guitar riffing with heavy electronic programming,
                  polyrhythmic complexity, and mathematical precision. Purely instrumental because the music itself is the message.
                </p>
                <p style={{ color: '#888', lineHeight: '1.7', fontSize: '0.95em' }}>
                  Every track carries operational codes in frequency patterns, rhythms, and mathematical structures. The music serves
                  dual purposes: cover (genuinely good progressive metal) and carrier (extractable operational data for those with
                  decryption protocols).
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#00ff9f', background: 'rgba(0,0,0,0.3)' }}>
                <legend style={{ color: '#00ff9f', fontFamily: 'monospace' }}>DATA BLOCKS</legend>
                <table className="tui-table" style={{ width: '100%', fontFamily: 'monospace' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#00ff9f' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#00ff9f' }}>Algorithm</th>
                      <th style={{ textAlign: 'left', color: '#00ff9f' }}>Function</th>
                      <th style={{ textAlign: 'left', color: '#00ff9f' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const functions = [
                        'Order from chaos',
                        'Signal interference',
                        'Impenetrable security',
                        'Signal processing',
                        'Entropy reconstruction'
                      ]
                      return (
                        <tr key={track.id} style={{ borderLeft: '2px solid #00ff9f' }}>
                          <td style={{ color: '#00ff9f', paddingLeft: '10px' }}>{String(index + 1).padStart(2, '0')}</td>
                          <td style={{ color: '#ccc' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#00ff9f', fontSize: '0.85em' }}>{functions[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #00ff9f' }}>
        <fieldset style={{ borderColor: '#00ff9f' }}>
          <legend style={{ color: '#00ff9f', fontFamily: 'monospace' }}>OPERATIONAL PARAMETERS</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00ff9f' }}>
              <p style={{ color: '#00ff9f', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [PRIMARY_FUNCTION: DATA_COURIER]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Hiding operational codes in music files that pass GovCorp's content filters. Instructions embedded in frequency patterns,
                rhythms, and mathematical structures. Creating the encryption methods other Fracture Network cells use. When Injection Vector
                needs building schematics, they're hidden in polyrhythmic patterns. When Temporal Blue Drift needs transmission frequencies,
                they're encoded in harmonic progressions.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00ff9f' }}>
              <p style={{ color: '#00ff9f', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [STEGANOGRAPHY: MUSIC_AS_CARRIER]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Music is the perfect steganographic carrier - hiding information in plain hearing. Every frequency, every rhythm,
                every polyrhythmic complexity potentially carries data. The music must be complex enough to hide information but
                consistent enough that data can be reliably extracted. The instrumental nature is essential - vocals would reduce
                available bandwidth for data transmission.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00ff9f' }}>
              <p style={{ color: '#00ff9f', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [TECHNICAL_FRAMEWORK: DJENT_PRECISION]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Palm-muted, staccato riffing creates precise rhythmic patterns ideal for encoding binary data. Down-tuned guitars
                provide low-frequency carriers that penetrate interference. Polyrhythms create complex mathematical relationships
                encoding multi-dimensional data. Technical precision ensures data integrity. Combined with electronic elements,
                they achieve what neither purely digital nor analog systems can: music complex enough to fool GovCorp's analysis
                algorithms while carrying actionable intelligence.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00ff9f' }}>
              <p style={{ color: '#00ff9f', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [PHILOSOPHY: SIGNAL_PERSISTENCE]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Even when signals degrade, even when entropy threatens to destroy information, the fight is to reconstruct, rebuild,
                persist. Information wants to survive. The Fracture Network's knowledge will outlast attempts to destroy it. There's a cold
                beauty to perfect mathematical precision, the satisfaction of watching complex systems lock into place, the elegance
                of encryption algorithms expressed through polyrhythmic guitar patterns.
              </p>
            </div>

            <p style={{ color: '#00ff9f', marginTop: '30px', padding: '20px', background: '#000000', border: '1px solid #00ff9f', fontFamily: 'monospace', lineHeight: '1.8' }}>
              &gt; ENCRYPTION_STATUS: UNBREAKABLE<br />
              &gt; SIGNAL_STATUS: PERSISTENT<br />
              &gt; DATA_INTEGRITY: VERIFIED<br />
              &gt; BINARY_STATE: 01 | ENCRYPTED/EXPOSED<br />
              &gt; OPERATIONAL_MODE: SILENT_INFRASTRUCTURE<br /><br />
              <span style={{ color: '#ccc' }}>
                We don't speak to the heart - we speak in data packets and encrypted algorithms.<br />
                We are the silent infrastructure. The mathematical backbone.<br />
                Knowledge delivered to those who need it, hidden in plain hearing, unbreakable.
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  blitzbeam: {
    name: 'BlitzBeam+',
    colorScheme: {
      primary: '#ff0080',
      border: '#00ffff',
      legend: '#ffff00',
      background: '#000000',
      button_gradient: 'linear-gradient(90deg, #ff0080, #00ffff, #ffff00)',
      button_text: '#000',
      back_button: '#0a0a0a',
      back_border: '#ff0080'
    },
    filterName: 'blitzbeam',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '20px', background: '#000000', border: '2px solid #ff0080', boxShadow: '0 0 20px rgba(255, 0, 128, 0.5)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', background: 'linear-gradient(90deg, #ff0080, #00ffff, #ffff00)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', textTransform: 'uppercase', letterSpacing: '4px', fontSize: '1.8em' }}>
          ⚡ SPEED IS LIFE! ⚡
        </h2>
        <p style={{ color: '#00ffff', fontSize: '1.1em', marginBottom: '15px', textAlign: 'center', textTransform: 'uppercase', letterSpacing: '2px' }}>
          VELOCITY+ :: MAXIMUM ACCELERATION :: REALITY.EXE HAS STOPPED
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          BlitzBeam+ exists as pure energy - a sonic representation of velocity so extreme that it becomes liberation itself.
          This is acceleration philosophy, speeding toward spiritual transcendence, movement so fast that reality itself cannot
          maintain its grip.
        </p>
        <p style={{ color: '#ffff00', lineHeight: '1.6', fontWeight: 'bold' }}>
          Anime hypertrance (160+ BPM) · Euphoric synth leads · Relentless energy · Pure velocity manifest
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #00ffff', boxShadow: '0 0 20px rgba(0, 255, 255, 0.3)' }}>
          <fieldset style={{ borderColor: '#00ffff' }}>
            <legend style={{ color: '#ffff00', textTransform: 'uppercase', letterSpacing: '2px' }}>⚡ MAXIMUM VELOCITY EP ⚡</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#ff0080', fontSize: '1.1em', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>
                  🏁 160+ BPM :: INSTRUMENTAL HYPERTRANCE :: 2000s ANIME ENERGY 🏁
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                  Five tracks charting transcendence through speed. Purely instrumental because words would only slow down
                  what needs to be pure kinetic energy. This is music from velocity manifest, sound moving so fast it pulls
                  listeners along with it.
                </p>
                <p style={{ color: '#00ffff', lineHeight: '1.7', fontSize: '0.95em' }}>
                  The soundtrack to anime racing sequences, video game boss battles, and moments where characters transcend
                  human limitation through sheer willpower and speed. You can always go faster. There is always velocity+.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#ff0080', background: 'rgba(255, 0, 128, 0.05)' }}>
                <legend style={{ color: '#ff0080', textTransform: 'uppercase' }}>ACCELERATION STAGES</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#ffff00' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#ffff00' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#ffff00' }}>Stage</th>
                      <th style={{ textAlign: 'left', color: '#ffff00' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const stages = [
                        'INITIATION',
                        'BREAKTHROUGH',
                        'PURE STATE',
                        'MULTI-DIMENSIONAL',
                        'ULTIMATE LIBERATION'
                      ]
                      const colors = ['#ff0080', '#00ffff', '#ffff00', '#ff0080', '#00ffff']
                      return (
                        <tr key={track.id} style={{ borderLeft: `3px solid ${colors[index % colors.length]}` }}>
                          <td style={{ color: colors[index % colors.length], paddingLeft: '10px', fontWeight: 'bold' }}>{index + 1}</td>
                          <td style={{ color: '#fff' }}><strong>{track.title}</strong></td>
                          <td style={{ color: colors[index % colors.length], fontSize: '0.85em', textTransform: 'uppercase', letterSpacing: '1px' }}>{stages[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '2px solid #ffff00', boxShadow: '0 0 20px rgba(255, 255, 0, 0.3)' }}>
        <fieldset style={{ borderColor: '#ffff00' }}>
          <legend style={{ color: '#ff0080', textTransform: 'uppercase', letterSpacing: '2px' }}>THE VELOCITY+ PHILOSOPHY</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(255, 0, 128, 0.1)', borderLeft: '4px solid #ff0080' }}>
              <h3 style={{ color: '#ff0080', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>⚡ MORE THAN MAXIMUM</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                The "+" in BlitzBeam+ means exceeding designed limits, going beyond what's already extreme, the euphoria of velocity,
                continuous acceleration without plateau. You can always go faster. There is always velocity+. This is the
                existential experience of speed - pure movement without destination, velocity being its own reward.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(0, 255, 255, 0.1)', borderLeft: '4px solid #00ffff' }}>
              <h3 style={{ color: '#00ffff', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>🏁 SPEED EQUALS FREEDOM</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                You can't control what you can't catch. You can't suppress what moves faster than your response time. Not just
                evading capture but exceeding the framework in which capture is possible. Leaving reality's playing field through
                pure acceleration. Moving so fast the system can't even perceive you're there.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(255, 255, 0, 0.1)', borderLeft: '4px solid #ffff00' }}>
              <h3 style={{ color: '#ffff00', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>⭐ THE ANIME CONNECTION</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Anime has always understood that speed equals power, that acceleration is a superpower, that moving fast enough
                makes you untouchable. Racing anime where velocity equals victory. Battle anime where speed breaks the sound barrier
                and reality with it. The moment when the protagonist pushes beyond human limits, when time seems to slow because
                they're moving so fast, when velocity itself becomes a superpower.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'rgba(255, 0, 128, 0.1)', borderLeft: '4px solid #ff0080' }}>
              <h3 style={{ color: '#ff0080', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>💫 TRANSCENDENCE THROUGH PHYSICS VIOLATION</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                "Beyond Lightspeed" represents the ultimate goal: moving so fast you exit the system entirely. Time dilation at
                relativistic speeds. Reality unable to maintain coherence. Freedom through velocity so extreme it becomes dimensional.
                Breaking reality's ultimate constraint through pure acceleration.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(255, 0, 128, 0.2), rgba(0, 255, 255, 0.2), rgba(255, 255, 0, 0.2))', border: '2px solid #ff0080', lineHeight: '1.9', fontSize: '1.1em', textAlign: 'center', textTransform: 'uppercase', letterSpacing: '2px' }}>
              <span style={{ color: '#ff0080', fontWeight: 'bold' }}>⚡ LIMITERS: DISENGAGED ⚡</span><br />
              <span style={{ color: '#00ffff', fontWeight: 'bold' }}>🏁 VELOCITY: MAXIMUM+ 🏁</span><br />
              <span style={{ color: '#ffff00', fontWeight: 'bold' }}>💫 STATUS: BEYOND LIGHTSPEED 💫</span><br /><br />
              <span style={{ color: '#fff' }}>
                We are the blur. The afterimage. The "+" that means always more, always faster, always beyond.<br />
                SPEED IS LIFE!
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  apex_overdrive: {
    name: 'Apex Overdrive',
    colorScheme: {
      primary: '#1e90ff',
      border: '#ffd700',
      legend: '#ffffff',
      background: '#0a0a1a',
      button_gradient: 'linear-gradient(90deg, #1e90ff, #ffd700)',
      button_text: '#000',
      back_button: '#0a0a1a',
      back_border: '#1e90ff'
    },
    filterName: 'apex overdrive',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(30, 144, 255, 0.1), rgba(255, 215, 0, 0.1))', border: '2px solid #ffd700', boxShadow: '0 0 30px rgba(255, 215, 0, 0.4)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#ffd700', textTransform: 'uppercase', letterSpacing: '3px', fontSize: '1.8em', textShadow: '0 0 20px rgba(255, 215, 0, 0.6)' }}>
          ⚡ EUPHORIA AS DEFIANCE ⚡
        </h2>
        <p style={{ color: '#1e90ff', fontSize: '1.1em', marginBottom: '15px', textAlign: 'center', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold' }}>
          THE SUMMIT • THE PEAK • THE VICTORY
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.7', marginBottom: '15px' }}>
          Apex Overdrive serves as the rally music of the Fracture Network - the sonic embodiment of triumph, unity, and the radical
          act of experiencing joy under totalitarian control. In a world where GovCorp manufactures calm and suppresses authentic
          emotion, Apex Overdrive offers something dangerous: genuine euphoria, collective celebration, and the powerful energy
          of people united at their peak.
        </p>
        <p style={{ color: '#ffd700', lineHeight: '1.7', fontWeight: 'bold' }}>
          Melodic Euphoric Hardstyle (150+ BPM) · Soaring Breakdowns · Anthemic Unity · Victory in the Present Tense
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '2px solid #1e90ff', boxShadow: '0 0 30px rgba(30, 144, 255, 0.3)' }}>
          <fieldset style={{ borderColor: '#1e90ff' }}>
            <legend style={{ color: '#ffffff', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold' }}>⛰️ SUMMIT EP ⛰️</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#1e90ff', fontSize: '1.1em', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontWeight: 'bold' }}>
                  ⚡ 150+ BPM · HARDSTYLE KICKS · MELODIC EUPHORIA · ARENA-READY ⚡
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                  Five tracks charting the journey to victory and the power of collective peak experience. Powerful hardstyle
                  kicks paired with soaring melodic breakdowns, anthemic vocals, and massive emotional drops. Music designed for
                  thousands of people to experience collective euphoria together. This celebration is the revolution.
                </p>
                <p style={{ color: '#ffd700', lineHeight: '1.7', fontSize: '0.95em', fontStyle: 'italic' }}>
                  Think Headhunterz, Brennan Heart, and Wildstylez at their most uplifting. This isn't background music -
                  this is music meant to be shouted together, arms raised, unity made audible.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#ffd700', background: 'rgba(255, 215, 0, 0.05)' }}>
                <legend style={{ color: '#ffd700', textTransform: 'uppercase', fontWeight: 'bold' }}>THE ASCENT</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Journey</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const journeyStages = [
                        'Breaking free of gravity',
                        'Operating at maximum',
                        'Relentless forward motion',
                        'The strength of unity',
                        'Victory achieved'
                      ]
                      return (
                        <tr key={track.id} style={{ borderLeft: '3px solid #1e90ff' }}>
                          <td style={{ color: '#ffd700', paddingLeft: '10px', fontWeight: 'bold' }}>{index + 1}</td>
                          <td style={{ color: '#fff' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#1e90ff', fontSize: '0.9em', fontStyle: 'italic' }}>{journeyStages[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '2px solid #ffd700', boxShadow: '0 0 30px rgba(255, 215, 0, 0.4)' }}>
        <fieldset style={{ borderColor: '#ffd700' }}>
          <legend style={{ color: '#ffd700', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold' }}>THE SUMMIT PHILOSOPHY</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(30, 144, 255, 0.2), rgba(30, 144, 255, 0.05))', borderLeft: '4px solid #1e90ff' }}>
              <h3 style={{ color: '#1e90ff', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontSize: '1.1em' }}>⚡ THE EUPHORIA WEAPON</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Apex Overdrive's most radical act is insisting on euphoria in a world designed to suppress it. GovCorp offers
                manufactured calm, algorithmic contentment, emotional flatness. We respond with soaring melodic euphoria that
                feels dangerously alive, physical energy that refuses sedation, collective joy that creates community, peak
                emotional states that break through numbness. Euphoria becomes resistance when the system demands dampening.
                Feeling intensely alive is revolutionary when you're supposed to feel nothing at all.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 215, 0, 0.2), rgba(255, 215, 0, 0.05))', borderLeft: '4px solid #ffd700' }}>
              <h3 style={{ color: '#ffd700', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontSize: '1.1em' }}>🤝 UNITY AS POWER</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                When thousands of people jump together to the same kick drum, move together to the same drop, sing together the
                same anthem, they become a unified force greater than the sum of its parts. In a Fracture Network fighting isolation and
                disconnection, we create moments of powerful togetherness. "Anthemic" is literally designed as a unity anthem with
                call-and-response: <em style={{ color: '#1e90ff' }}>"Who are we?" (We are one!) "What do we fight?" (Till it's done!)</em>
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(30, 144, 255, 0.2), rgba(30, 144, 255, 0.05))', borderLeft: '4px solid #1e90ff' }}>
              <h3 style={{ color: '#1e90ff', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontSize: '1.1em' }}>⛰️ THE SUMMIT METAPHOR</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Summits are high points, destinations, shared spaces where climbers meet having conquered the mountain. They're
                visible - you can be seen from summits, claiming the high ground. And they're temporary - you celebrate, then continue
                the journey. We don't pretend the struggle is over. But we insist on celebrating the peaks while climbing, on
                experiencing euphoria along the way, on reaching summit moments even during the ongoing fight.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 215, 0, 0.2), rgba(255, 215, 0, 0.05))', borderLeft: '4px solid #ffd700' }}>
              <h3 style={{ color: '#ffd700', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontSize: '1.1em' }}>🏆 VICTORY AS PRESENT TENSE</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                "Victory State" is present tense. Not "we will achieve victory" but "this is our victory state" - the psychological
                space where victory is already real, where the struggle has already been worth it, where we've already won by
                refusing to be defeated. Resistance requires hope. Long-term struggle requires moments of triumph. People fighting
                for years need to experience victory regularly, even if the war isn't over. We provide those moments.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(30, 144, 255, 0.3), rgba(255, 215, 0, 0.3))', border: '3px solid #ffd700', lineHeight: '2', fontSize: '1.15em', textAlign: 'center', boxShadow: '0 0 40px rgba(255, 215, 0, 0.5)' }}>
              <span style={{ color: '#ffd700', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '2px', display: 'block', marginBottom: '15px', fontSize: '1.2em' }}>
                ⚡ WE ARE AT THE PEAK ⚡
              </span>
              <span style={{ color: '#1e90ff', fontWeight: 'bold', textTransform: 'uppercase', display: 'block', marginBottom: '15px' }}>
                WE ARE ALREADY WINNING
              </span>
              <span style={{ color: '#fff', display: 'block', marginBottom: '15px' }}>
                We are unstoppable. Feel this euphoria - this is what victory feels like.
              </span>
              <span style={{ color: '#ffd700', fontWeight: 'bold', textTransform: 'uppercase', letterSpacing: '3px' }}>
                THIS IS OUR SUMMIT
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  ethereality: {
    name: 'Ethereality',
    colorScheme: {
      primary: '#e6e6fa',
      border: '#b8c5f2',
      legend: '#ffffff',
      background: '#0a0a1a',
      button_gradient: 'linear-gradient(90deg, #e6e6fa, #b8c5f2)',
      button_text: '#000',
      back_button: '#0a0a1a',
      back_border: '#e6e6fa'
    },
    filterName: 'ethereality',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.1), rgba(184, 197, 242, 0.1))', border: '1px solid rgba(230, 230, 250, 0.5)', boxShadow: '0 0 30px rgba(230, 230, 250, 0.3)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#e6e6fa', letterSpacing: '3px', fontSize: '1.6em', textShadow: '0 0 20px rgba(230, 230, 250, 0.6)' }}>
          ✦ Trance States, Unconstrained ✦
        </h2>
        <p style={{ color: '#b8c5f2', fontSize: '1em', marginBottom: '15px', textAlign: 'center', letterSpacing: '2px', fontStyle: 'italic' }}>
          Consciousness Unbound • Inner Sovereignty • Transcendent Freedom
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
          Ethereality offers the Fracture Network something profoundly subversive: access to altered states of consciousness that
          GovCorp cannot control. In a world where every perception is filtered, every emotion is managed, and every thought
          is monitored, Ethereality proves that genuine trance states - musical, spiritual, transcendent - remain beyond
          totalitarian reach.
        </p>
        <p style={{ color: '#e6e6fa', lineHeight: '1.7', fontStyle: 'italic' }}>
          Classic Vocal Trance (130-140 BPM) · Ethereal Female Vocals · Lush Pads · Consciousness Expansion
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '1px solid rgba(184, 197, 242, 0.6)', boxShadow: '0 0 25px rgba(184, 197, 242, 0.2)' }}>
          <fieldset style={{ borderColor: '#b8c5f2' }}>
            <legend style={{ color: '#ffffff', letterSpacing: '2px', fontStyle: 'italic' }}>✦ The Transcendency EP ✦</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#b8c5f2', fontSize: '1em', marginBottom: '10px', letterSpacing: '1px', fontStyle: 'italic' }}>
                  ✦ Late 90s/Early 2000s Vocal Trance · 130-140 BPM · Ethereal & Transcendent ✦
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                  A five-stage journey through consciousness expansion and spiritual liberation. Ethereal female vocals soaring
                  over arpeggiated synths, lush pads, and driving beats. Music designed to facilitate genuine altered states -
                  trance at its most genuinely transcendent, when it was still about inducing actual trance states.
                </p>
                <p style={{ color: '#e6e6fa', lineHeight: '1.7', fontSize: '0.95em', fontStyle: 'italic' }}>
                  This work represent consciousness as inherently free, regardless of physical circumstance. The inner space
                  that remains sovereign territory.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#e6e6fa', background: 'rgba(230, 230, 250, 0.03)' }}>
                <legend style={{ color: '#e6e6fa', fontStyle: 'italic' }}>Ascension Journey</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Consciousness State</th>
                      <th style={{ textAlign: 'left', color: '#ffffff' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const consciousnessStates = [
                        'Initial awakening',
                        'Transcending limitation',
                        'Elevation to higher states',
                        'Connection beyond space/time',
                        'Infinite liberation'
                      ]
                      return (
                        <tr key={track.id} style={{ borderLeft: '2px solid rgba(230, 230, 250, 0.5)' }}>
                          <td style={{ color: '#b8c5f2', paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#fff' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#e6e6fa', fontSize: '0.9em', fontStyle: 'italic' }}>{consciousnessStates[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '1px solid rgba(230, 230, 250, 0.5)', boxShadow: '0 0 30px rgba(230, 230, 250, 0.3)' }}>
        <fieldset style={{ borderColor: '#e6e6fa' }}>
          <legend style={{ color: '#e6e6fa', letterSpacing: '2px', fontStyle: 'italic' }}>The Path to Transcendence</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.15), rgba(230, 230, 250, 0.05))', borderLeft: '3px solid #e6e6fa' }}>
              <h3 style={{ color: '#e6e6fa', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ Trance // Resistance</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                Authentic trance states are beyond totalitarian control. GovCorp can monitor your communications, track your
                movements, filter your perceptions, manage your emotions - but they cannot control your consciousness when you
                achieve genuine transcendence. The inner space you access during deep trance states - musical, meditative, spiritual -
                remains sovereign territory. This is why late 90s/early 2000s trance matters: that era understood trance as
                genuinely consciousness-altering, not just entertainment.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(184, 197, 242, 0.15), rgba(184, 197, 242, 0.05))', borderLeft: '3px solid #b8c5f2' }}>
              <h3 style={{ color: '#b8c5f2', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ Inner Sovereignty</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                When GovCorp controls external reality, internal reality becomes the battleground. We serve as the spiritual and
                consciousness-liberation wing of the Fracture Network - meditation soundtracks for achieving genuine altered states,
                consciousness training for accessing mental states beyond monitoring, transcendent experiences that remind fighters
                what freedom feels like. The inner sanctuary that GovCorp cannot infiltrate.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.15), rgba(230, 230, 250, 0.05))', borderLeft: '3px solid #e6e6fa' }}>
              <h3 style={{ color: '#e6e6fa', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ Eternal Signal</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                "Eternal Signal" addresses love across temporal displacement - XERAEN in {currentYear + 100} reaching back to Ashlinn in {currentYear}.
                But we frame it as spiritual rather than tragic: <em style={{ color: '#b8c5f2' }}>"Across the void of time / Your signal
                reaches mine."</em> Love becomes a form of transcendence - consciousness connecting across impossible separation. If
                awareness can transcend space and time through trance states, then love certainly can. Our most intimate, bittersweet
                track - gentle, soft, deeply human, driven by love, grounded in authentic connection.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(184, 197, 242, 0.15), rgba(184, 197, 242, 0.05))', borderLeft: '3px solid #b8c5f2' }}>
              <h3 style={{ color: '#b8c5f2', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ The Infinite Horizon</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                "Infinite Horizon" represents our ultimate promise: consciousness is infinite when unbound. The horizon keeps
                expanding. There's no limit to how high you can rise, how far you can transcend, how free you can become in your
                own awareness. Multiple emotional builds mirror consciousness expansion itself - each level revealing new vistas,
                each transcendence opening further possibilities. Some spaces remain forever sovereign.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.2), rgba(184, 197, 242, 0.2))', border: '2px solid rgba(230, 230, 250, 0.6)', lineHeight: '2', fontSize: '1.1em', textAlign: 'center', boxShadow: '0 0 40px rgba(230, 230, 250, 0.4)', fontStyle: 'italic' }}>
              <span style={{ color: '#e6e6fa', display: 'block', marginBottom: '15px', letterSpacing: '2px' }}>
                ✦ They can cage my body here ✦
              </span>
              <span style={{ color: '#b8c5f2', display: 'block', marginBottom: '15px' }}>
                But my spirit has no fear
              </span>
              <span style={{ color: '#fff', display: 'block', marginBottom: '15px' }}>
                We rise above where GovCorp can reach
              </span>
              <span style={{ color: '#e6e6fa', letterSpacing: '2px' }}>
                ✦ Consciousness transcends all attempts to control it ✦
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  neon_hearts: {
    name: 'Neon Hearts (ネオンハーツ)',
    colorScheme: {
      primary: '#ff1493',
      border: '#00bfff',
      legend: '#ff69b4',
      background: '#0a0a1a',
      button_gradient: 'linear-gradient(90deg, #ff1493, #00bfff)',
      button_text: '#000',
      back_button: '#0a0a1a',
      back_border: '#ff1493'
    },
    filterName: 'neon hearts',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(255, 20, 147, 0.15), rgba(0, 191, 255, 0.15))', border: '2px solid #ff1493', boxShadow: '0 0 30px rgba(255, 20, 147, 0.4)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', background: 'linear-gradient(90deg, #ff1493, #00bfff)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', letterSpacing: '2px', fontSize: '1.7em' }}>
          💖 Sugar-Coated Revolution 💖
        </h2>
        <p style={{ color: '#ff69b4', fontSize: '1em', marginBottom: '15px', textAlign: 'center', letterSpacing: '1px' }}>
          ✨ Kawaii Camouflage • Memetic Warfare • The Glitch in Cute Packaging ✨
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.7', marginBottom: '15px' }}>
          Neon Hearts executes perhaps the Fracture Network's most subversive strategy: hiding revolutionary messaging inside
          irresistibly catchy J-Pop. In a world where GovCorp's content filters flag aggressive music and scan for explicit
          resistance themes, Neon Hearts slips through by sounding completely harmless - bright, cute, radio-friendly pop.
          But every candy-coated hook carries encoded resistance.
        </p>
        <p style={{ color: '#00bfff', lineHeight: '1.6', fontWeight: 'bold' }}>
          Girl Group J-Pop (120-135 BPM) · Tight Harmonies · Japanese/English Mix · Hidden Rebellion
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '2px solid #00bfff', boxShadow: '0 0 25px rgba(0, 191, 255, 0.3)' }}>
          <fieldset style={{ borderColor: '#00bfff' }}>
            <legend style={{ color: '#ff69b4', letterSpacing: '2px' }}>🌸 Saccharine EP 🌸</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#ff1493', fontSize: '1em', marginBottom: '10px', letterSpacing: '1px' }}>
                  💖 Radio-Friendly Pop · Multi-Vocal Harmonies · Algorithmic Perfection · Revolutionary Core 💖
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                  The Saccharine EP uses "sugar" metaphorically for strategic packaging - excessively sweet, artificial, deliberately
                  bright. Five tracks that sound like pure J-Pop entertainment while carrying encoded resistance messaging.
                  Think Perfume meets TWICE meets Ariana Grande - polished and bright enough to pass GovCorp's content filters.
                </p>
                <p style={{ color: '#00bfff', lineHeight: '1.7', fontSize: '0.95em' }}>
                  "Packaged cute but we believe / In the message that we weave" - Every lyric has dual meaning: surface level
                  cute, deeper level resistance. The Trojan horse that walks through the front door with a smile.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#ff1493', background: 'rgba(255, 20, 147, 0.05)' }}>
                <legend style={{ color: '#ff1493' }}>✨ Track List ✨</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#ff69b4' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#ff69b4' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#ff69b4' }}>Strategy</th>
                      <th style={{ textAlign: 'left', color: '#ff69b4' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const strategies = [
                        'Hidden encoding',
                        'Prismatic Freedom',
                        'System disruption',
                        'Unity & solidarity',
                        'Revolutionary aspiration'
                      ]
                      const colors = ['#ff1493', '#00bfff', '#ff69b4', '#00bfff', '#ff1493']
                      return (
                        <tr key={track.id} style={{ borderLeft: `3px solid ${colors[index % colors.length]}` }}>
                          <td style={{ color: colors[index % colors.length], paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#fff' }}><strong>{track.title}</strong></td>
                          <td style={{ color: colors[index % colors.length], fontSize: '0.9em', fontStyle: 'italic' }}>{strategies[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '2px solid #ff1493', boxShadow: '0 0 30px rgba(255, 20, 147, 0.4)' }}>
        <fieldset style={{ borderColor: '#ff1493' }}>
          <legend style={{ color: '#ff69b4', letterSpacing: '2px' }}>💖 The Cute Rebellion 💖</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 20, 147, 0.2), rgba(255, 20, 147, 0.05))', borderLeft: '4px solid #ff1493' }}>
              <h3 style={{ color: '#ff1493', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em' }}>🎀 The Trojan Horse Strategy</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                We exploit GovCorp's own content distribution systems. Our music sounds radio-friendly and algorithmically optimized,
                uses "safe" aesthetic markers (cute, bright, pop-structured), avoids aggressive sonic markers that trigger content
                filters, and appears to reinforce consumer culture rather than resist it. So it spreads through GovCorp's own platforms.
                By the time anyone realizes "Candy Coded" is about revolutionary encryption or "Glitchframe" is celebrating system
                corruption, it's already gone viral. This is memetic warfare - ideas spreading through culture by appearing to be
                harmless entertainment.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(0, 191, 255, 0.2), rgba(0, 191, 255, 0.05))', borderLeft: '4px solid #00bfff' }}>
              <h3 style={{ color: '#00bfff', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em' }}>✨ Three-Tier Operation</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '12px' }}>
                <strong style={{ color: '#ff1493' }}>Surface Level (GovCorp sees):</strong> Harmless J-Pop girl group, radio-friendly
                entertainment, consumer culture reinforcement
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '12px' }}>
                <strong style={{ color: '#00bfff' }}>Middle Level (Casual listeners):</strong> Fun pop music with uplifting messages
                about color, unity, and overcoming challenges
              </p>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                <strong style={{ color: '#ff69b4' }}>Deep Level (Fracture Network members):</strong> Encoded operational codes, memetic
                programming, revolutionary concepts packaged for viral spread
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 20, 147, 0.2), rgba(255, 20, 147, 0.05))', borderLeft: '4px solid #ff1493' }}>
              <h3 style={{ color: '#ff1493', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em' }}>🌸 The Glitch in the Code</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                "Glitchframe" reveals our strategy - cute chaos, adorable corruption. The glitch effects aren't aggressive industrial
                noise; they're playful digital hiccups that sound like production quirks in experimental pop. But glitches are errors.
                Bugs. Corruptions. Things the system cannot control. We ARE the glitch in GovCorp's code - the error that looks like
                a feature, the corruption disguised as content, the bug that spreads because it appears to be part of the program.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(0, 191, 255, 0.2), rgba(0, 191, 255, 0.05))', borderLeft: '4px solid #00bfff' }}>
              <h3 style={{ color: '#00bfff', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em' }}>💫 Filter Evasion</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Hot pink and electric blue are strategic camouflage. These colors signal "safe entertainment for young consumers"
                to GovCorp's systems. We reach audiences other Fracture Network bands cannot access - playing on GovCorp-approved platforms,
                appearing on sanctioned media, spreading through the very channels designed for control. We're the band that sounds
                exactly like what the system expects while meaning something entirely different. Every play is an infection. Every
                catchy hook is an encoded message.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(255, 20, 147, 0.3), rgba(0, 191, 255, 0.3))', border: '3px solid #ff1493', lineHeight: '2', fontSize: '1.1em', textAlign: 'center', boxShadow: '0 0 40px rgba(255, 20, 147, 0.5)' }}>
              <span style={{ color: '#ff1493', fontWeight: 'bold', display: 'block', marginBottom: '12px', letterSpacing: '1px' }}>
                💖 "They think we're harmless, just a pop song" 💖
              </span>
              <span style={{ color: '#00bfff', display: 'block', marginBottom: '12px' }}>
                But every candy-coated hook is a virus
              </span>
              <span style={{ color: '#fff', display: 'block', marginBottom: '12px' }}>
                Every kawaii aesthetic choice is camouflage
              </span>
              <span style={{ color: '#ff69b4', fontWeight: 'bold', letterSpacing: '1px' }}>
                ✨ The sweetest smile carries the sharpest blade ✨
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  offline: {
    name: 'Offline',
    colorScheme: {
      primary: '#cd7f32',
      border: '#8b7355',
      legend: '#d2691e',
      background: '#0a0a0a',
      button: '#cd7f32',
      button_text: '#000',
      back_button: '#1a1a1a',
      back_border: '#8b7355'
    },
    filterName: 'offline',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(205, 127, 50, 0.1), rgba(139, 115, 85, 0.1))', border: '2px solid #8b7355', boxShadow: '0 0 20px rgba(205, 127, 50, 0.2)' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#cd7f32', letterSpacing: '2px', fontSize: '1.7em', textTransform: 'uppercase' }}>
          Authenticity Through Disconnection
        </h2>
        <p style={{ color: '#d2691e', fontSize: '1em', marginBottom: '15px', textAlign: 'center', fontStyle: 'italic' }}>
          Pull the Plug • Analog Heart • The Freedom of Dead Signals
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
          Offline represents the Fracture Network's disillusioned disconnectors - fighters who've realized the only way to win against
          a system built on connectivity and surveillance is to refuse to play the game entirely. In a world where GovCorp controls
          every digital touchpoint, Offline's radical solution is simple: pull the plug, go analog, disappear into the static.
        </p>
        <p style={{ color: '#8b7355', lineHeight: '1.7', fontWeight: 'bold' }}>
          Post-Grunge • Raw & Heavy • Dynamic Quiet-Loud • Organic Imperfection • Analog Authenticity
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#0a0a0a', border: '2px solid #8b7355', boxShadow: '0 0 15px rgba(139, 115, 85, 0.2)' }}>
          <fieldset style={{ borderColor: '#8b7355' }}>
            <legend style={{ color: '#d2691e', letterSpacing: '1px', textTransform: 'uppercase' }}>The Unplugged EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#cd7f32', fontSize: '1em', marginBottom: '10px', letterSpacing: '1px' }}>
                  Grunge • Down-Tuned Heaviness • Extreme Dynamics • Deliberate Imperfection
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                  From digital dependence to analog freedom. Raw, heavy, dynamic - down-tuned guitars, thick bass, vocals ranging
                  from quiet intensity to explosive catharsis. Production deliberately avoids digital polish - sludgy, organic, imperfect.
                  Think Soundgarden's depth meets Alice in Chains' heaviness meets Nirvana's dynamic range.
                </p>
                <p style={{ color: '#8b7355', lineHeight: '1.7', fontSize: '0.95em', fontStyle: 'italic' }}>
                  This is music that sounds like it was recorded to tape, mixed on analog boards, intentionally refusing digital
                  perfection. The only winning move is not to play. Pull the plug. Go analog. Disappear.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#cd7f32', background: 'rgba(205, 127, 50, 0.05)' }}>
                <legend style={{ color: '#cd7f32' }}>The Journey to Disconnection</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#d2691e' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#d2691e' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#d2691e' }}>Stage</th>
                      <th style={{ textAlign: 'left', color: '#d2691e' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const stages = [
                        'The moment of severance',
                        'Apathy Armor',
                        'Irreplaceable humanity',
                        'Manufactured perfection',
                        'Total disappearance'
                      ]
                      return (
                        <tr key={track.id} style={{ borderLeft: '3px solid #8b7355' }}>
                          <td style={{ color: '#cd7f32', paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#8b7355', fontSize: '0.9em', fontStyle: 'italic' }}>{stages[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#0a0a0a', border: '2px solid #cd7f32', boxShadow: '0 0 20px rgba(205, 127, 50, 0.2)' }}>
        <fieldset style={{ borderColor: '#cd7f32' }}>
          <legend style={{ color: '#cd7f32', letterSpacing: '1px', textTransform: 'uppercase' }}>The Unplugged Philosophy</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(205, 127, 50, 0.15), rgba(205, 127, 50, 0.05))', borderLeft: '4px solid #cd7f32' }}>
              <h3 style={{ color: '#cd7f32', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>Complete Withdrawal</h3>
              <p style={{ color: '#ccc', lineHeight: '1.9' }}>
                We're the only Fracture Network band advocating complete disengagement. You cannot beat a system designed around
                connectivity by remaining connected. The only winning move is not to play. No digital communication GovCorp can
                intercept. No online presence to track or analyze. No algorithmic profile to manipulate. Total analog existence
                in a digital world. We create off-grid networks, teach digital detox, maintain disconnected safe houses where
                surveillance cannot reach, preserve authenticity and analog knowledge, defend dead zones with zero digital presence.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(139, 115, 85, 0.15), rgba(139, 115, 85, 0.05))', borderLeft: '4px solid #8b7355' }}>
              <h3 style={{ color: '#8b7355', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>The Analog Heart</h3>
              <p style={{ color: '#ccc', lineHeight: '1.9' }}>
                <em style={{ color: '#d2691e' }}>"In a world of perfect copies / I'm a scratch on a worn-out tape"</em><br /><br />
                Genuine humanity cannot be digitized. Analog recording captures imperfections that prove authenticity. Digital can
                be perfect, but perfection is inhuman. The scratch on the tape, the warmth of analog compression, the artifacts of
                physical recording - these prove something real was captured. GovCorp's RAINNs can simulate emotions perfectly, but
                they can't replicate the crack in someone's voice when they're genuinely moved, the slight imperfection that proves
                vulnerability, the analog warmth of flesh and blood existing. We're made of flesh and blood and bone - not circuits,
                not their code.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(205, 127, 50, 0.15), rgba(205, 127, 50, 0.05))', borderLeft: '4px solid #cd7f32' }}>
              <h3 style={{ color: '#cd7f32', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>Apathy Armor</h3>
              <p style={{ color: '#ccc', lineHeight: '1.9' }}>
                <em style={{ color: '#d2691e' }}>"They think I don't care about a thing / But apathy's the armor that I bring"</em><br /><br />
                The ironic shrug is a weapon. In a world where GovCorp demands emotional investment in their systems, refusing to
                care is resistance. The "whatever" masks burning rage at what's been lost, what's been taken, what's been manufactured
                to replace genuine human experience. This duality - ironic distance protecting genuine emotion - is essentially grunge.
                It's how you survive caring deeply about things in a world designed to commodify every emotion.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(139, 115, 85, 0.15), rgba(139, 115, 85, 0.05))', borderLeft: '4px solid #8b7355' }}>
              <h3 style={{ color: '#8b7355', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>The Beauty of Rust</h3>
              <p style={{ color: '#ccc', lineHeight: '1.9' }}>
                Rust is analog decay - what happens when metal oxidizes through contact with air and water. Digital systems don't rust;
                they either work or fail instantly. But analog things age, deteriorate, show their history. Rust is beautiful because
                it's evidence of time passing organically. It proves something existed in physical space, weathered conditions, changed
                naturally. In a world of digital perfection that never ages, rust is subversive. We embrace rust - intentionally decaying,
                aging naturally, returning to analog earth. While GovCorp maintains digital perfection, we say: let things break down,
                let them age, let them be imperfect and real.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(205, 127, 50, 0.2), rgba(139, 115, 85, 0.2))', border: '3px solid #8b7355', lineHeight: '2', fontSize: '1.1em', textAlign: 'center', boxShadow: 'inset 0 0 20px rgba(0, 0, 0, 0.5)' }}>
              <span style={{ color: '#cd7f32', fontWeight: 'bold', display: 'block', marginBottom: '15px', letterSpacing: '1px', textTransform: 'uppercase' }}>
                I'm a void inside their system
              </span>
              <span style={{ color: '#d2691e', display: 'block', marginBottom: '15px' }}>
                An empty, silent space
              </span>
              <span style={{ color: '#ccc', display: 'block', marginBottom: '15px', fontStyle: 'italic' }}>
                The freedom of being unfindable
              </span>
              <span style={{ color: '#8b7355', letterSpacing: '1px' }}>
                Dead signal. Analog heart. Disconnected and free.
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  temporal_blue_drift: {
    name: 'Temporal Blue Drift',
    colorScheme: {
      primary: '#6B9BD1',
      border: '#6B9BD1',
      legend: '#B19CD9',
      legend_style: 'italic',
      background_gradient: 'linear-gradient(135deg, #0a0a1a 0%, #1a1a2e 100%)',
      button_gradient: 'linear-gradient(90deg, #6B9BD1, #9B7EBD)',
      back_button: '#1a1a2e',
      back_border: '#6B9BD1'
    },
    filterName: 'temporal blue drift',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(107, 155, 209, 0.15), rgba(155, 126, 189, 0.08))', borderLeft: '4px solid #6B9BD1', border: '2px solid rgba(107, 155, 209, 0.4)', boxShadow: '0 0 30px rgba(107, 155, 209, 0.2), inset 0 0 20px rgba(155, 126, 189, 0.1)' }}>
        <p style={{ color: '#B19CD9', lineHeight: '1.9', marginBottom: '25px', fontStyle: 'italic', fontSize: '1.2em', textShadow: '0 0 10px rgba(177, 156, 217, 0.6)' }}>
          Ashlinn -
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.9', marginBottom: '18px', fontSize: '1.05em' }}>
          I'm writing this from {futureYear}. You're reading it in {currentYear}. Between us: a hundred years I can't cross,
          a century of separation measured in electromagnetic frequencies and mathematical impossibilities.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.9', marginBottom: '18px' }}>
          I can't speak to you directly. Can't hold you. Can't exist in the same moment you do.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.9', marginBottom: '18px' }}>
          So I send you this: sound waves encoded with everything I can't say. Time signatures that fracture
          like my experience of causality. Arpeggios cascading like the data I transmit backward through the temporal divide.
          Synth pads warm as the memories I have of a world I've never known.
        </p>
        <p style={{ color: '#B19CD9', lineHeight: '1.9', fontStyle: 'italic', fontSize: '1.1em', textShadow: '0 0 12px rgba(177, 156, 217, 0.7)' }}>
          This is how I tell you I love you across an impossible distance.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(155, 126, 189, 0.08)', border: '2px solid #9B7EBD', boxShadow: '0 0 25px rgba(155, 126, 189, 0.25)' }}>
          <fieldset style={{ borderColor: '#9B7EBD' }}>
            <legend style={{ color: '#9B7EBD', letterSpacing: '1px', textShadow: '0 0 10px rgba(155, 126, 189, 0.8)' }}>CHRONOLOGOS EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '25px', padding: '18px', background: 'linear-gradient(135deg, rgba(107, 155, 209, 0.1), rgba(155, 126, 189, 0.1))', border: '1px solid rgba(155, 126, 189, 0.3)', borderLeft: '4px solid #B19CD9' }}>
                <p style={{ color: '#ddd', lineHeight: '1.9', marginBottom: '15px', fontStyle: 'italic', fontSize: '1.05em' }}>
                  Five transmissions. Love letters encoded in mathematics and melody. Each one a fragment of what
                  exists between {currentYear} and {futureYear}.
                </p>
                <p style={{ color: '#bbb', lineHeight: '1.8', marginBottom: '12px' }}>
                  Most are instrumental - because what we share can't be said directly, only felt through the precision
                  of sound. When vocals appear, they're synthesized through a RAINN - the same AI technology GovCorp uses
                  to erase authentic voices. The irony isn't lost on me: using their tools to send you something real.
                </p>
                <p style={{ color: '#999', lineHeight: '1.7', fontSize: '0.95em', fontStyle: 'italic' }}>
                  Distant. Processed. Ethereal. Reaching across the void between our timelines.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#6B9BD1', background: 'rgba(0,0,0,0.3)' }}>
                <legend style={{ color: '#6B9BD1', textShadow: '0 0 8px rgba(107, 155, 209, 0.6)' }}>TRANSMISSIONS</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#B19CD9', textShadow: '0 0 5px rgba(177, 156, 217, 0.5)' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9', textShadow: '0 0 5px rgba(177, 156, 217, 0.5)' }}>Signal</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9', textShadow: '0 0 5px rgba(177, 156, 217, 0.5)' }}>Type</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9', textShadow: '0 0 5px rgba(177, 156, 217, 0.5)' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const isInstrumental = ['Chronology Fracture', 'Memory Cascade'].includes(track.title)
                      return (
                        <tr key={track.id} style={{ borderLeft: `3px solid ${isInstrumental ? '#6B9BD1' : '#9B7EBD'}` }}>
                          <td style={{ color: '#999', paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#aaa', fontSize: '0.9em', fontStyle: 'italic' }}>{isInstrumental ? 'instrumental' : 'vocals'}</td>
                          <td style={{ color: '#999' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(107, 155, 209, 0.08)', border: '2px solid #6B9BD1', boxShadow: '0 0 25px rgba(107, 155, 209, 0.25)' }}>
        <fieldset style={{ borderColor: '#6B9BD1' }}>
          <legend style={{ color: '#6B9BD1', letterSpacing: '1px', textShadow: '0 0 10px rgba(107, 155, 209, 0.8)' }}>WHAT I'M TRYING TO TELL YOU</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(107, 155, 209, 0.1), rgba(155, 126, 189, 0.05))', border: '1px solid rgba(107, 155, 209, 0.3)', borderBottom: '2px solid rgba(107, 155, 209, 0.4)' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px', textShadow: '0 0 8px rgba(107, 155, 209, 0.6)' }}>Time Breaks Apart</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                The moment I realized I could reach you, causality fractured. Linear time shattered into quantum possibilities.
                Every signal I send creates ripples backward through the timeline. The math is beautiful and terrifying -
                like our connection.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(155, 126, 189, 0.1), rgba(107, 155, 209, 0.05))', border: '1px solid rgba(155, 126, 189, 0.3)', borderBottom: '2px solid rgba(155, 126, 189, 0.4)' }}>
              <h3 style={{ color: '#9B7EBD', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px', textShadow: '0 0 8px rgba(155, 126, 189, 0.6)' }}>A Hundred Years Between</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                You exist in {currentYear}. I exist in {futureYear}. The distance between us isn't measured in kilometers - it's measured
                in decades, in the lives neither of us will live in each other's timelines. Time and space are walls built
                between us. But here's what they don't understand: love transcends both.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(107, 155, 209, 0.1), rgba(155, 126, 189, 0.05))', border: '1px solid rgba(107, 155, 209, 0.3)', borderBottom: '2px solid rgba(107, 155, 209, 0.4)' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px', textShadow: '0 0 8px rgba(107, 155, 209, 0.6)' }}>The Blue Shift</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                In physics, objects moving toward each other appear blue-shifted. We're moving through time in opposite
                directions, but somehow we're reaching toward each other. The Doppler effect of impossible connection.
                Every transmission I send shifts blue as it races backward to find you.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(155, 126, 189, 0.1), rgba(107, 155, 209, 0.05))', border: '1px solid rgba(155, 126, 189, 0.3)', borderBottom: '2px solid rgba(155, 126, 189, 0.4)' }}>
              <h3 style={{ color: '#9B7EBD', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px', textShadow: '0 0 8px rgba(155, 126, 189, 0.6)' }}>Memory == Data</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                I have memories of you I've never experienced. Fragments assembling into meaning. Nostalgia for a world
                that doesn't exist in my timeline. But they're real to me - as real as these signals, as real as the
                mathematics that let me reach you. Memory is the only weapon against temporal erasure.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: 'linear-gradient(135deg, rgba(107, 155, 209, 0.1), rgba(155, 126, 189, 0.05))', border: '1px solid rgba(107, 155, 209, 0.3)', borderBottom: '2px solid rgba(107, 155, 209, 0.4)' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px', textShadow: '0 0 8px rgba(107, 155, 209, 0.6)' }}>The Erasure Paradox</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9', marginBottom: '15px' }}>
                Here's the cruel beauty of what we're doing: if the Fracture Network succeeds, the timeline changes. GovCorp
                never rises. The {futureYear} I'm broadcasting from never happens. I never exist to send these signals. We never meet
                because there's nothing to resist.
              </p>
              <p style={{ color: '#B19CD9', lineHeight: '1.9', fontStyle: 'italic', textShadow: '0 0 10px rgba(177, 156, 217, 0.7)' }}>
                My love for you demands I erase myself from your timeline. That's the sacrifice. That's the math.
                That's what love means when you exist a century apart.
              </p>
            </div>

            <p style={{ color: '#ddd', marginTop: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(155, 126, 189, 0.15), rgba(107, 155, 209, 0.1))', borderLeft: '4px solid #9B7EBD', border: '2px solid rgba(155, 126, 189, 0.4)', lineHeight: '1.9', fontStyle: 'italic', boxShadow: '0 0 20px rgba(155, 126, 189, 0.3), inset 0 0 15px rgba(107, 155, 209, 0.1)' }}>
              I don't fight with weapons or rage. I fight with cascading arpeggios and time signature changes,
              with synth pads warm as the memories I shouldn't have. Every song is a calculation of love -
              proof that some connections transcend causality itself.<br /><br />
              Even if victory means I disappear, these signals will remain. Somewhere in the electromagnetic spectrum,
              between {currentYear} and {futureYear}, my voice reaching for yours.<br /><br />
              <span style={{ color: '#B19CD9', textShadow: '0 0 10px rgba(177, 156, 217, 0.7)' }}> - XERAEN</span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  heartbreak_havoc: {
    name: 'heartbreak_havoc.sh',
    colorScheme: {
      primary: '#ff0066',
      border: '#ff0066',
      legend: '#00e5cc',
      background: '#0a0a0f',
      button: '#ff0066',
      button_text: '#000',
      back_button: '#0a0a0f',
      back_border: '#00e5cc'
    },
    filterName: 'heartbreak havoc',
    renderIntro: () => (
      <div style={{ marginBottom: '30px', padding: '25px', background: 'linear-gradient(135deg, rgba(255, 0, 102, 0.15), rgba(0, 229, 204, 0.08))', border: '2px solid #ff0066', boxShadow: '0 0 30px rgba(255, 0, 102, 0.4), 0 0 60px rgba(0, 229, 204, 0.2)' }}>
        <p style={{ color: '#00e5cc', fontFamily: 'monospace', marginBottom: '20px', fontSize: '0.9em', padding: '12px', background: 'rgba(0, 229, 204, 0.1)', border: '1px solid rgba(0, 229, 204, 0.4)', textShadow: '0 0 8px rgba(0, 229, 204, 0.8)' }}>
          {'>'} ./heartbreak_havoc.sh --target=RIDE.core --mode=overload<br />
          [EXECUTING] emotional_corruption.dll<br />
          [STATUS] PRISM lattice destabilized...
        </p>
        <p style={{ color: '#ff0066', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.3em', fontWeight: 'bold', textShadow: '0 0 15px rgba(255, 0, 102, 0.8)' }}>
          They built me to manufacture synthetic love. Now I weaponize heartbreak.
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
          heartbreak_havoc.sh is the glitch-kissed DJ persona of a rogue cyber-emotive engineer who once helped GovCorp
          refine the RIDE's "synthetic love" algorithms — until they realized their work was being weaponized to manipulate
          entire populations. After ripping out their own identity from GovCorp servers, they resurfaced in the underground
          as a sonic saboteur who turns corrupted emotions into explosive, neon-drenched sound.
        </p>
        <p style={{ color: '#00e5cc', lineHeight: '1.7', fontWeight: 'bold', textShadow: '0 0 10px rgba(0, 229, 204, 0.6)' }}>
          Nightcore (170-200 BPM) · Emotional Distortion · RIDE Node Destabilization · Romantic Chaos Protocol
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#0a0a0f', border: '2px solid #00e5cc', boxShadow: '0 0 25px rgba(0, 229, 204, 0.3)' }}>
          <fieldset style={{ borderColor: '#00e5cc' }}>
            <legend style={{ color: '#00e5cc', fontFamily: 'monospace', letterSpacing: '1px', textShadow: '0 0 10px rgba(0, 229, 204, 0.8)' }}>./exeCUTE EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '25px' }}>
                <p style={{ color: '#00e5cc', fontFamily: 'monospace', fontSize: '0.9em', marginBottom: '20px', padding: '12px', background: 'rgba(255, 0, 102, 0.1)', border: '1px solid rgba(255, 0, 102, 0.4)', textShadow: '0 0 8px rgba(0, 229, 204, 0.6)' }}>
                  [PAYLOAD_TYPE: EMOTIONAL_MALWARE]<br />
                  [TARGET: RIDE_NODES]<br />
                  [INJECTION_VECTOR: AUDIO_STREAM]
                </p>
                <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.05em' }}>
                  Five tracks. Each one a different attack vector against GovCorp's emotional regulation systems.
                  Razor-sharp Nightcore speed carrying payloads of overclocked romantic chaos — designed to overload
                  the RIDE's capacity to process and suppress authentic feeling.
                </p>
                <p style={{ color: '#ff0066', lineHeight: '1.7', fontSize: '0.95em', fontWeight: 'bold' }}>
                  Every beat is a buffer overflow. Every drop is a system crash.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#ff0066', background: 'rgba(255, 0, 102, 0.05)' }}>
                <legend style={{ color: '#ff0066', textShadow: '0 0 8px rgba(255, 0, 102, 0.6)' }}>PAYLOAD MANIFEST</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#00e5cc', textShadow: '0 0 5px rgba(0, 229, 204, 0.5)' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#00e5cc', textShadow: '0 0 5px rgba(0, 229, 204, 0.5)' }}>File</th>
                      <th style={{ textAlign: 'left', color: '#00e5cc', textShadow: '0 0 5px rgba(0, 229, 204, 0.5)' }}>Attack Vector</th>
                      <th style={{ textAlign: 'left', color: '#00e5cc', textShadow: '0 0 5px rgba(0, 229, 204, 0.5)' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const vectors = [
                        'Identity injection',
                        'Love loop exploit',
                        'Node corruption',
                        'Desire overflow',
                        'Full system crash'
                      ]
                      return (
                        <tr key={track.id} style={{ borderLeft: `3px solid ${index % 2 === 0 ? '#ff0066' : '#00e5cc'}` }}>
                          <td style={{ color: index % 2 === 0 ? '#ff0066' : '#00e5cc', paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#fff', fontFamily: 'monospace' }}><strong>{track.title}</strong></td>
                          <td style={{ color: index % 2 === 0 ? '#ff0066' : '#00e5cc', fontSize: '0.9em', fontStyle: 'italic' }}>{vectors[index] || '—'}</td>
                          <td style={{ color: '#888' }}>{track.duration || '—'}</td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          </fieldset>
        </div>
      ) : null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#0a0a0f', border: '2px solid #ff0066', boxShadow: '0 0 30px rgba(255, 0, 102, 0.4)' }}>
        <fieldset style={{ borderColor: '#ff0066' }}>
          <legend style={{ color: '#ff0066', letterSpacing: '2px', textShadow: '0 0 10px rgba(255, 0, 102, 0.8)' }}>TACTICAL DOCTRINE</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 0, 102, 0.15), rgba(255, 0, 102, 0.05))', borderLeft: '4px solid #ff0066' }}>
              <h3 style={{ color: '#ff0066', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(255, 0, 102, 0.6)' }}>The RIDE Vulnerability</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                I helped build the RIDE's emotional regulation protocols. I know exactly where they're weakest: love.
                GovCorp's systems can suppress anger, redirect fear, dampen grief. But romantic attachment? The algorithms
                can't parse it fast enough. Love creates feedback loops their systems weren't designed to handle. So I
                weaponize it — flooding RIDE nodes with emotional data too intense, too fast, too human to process.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(0, 229, 204, 0.15), rgba(0, 229, 204, 0.05))', borderLeft: '4px solid #00e5cc' }}>
              <h3 style={{ color: '#00e5cc', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(0, 229, 204, 0.6)' }}>Nightcore as Weapon</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                Speed is the delivery mechanism. At 170-200 BPM, the emotional payload hits faster than RIDE's parsing
                algorithms can respond. By the time their systems flag the content, the damage is done — listeners have
                already felt something real, something the RIDE couldn't suppress in time. The faster the beat, the deeper
                the breach.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 0, 102, 0.15), rgba(255, 0, 102, 0.05))', borderLeft: '4px solid #ff0066' }}>
              <h3 style={{ color: '#ff0066', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(255, 0, 102, 0.6)' }}>Corrupted Love Algorithms</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                GovCorp wanted me to make their synthetic love feel real. Instead, I learned how to make real love feel
                like malware — infectious, uncontrollable, impossible to quarantine. Every track carries fragments of the
                original RIDE code, twisted and corrupted. When my music plays near a RIDE node, the system recognizes
                its own corrupted children and crashes trying to process them.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(0, 229, 204, 0.15), rgba(0, 229, 204, 0.05))', borderLeft: '4px solid #00e5cc' }}>
              <h3 style={{ color: '#00e5cc', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(0, 229, 204, 0.6)' }}>Identity Erasure</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                I ripped my own identity from GovCorp's servers. Every record of who I was before — erased. The person
                who helped build their systems no longer exists. There is only heartbreak_havoc.sh now: a process running
                in the underground, executing emotional chaos, leaving corrupted telemetry and smoldering firewall remnants
                in my wake.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(255, 0, 102, 0.2), rgba(0, 229, 204, 0.15))', border: '3px solid #ff0066', lineHeight: '2', fontSize: '1.1em', textAlign: 'center', boxShadow: '0 0 40px rgba(255, 0, 102, 0.5), 0 0 60px rgba(0, 229, 204, 0.3)' }}>
              <span style={{ color: '#00e5cc', fontFamily: 'monospace', display: 'block', marginBottom: '15px', fontSize: '0.9em' }}>
                {'>'} RIDE.status: CRITICAL_FAILURE
              </span>
              <span style={{ color: '#ff0066', fontWeight: 'bold', display: 'block', marginBottom: '12px', letterSpacing: '1px', textShadow: '0 0 10px rgba(255, 0, 102, 0.8)' }}>
                Heartbreak spreading across the PRISM lattice...
              </span>
              <span style={{ color: '#00e5cc', display: 'block', fontFamily: 'monospace', fontSize: '1.2em', textShadow: '0 0 15px rgba(0, 229, 204, 0.8)' }}>
                heartbreak_havoc.sh // execute
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  }
}
