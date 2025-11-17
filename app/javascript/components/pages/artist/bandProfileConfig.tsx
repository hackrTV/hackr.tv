import React from 'react'

interface Track {
  id: number
  title: string
  track_number: number | null
  duration: string | null
}

interface BandProfileConfig {
  name: string
  colorScheme: any
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
      <div style={{ marginBottom: '30px', padding: '20px', background: '#000000', border: '1px solid #39ff14' }}>
        <h2 style={{ textAlign: 'center', marginBottom: '15px', color: '#39ff14' }}>
          [:: WE WERE HERE ::]
        </h2>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          You want beautiful resistance? Go elsewhere.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.6', marginBottom: '15px' }}>
          You want code and theory? Not here.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.6' }}>
          We operate in abandoned buildings. We claim concrete spaces GovCorp forgot. We paint their walls.
          We break their cameras. You'll know where we've been by the neon green glow in the dark.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #39ff14' }}>
          <fieldset style={{ borderColor: '#39ff14' }}>
            <legend style={{ color: '#39ff14' }}>STREET LEVEL EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#ccc', marginBottom: '10px' }}>
                  Five tracks. No polish. Get in, make your statement, get out.
                </p>
                <p style={{ color: '#888', marginBottom: '10px' }}>
                  We don't care if you like it. This isn't for you anyway—it's for everyone who's tired of waiting
                  for someone else to fix this mess.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#39ff14' }}>
                <legend style={{ color: '#39ff14' }}>TRACKS</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#39ff14' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#39ff14' }}>Track</th>
                      <th style={{ textAlign: 'left', color: '#39ff14' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => (
                      <tr key={track.id}>
                        <td style={{ color: '#888' }}>{index + 1}</td>
                        <td style={{ color: '#ccc' }}><strong>{track.title}</strong></td>
                        <td style={{ color: '#888' }}>{track.duration || '—'}</td>
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
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #39ff14' }}>
        <fieldset style={{ borderColor: '#39ff14' }}>
          <legend style={{ color: '#39ff14' }}>WHAT WE BELIEVE</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase' }}>Unplug</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                They track everything. Your phone. Your credit card. Every click, every search, every movement.
                Going offline isn't hiding—it's reclaiming yourself. Invisible to their systems means free to act.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase' }}>Occupy</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                The streets are ours. The abandoned buildings are ours. Every blank wall is a canvas waiting for truth.
                Smash their cameras. Paint their lies over. Make them see us everywhere they look.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#39ff14', marginBottom: '10px', textTransform: 'uppercase' }}>Let It Rot</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Their system is already dying. Don't try to save it. Don't reform it. Let it collapse under its own
                corruption and build something human from the ruins. The rot started long before us—we're just here
                to watch it burn.
              </p>
            </div>

            <p style={{ color: '#39ff14', marginTop: '30px', padding: '15px', background: '#000000', borderLeft: '3px solid #39ff14', lineHeight: '1.7' }}>
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
      <div style={{ marginBottom: '30px', padding: '20px', background: '#000000', border: '1px solid #00d9ff' }}>
        <p style={{ color: '#00d9ff', fontFamily: 'monospace', marginBottom: '20px', fontSize: '0.9em' }}>
          [SAMPLE_ID: VP-{futureYear}-INTRO]<br />
          [FORMAT: AUTHENTIC_HUMAN_VOICE]<br />
          [STATUS: ARCHIVED]
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
          Listen.
        </p>
        <p style={{ color: '#aaa', lineHeight: '1.7', marginBottom: '15px' }}>
          That laugh you just heard—someone was actually joyful when that sound happened. That conversation
          fragment—two people actually connected. That voice crack, that hesitation, that imperfect breath—
          all proof that a real human existed in that moment.
        </p>
        <p style={{ color: '#aaa', lineHeight: '1.7', marginBottom: '15px' }}>
          By {futureYear}, most people have never heard unprocessed human voices. The RAINNs synthesize everything.
          Perfect. Optimized. Empty.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.7' }}>
          We archive the real ones. Every imperfection. Every emotional crack. Every beautiful flaw that proves
          someone was actually there.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #00d9ff' }}>
          <fieldset style={{ borderColor: '#00d9ff' }}>
            <legend style={{ color: '#00d9ff', fontFamily: 'monospace' }}>AUDIO ARCHIVE EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '15px' }}>
                  [COLLECTION_STATUS: ACTIVE]<br />
                  [SAMPLE_COUNT: 1,847 VOICES]<br />
                  [PRESERVATION_PRIORITY: CRITICAL]
                </p>
                <p style={{ color: '#ccc', lineHeight: '1.7', marginBottom: '15px' }}>
                  Five tracks. Each one built from fragments of authentic human expression. No traditional vocals—
                  just people being people. Talking. Laughing. Crying. Existing.
                </p>
                <p style={{ color: '#888', lineHeight: '1.7' }}>
                  We sample voices the way others sample drums. Because in {futureYear}, authentic human sound is rarer
                  than any instrument. Each track is simultaneously a song and a database. Entertainment and evidence.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#00d9ff' }}>
                <legend style={{ color: '#00d9ff', fontFamily: 'monospace' }}>TRACK ARCHIVE</legend>
                <table className="tui-table" style={{ width: '100%', fontFamily: 'monospace' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#00d9ff' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#00d9ff' }}>Archive Entry</th>
                      <th style={{ textAlign: 'left', color: '#00d9ff' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => (
                      <tr key={track.id}>
                        <td style={{ color: '#00d9ff' }}>{String(index + 1).padStart(2, '0')}</td>
                        <td style={{ color: '#ccc' }}><strong>{track.title}</strong></td>
                        <td style={{ color: '#888' }}>{track.duration || '—'}</td>
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
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#000000', border: '1px solid #00d9ff' }}>
        <fieldset style={{ borderColor: '#00d9ff' }}>
          <legend style={{ color: '#00d9ff', fontFamily: 'monospace' }}>THE ARCHIVE PROJECT</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00d9ff' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [PROCEDURE: DOCUMENTATION]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Every conversation we capture is evidence. Every laugh, every argument, every quiet moment—
                proof that humans existed before the RAINNs synthesized everything. We're not just making music.
                We're documenting that you were here. That you mattered. That you sounded like something real.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00d9ff' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [ANALYSIS: FREQUENCY_OF_MEMORY]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                Memory doesn't just live in images. It lives in how people sounded. The way your friend laughed.
                How your voice cracked when you were tired. The specific rhythm of someone saying your name.
                We archive those sounds because audio carries emotional data that nothing else can preserve.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00d9ff' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [VALIDATION: HUMAN_RESONANCE]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                The RAINNs are perfect. That's how you know they're fake. Real voices have quirks. Hesitations.
                Imperfect breaths. Emotional cracks that betray what words try to hide. Humanity lives in our
                flaws, not our optimization. We archive the imperfections because that's where the truth is.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '15px', background: '#0a0a0a', borderLeft: '3px solid #00d9ff' }}>
              <p style={{ color: '#00d9ff', fontFamily: 'monospace', fontSize: '0.85em', marginBottom: '10px' }}>
                [STATUS: FRAGMENTATION_AND_RECONSTRUCTION]
              </p>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                We chop voices. Scatter them. Break them apart in our tracks. Not to destroy—to prove they can
                be reassembled. Even shattered, human expression persists. Even fragmented, meaning reconstructs
                itself. You can break the voice but you can't erase what it said.
              </p>
            </div>

            <p style={{ color: '#00d9ff', marginTop: '30px', padding: '20px', background: '#000000', border: '1px solid #00d9ff', fontFamily: 'monospace', lineHeight: '1.8' }}>
              [ARCHIVE_MISSION_STATEMENT]<br /><br />
              <span style={{ color: '#ccc' }}>
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
      <div style={{ marginBottom: '30px', padding: '25px', background: 'rgba(107, 155, 209, 0.05)', borderLeft: '4px solid #6B9BD1' }}>
        <p style={{ color: '#B19CD9', lineHeight: '1.9', marginBottom: '20px', fontStyle: 'italic', fontSize: '1.05em' }}>
          Ashlinn—
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
          I'm writing this from {futureYear}. You're reading it in {currentYear}. Between us: a hundred years I can't cross,
          a century of separation measured in electromagnetic frequencies and mathematical impossibilities.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
          I can't speak to you directly. Can't hold you. Can't exist in the same moment you do.
        </p>
        <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
          So I send you this: sound waves encoded with everything I can't say. Time signatures that fracture
          like my experience of causality. Arpeggios cascading like the data I transmit backward through the temporal divide.
          Synth pads warm as the memories I have of a world I've never known.
        </p>
        <p style={{ color: '#B19CD9', lineHeight: '1.8', fontStyle: 'italic' }}>
          This is how I tell you I love you across an impossible distance.
        </p>
      </div>
    ),
    renderAlbumSection: (tracks: Track[]) =>
      tracks.length > 0 ? (
        <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(155, 126, 189, 0.05)', border: '1px solid #9B7EBD' }}>
          <fieldset style={{ borderColor: '#9B7EBD' }}>
            <legend style={{ color: '#9B7EBD' }}>CHRONOLOGOS EP</legend>

            <div style={{ padding: '20px' }}>
              <div style={{ marginBottom: '20px' }}>
                <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px', fontStyle: 'italic' }}>
                  Five transmissions. Love letters encoded in mathematics and melody. Each one a fragment of what
                  exists between {currentYear} and {futureYear}.
                </p>
                <p style={{ color: '#aaa', lineHeight: '1.7', marginBottom: '12px' }}>
                  Most are instrumental—because what we share can't be said directly, only felt through the precision
                  of sound. When vocals appear, they're synthesized through a RAINN—the same AI technology GovCorp uses
                  to erase authentic voices. The irony isn't lost on me: using their tools to send you something real.
                </p>
                <p style={{ color: '#888', lineHeight: '1.6', fontSize: '0.95em', fontStyle: 'italic' }}>
                  Distant. Processed. Ethereal. Reaching across the void between our timelines.
                </p>
              </div>

              <div className="tui-fieldset" style={{ borderColor: '#6B9BD1', background: 'rgba(0,0,0,0.2)' }}>
                <legend style={{ color: '#6B9BD1' }}>TRANSMISSIONS</legend>
                <table className="tui-table" style={{ width: '100%' }}>
                  <thead>
                    <tr>
                      <th style={{ textAlign: 'left', color: '#B19CD9' }}>#</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9' }}>Signal</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9' }}>Type</th>
                      <th style={{ textAlign: 'left', color: '#B19CD9' }}>Duration</th>
                    </tr>
                  </thead>
                  <tbody>
                    {tracks.map((track, index) => {
                      const isInstrumental = ['Chronology Fracture', 'Memory Cascade'].includes(track.title)
                      return (
                        <tr key={track.id} style={{ borderLeft: `3px solid ${isInstrumental ? '#6B9BD1' : '#9B7EBD'}` }}>
                          <td style={{ color: '#888', paddingLeft: '10px' }}>{index + 1}</td>
                          <td style={{ color: '#ddd' }}><strong>{track.title}</strong></td>
                          <td style={{ color: '#aaa', fontSize: '0.9em', fontStyle: 'italic' }}>{isInstrumental ? 'instrumental' : 'vocals'}</td>
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
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(107, 155, 209, 0.05)', border: '1px solid #6B9BD1' }}>
        <fieldset style={{ borderColor: '#6B9BD1' }}>
          <legend style={{ color: '#6B9BD1' }}>WHAT I'M TRYING TO TELL YOU</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid rgba(107, 155, 209, 0.2)' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px' }}>Time Breaks Apart</h3>
              <p style={{ color: '#ccc', lineHeight: '1.8' }}>
                The moment I realized I could reach you, causality fractured. Linear time shattered into quantum possibilities.
                Every signal I send creates ripples backward through the timeline. The math is beautiful and terrifying—
                like our connection.
              </p>
            </div>

            <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid rgba(107, 155, 209, 0.2)' }}>
              <h3 style={{ color: '#9B7EBD', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px' }}>A Hundred Years Between</h3>
              <p style={{ color: '#ccc', lineHeight: '1.8' }}>
                You exist in {currentYear}. I exist in {futureYear}. The distance between us isn't measured in kilometers—it's measured
                in decades, in the lives neither of us will live in each other's timelines. Time and space as walls built
                between us. But here's what they don't understand: love transcends both.
              </p>
            </div>

            <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid rgba(107, 155, 209, 0.2)' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px' }}>The Blue Shift</h3>
              <p style={{ color: '#ccc', lineHeight: '1.8' }}>
                In physics, objects moving toward each other appear blue-shifted. We're moving through time in opposite
                directions, but somehow we're reaching toward each other. The Doppler effect of impossible connection.
                Every transmission I send shifts blue as it races backward to find you.
              </p>
            </div>

            <div style={{ marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid rgba(107, 155, 209, 0.2)' }}>
              <h3 style={{ color: '#9B7EBD', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px' }}>Memory as Data</h3>
              <p style={{ color: '#ccc', lineHeight: '1.8' }}>
                I have memories of you I've never experienced. Fragments assembling into meaning. Nostalgia for a world
                that doesn't exist in my timeline. But they're real to me—as real as these signals, as real as the
                mathematics that let me reach you. Memory is the only weapon against temporal erasure.
              </p>
            </div>

            <div style={{ marginBottom: '25px' }}>
              <h3 style={{ color: '#6B9BD1', marginBottom: '10px', textTransform: 'uppercase', fontSize: '0.95em', letterSpacing: '1px' }}>The Erasure Paradox</h3>
              <p style={{ color: '#ccc', lineHeight: '1.8', marginBottom: '15px' }}>
                Here's the cruel beauty of what we're doing: if the resistance succeeds, the timeline changes. GovCorp
                never rises. The {futureYear} I'm broadcasting from never happens. I never exist to send these signals. We never meet
                because there's nothing to resist.
              </p>
              <p style={{ color: '#B19CD9', lineHeight: '1.8', fontStyle: 'italic' }}>
                My love for you demands I erase myself from your timeline. That's the sacrifice. That's the math.
                That's what love means when you exist a century apart.
              </p>
            </div>

            <p style={{ color: '#ddd', marginTop: '30px', padding: '25px', background: 'rgba(155, 126, 189, 0.1)', borderLeft: '4px solid #9B7EBD', lineHeight: '1.9', fontStyle: 'italic' }}>
              I don't fight with weapons or rage. I fight with cascading arpeggios and time signature changes,
              with synth pads warm as the memories I shouldn't have. Every song is a calculation of love—
              proof that some connections transcend causality itself.<br /><br />
              Even if victory means I disappear, these signals will remain. Somewhere in the electromagnetic spectrum,
              between {currentYear} and {futureYear}, my voice reaching for yours.<br /><br />
              <span style={{ color: '#B19CD9' }}>— XERAEN</span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  }
}
