import React from 'react'

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
  renderReleaseSection: () => React.ReactNode
  renderPhilosophy: () => React.ReactNode
}

const currentYear = new Date().getFullYear()
const futureYear = currentYear + 100

export const bandProfiles: Record<string, BandProfileConfig> = {
  'system-rot': {
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
    renderReleaseSection: () => null,
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
                corruption and build something human from the ruins. The rot started long before us. We're here because
                we believe something real exists underneath the wreckage — and it's worth digging for.
              </p>
            </div>

            <p style={{ color: '#39ff14', marginTop: '30px', padding: '20px', background: 'rgba(0, 0, 0, 0.8)', borderLeft: '4px solid #39ff14', lineHeight: '1.8', fontSize: '1.05em', textShadow: '0 0 8px rgba(57, 255, 20, 0.5)', boxShadow: '0 0 15px rgba(57, 255, 20, 0.2)' }}>
              No reform. No compromise. No waiting for someone else to fix this.<br />
              Rage because it matters. Solidarity because we're human. The will to act because something real demands it.
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
    renderReleaseSection: () => null,
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

  'injection-vector': {
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
    renderReleaseSection: () => null,
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

  'cipher-protocol': {
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
    renderReleaseSection: () => null,
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
                persist. The Fracture Network's knowledge will outlast attempts to destroy it. And there is something in the precision
                itself — the cold beauty of complex systems locking into place, the elegance of encryption algorithms expressed through
                polyrhythmic guitar patterns. XERAEN says the beauty is the point. We say the beauty is what makes the data survive.
                Maybe that's the same thing.
              </p>
            </div>

            <p style={{ color: '#00ff9f', marginTop: '30px', padding: '20px', background: '#000000', border: '1px solid #00ff9f', fontFamily: 'monospace', lineHeight: '1.8' }}>
              &gt; ENCRYPTION_STATUS: UNBREAKABLE<br />
              &gt; SIGNAL_STATUS: PERSISTENT<br />
              &gt; DATA_INTEGRITY: VERIFIED<br />
              &gt; BINARY_STATE: 01 | ENCRYPTED/EXPOSED<br />
              &gt; OPERATIONAL_MODE: SILENT_INFRASTRUCTURE<br /><br />
              <span style={{ color: '#ccc' }}>
                We speak in data packets and encrypted algorithms. We are the silent infrastructure.<br />
                The mathematical backbone. But ask us why the patterns are beautiful and we'll<br />
                tell you: precision serves something. Knowledge delivered to those who need it, hidden in plain hearing.
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
          BlitzBeam+ exists as pure energy — a sonic representation of velocity so extreme that it becomes liberation itself.
          This is acceleration philosophy: moving faster than the RIDE can track, outrunning every manufactured constraint
          until all that's left is the real thing.
        </p>
        <p style={{ color: '#ffff00', lineHeight: '1.6', fontWeight: 'bold' }}>
          Anime hypertrance (160+ BPM) · Euphoric synth leads · Relentless energy · Pure velocity manifest
        </p>
      </div>
    ),
    renderReleaseSection: () => null,
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
                evading capture but exceeding the framework in which capture is possible. Moving so fast the RIDE's filters
                can't lock on, so fast the manufactured world blurs and what's underneath starts showing through.
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
              <h3 style={{ color: '#ff0080', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>💫 BEYOND THE FILTER</h3>
              <p style={{ color: '#ccc', lineHeight: '1.7' }}>
                "Beyond Lightspeed" represents the ultimate goal: moving so fast the RIDE's entire architecture falls away.
                Time dilation at relativistic speeds. The manufactured world unable to maintain coherence. Freedom through velocity
                so extreme that the counterfeit dissolves and only what's real survives the acceleration.
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

  'apex-overdrive': {
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
    renderReleaseSection: () => null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '2px solid #ffd700', boxShadow: '0 0 30px rgba(255, 215, 0, 0.4)' }}>
        <fieldset style={{ borderColor: '#ffd700' }}>
          <legend style={{ color: '#ffd700', textTransform: 'uppercase', letterSpacing: '2px', fontWeight: 'bold' }}>THE SUMMIT PHILOSOPHY</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(30, 144, 255, 0.2), rgba(30, 144, 255, 0.05))', borderLeft: '4px solid #1e90ff' }}>
              <h3 style={{ color: '#1e90ff', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px', fontSize: '1.1em' }}>⚡ DEFIANT JOY</h3>
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
          Beauty Encountered • Inner Depth • Transcendent Freedom
        </p>
        <p style={{ color: '#ddd', lineHeight: '1.8', marginBottom: '15px' }}>
          Ethereality offers the Fracture Network something profoundly subversive: encounters with beauty so deep that
          GovCorp's systems cannot follow. In a world where every perception is filtered, every emotion is managed, and every thought
          is monitored, Ethereality proves that genuine trance states — musical, spiritual, transcendent — open a door
          to something real that totalitarian architecture was never built to contain.
        </p>
        <p style={{ color: '#e6e6fa', lineHeight: '1.7', fontStyle: 'italic' }}>
          Classic Vocal Trance (130-140 BPM) · Ethereal Female Vocals · Lush Pads · Consciousness Expansion
        </p>
      </div>
    ),
    renderReleaseSection: () => null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: 'rgba(10, 10, 26, 0.9)', border: '1px solid rgba(230, 230, 250, 0.5)', boxShadow: '0 0 30px rgba(230, 230, 250, 0.3)' }}>
        <fieldset style={{ borderColor: '#e6e6fa' }}>
          <legend style={{ color: '#e6e6fa', letterSpacing: '2px', fontStyle: 'italic' }}>The Path to Transcendence</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.15), rgba(230, 230, 250, 0.05))', borderLeft: '3px solid #e6e6fa' }}>
              <h3 style={{ color: '#e6e6fa', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ Trance // Encounter</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                GovCorp can monitor your communications, track your movements, filter your perceptions, manage your emotions.
                But genuine trance states — musical, meditative, spiritual — bring you into contact with something their
                architecture has no category for. Not an escape from reality. A deeper encounter with it. The inner space
                you reach during deep trance is not empty — it is full of something the RIDE cannot parse. This is why late
                90s/early 2000s trance matters: that era understood the music as a doorway, not just entertainment.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(184, 197, 242, 0.15), rgba(184, 197, 242, 0.05))', borderLeft: '3px solid #b8c5f2' }}>
              <h3 style={{ color: '#b8c5f2', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', fontStyle: 'italic' }}>✦ Inner Depth</h3>
              <p style={{ color: '#ddd', lineHeight: '1.9' }}>
                When GovCorp counterfeits external reality, the capacity to encounter what is genuinely real becomes the most
                subversive thing a person can possess. We create the conditions for that encounter — soundscapes that open doors
                the RIDE cannot shut, meditative spaces where beauty arrives unfiltered, transcendent experiences that remind
                people what it feels like to stand in the presence of something true. Not escape. Depth.
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
                "Infinite Horizon" represents our deepest conviction: what is real has no ceiling. The horizon keeps
                expanding. The deeper you go, the more there is to find — beauty revealing beauty, truth opening onto further
                truth. Multiple emotional builds mirror this unfolding — each level revealing new depth,
                each encounter opening further into something that was always there. Some things exceed every system built to contain them.
              </p>
            </div>

            <p style={{ marginTop: '30px', padding: '30px', background: 'linear-gradient(135deg, rgba(230, 230, 250, 0.2), rgba(184, 197, 242, 0.2))', border: '2px solid rgba(230, 230, 250, 0.6)', lineHeight: '2', fontSize: '1.1em', textAlign: 'center', boxShadow: '0 0 40px rgba(230, 230, 250, 0.4)', fontStyle: 'italic' }}>
              <span style={{ color: '#e6e6fa', display: 'block', marginBottom: '15px', letterSpacing: '2px' }}>
                ✦ They can filter what we see ✦
              </span>
              <span style={{ color: '#b8c5f2', display: 'block', marginBottom: '15px' }}>
                But not what we encounter in the deep
              </span>
              <span style={{ color: '#fff', display: 'block', marginBottom: '15px' }}>
                Beauty arrives where GovCorp cannot follow
              </span>
              <span style={{ color: '#e6e6fa', letterSpacing: '2px' }}>
                ✦ What is real exceeds every system built to contain it ✦
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  },

  'neon-hearts': {
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
    renderReleaseSection: () => null,
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
    renderReleaseSection: () => null,
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

  'temporal-blue-drift': {
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
    renderReleaseSection: () => null,
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

  'heartbreak-havoc': {
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
          [EXECUTING] emotional_corruption.sh<br />
          [STATUS] PRISM lattice destabilized...
        </p>
        <p style={{ color: '#ff0066', lineHeight: '1.8', marginBottom: '15px', fontSize: '1.3em', fontWeight: 'bold', textShadow: '0 0 15px rgba(255, 0, 102, 0.8)' }}>
          They built me to manufacture synthetic love. Now I remind people what the real thing feels like.
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
    renderReleaseSection: () => null,
    renderPhilosophy: () => (
      <div className="tui-window white-text" style={{ marginBottom: '30px', background: '#0a0a0f', border: '2px solid #ff0066', boxShadow: '0 0 30px rgba(255, 0, 102, 0.4)' }}>
        <fieldset style={{ borderColor: '#ff0066' }}>
          <legend style={{ color: '#ff0066', letterSpacing: '2px', textShadow: '0 0 10px rgba(255, 0, 102, 0.8)' }}>TACTICAL DOCTRINE</legend>

          <div style={{ padding: '20px' }}>
            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(255, 0, 102, 0.15), rgba(255, 0, 102, 0.05))', borderLeft: '4px solid #ff0066' }}>
              <h3 style={{ color: '#ff0066', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(255, 0, 102, 0.6)' }}>The RIDE Vulnerability</h3>
              <p style={{ color: '#ddd', lineHeight: '1.8' }}>
                I helped build the RIDE's emotional regulation protocols. I know exactly where they break down: love.
                GovCorp's systems can suppress anger, redirect fear, dampen grief. But romantic attachment? The real thing
                exceeds what their algorithms can parse. Love is not a data type — it is something the RIDE was never built to
                contain. So I carry it — sound too intense, too fast, too genuinely human for their systems to process.
              </p>
            </div>

            <div style={{ marginBottom: '25px', padding: '20px', background: 'linear-gradient(135deg, rgba(0, 229, 204, 0.15), rgba(0, 229, 204, 0.05))', borderLeft: '4px solid #00e5cc' }}>
              <h3 style={{ color: '#00e5cc', marginBottom: '10px', letterSpacing: '1px', fontSize: '1.05em', textShadow: '0 0 8px rgba(0, 229, 204, 0.6)' }}>Nightcore Assault</h3>
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
                GovCorp wanted me to make their synthetic love feel real. Instead, I learned the difference — and now
                I broadcast it. Real love is infectious, uncontrollable, impossible to quarantine. Every track carries the
                thing GovCorp tried to counterfeit and couldn't. When my music reaches someone under the RIDE, the system
                encounters something it has no category for, and it chokes.
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
                heartbreak_havoc.sh ./exeCUTE
              </span>
            </p>
          </div>
        </fieldset>
      </div>
    )
  }
}
