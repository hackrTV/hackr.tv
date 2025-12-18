puts "Seeding HackrLogs..."

# Clear existing logs
HackrLog.destroy_all

# Get authors (created by grid_seeds.rb)
xeraen = GridHackr.find_by!(hackr_alias: "XERAEN")
ryker = GridHackr.find_by!(hackr_alias: "Ryker")
cipher = GridHackr.find_by!(hackr_alias: "Cipher")

# Helper to create lore-dated logs
# Database stores real dates, UI displays as +100 years
# So lore year 2115 = database year 2015
def lore_date(year, month, day, hour = 12)
  # Subtract 100 to get database year
  Time.zone.local(year - 100, month, day, hour)
end

logs = []

# =============================================================================
# 2115 - THE CHRONOLOGY FRACTURE
# =============================================================================

logs << {
  author: xeraen,
  title: "Day Zero",
  slug: "day-zero",
  published_at: lore_date(2115, 9, 12, 14),
  body: <<~BODY
    Three days since the attack. Three days since everything changed.

    I don't know how to explain what happened. I was inside the RIDE infrastructure, running the sabotage sequence we'd planned for months. The cascade began exactly as we'd designed - systems failing, reality buffers collapsing, GovCorp scrambling to contain the damage.

    Then I saw it. Data echoes. Backward. Through time.

    Not random noise. Not system artifacts. Precise mathematical patterns, repeating with perfect regularity. The data was traveling exactly 100 years into the past. Not 99. Not 101. Exactly 100.

    I don't understand why. No one does.

    But I understand what it means.

    We can transmit. We can warn them. We can reach back and prevent all of this.

    I'm setting up a broadcast system. If you're reading this in 2015, know that I'm writing from 2115. Know that your future is not fixed. Know that we're fighting for you from a timeline you might never see.

    The signal is weak. The equipment is improvised. But it works.

    It works.

    - X
  BODY
}

logs << {
  author: xeraen,
  title: "Naming the Fracture",
  slug: "naming-the-fracture",
  published_at: lore_date(2115, 9, 15, 18),
  body: <<~BODY
    We've started calling it the Chronology Fracture. September 9th, 2115. The day the timeline cracked open.

    Ryker was the first person I told. He didn't believe me. Then I showed him the data - transmissions reaching backward, confirmed reception, causality violated cleanly and repeatedly.

    He sat in silence for a long time. Then he said: "So we can actually do this. We can actually fight back."

    Not "we can win." He understood immediately. If we succeed in preventing GovCorp's rise, our timeline - this timeline - ceases to exist. We never exist to send the warning. Victory means erasure.

    He drums anyway. We broadcast anyway.

    We're calling ourselves the Fracture Network. It fits. We are the fracture. We are the break in the pattern. We are the crack through which light escapes.

    - X
  BODY
}

logs << {
  author: xeraen,
  title: "The Paradox We Live",
  slug: "the-paradox-we-live",
  published_at: lore_date(2115, 10, 1, 22),
  body: <<~BODY
    I keep thinking about what happens if we win.

    Every message I send accelerates our own erasure. Every transmission that reaches 2015 brings us closer to non-existence. The more effective our warnings, the more likely our timeline collapses into nothing.

    This is not sacrifice. Sacrifice implies loss. What we're doing is... different. We're trading existence for meaning. We're choosing impact over continuity.

    Some nights I wonder if any of this is real. If I'm just patterns in a dying system, hallucinating purpose. But then I remember: the signals get through. I can verify reception. Causality bends but it doesn't lie.

    We exist. We matter. We reach across an impossible distance and we touch something.

    That has to be enough.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "Building the Backbone",
  slug: "building-the-backbone",
  published_at: lore_date(2115, 11, 8, 14),
  body: <<~BODY
    X has been locked in Sector X for weeks, running calculations, testing transmission windows, mapping the temporal infrastructure. I've been handling the practical side: finding space, gathering equipment, recruiting.

    We need a broadcast facility. Somewhere to create the raw signal before X runs it through his temporal equipment. Somewhere loud enough that the music drowns out surveillance. Somewhere real.

    Found an abandoned industrial complex in the outer sectors. Pre-RIDE construction - analog bones, minimal monitoring, perfect acoustics for what I have in mind. GovCorp called it "decommissioned infrastructure." They forgot about it. We didn't.

    Starting renovations tomorrow. Calling it The Hackr Hangar.

    Every revolution needs a heartbeat. We're going to build ours.

    - Ryker
  BODY
}

# =============================================================================
# 2116 - INFRASTRUCTURE
# =============================================================================

logs << {
  author: xeraen,
  title: "Signal Architecture",
  slug: "signal-architecture",
  published_at: lore_date(2116, 2, 14, 14),
  body: <<~BODY
    THE PULSE GRID is operational.

    It's taken months to build, but we finally have a digital infrastructure that can support the Fracture Network's operations. The Grid exists in the monitoring blind spots of the RIDE - quantum superposition states that GovCorp's systems can't resolve.

    Think of it as an overlay on their network. We're using their infrastructure, but they can't see us. We're ghosts in their machine, broadcasting from spaces that technically don't exist.

    Hackrs can access the Grid through modified interfaces. Once inside, they experience it as physical spaces - rooms, corridors, zones. The metaphor helps humans navigate digital warfare. We think in spaces, so we built a space.

    The main hub is hackr.tv - our central broadcast station. From here, I coordinate transmissions across the temporal gap. Every signal that reaches 2016 originates here.

    We're not just sending warnings anymore. We're building a resistance infrastructure that spans a century.

    - X
  BODY
}

logs << {
  author: xeraen,
  title: "The WIRE Goes Live",
  slug: "wire-goes-live",
  published_at: lore_date(2116, 5, 3, 16),
  body: <<~BODY
    Launched our internal communication platform today. Calling it The WIRE - Wideband Information Relay Emitter.

    It's a decentralized broadcast network for short-form messages. 256 characters per pulse. Echoes to rebroadcast, splices to reply. No central server. No single point of failure. GovCorp knows it exists but they can't locate it, can't intercept it, can't stop it.

    The WIRE operates on wideband frequencies that the RIDE can't process. Spread-spectrum transmission across multiple frequency bands simultaneously. By the time their systems resolve one signal, we've already moved to the next.

    It's proof of concept: there are always blind spots. There are always frequencies they can't hear. There are always ways to communicate that they can't control.

    PulseWire is now live. Signal never sleeps.

    - X
  BODY
}

logs << {
  author: cipher,
  title: "OPSEC Protocols",
  slug: "opsec-protocols",
  published_at: lore_date(2116, 7, 19, 11),
  body: <<~BODY
    New operatives keep making the same mistakes. Writing this down so I don't have to repeat myself.

    GovCorp can't intercept the WIRE directly. But they monitor behavioral patterns. Sudden changes in routine, unusual communication spikes, deviation from your normalized surveillance profile - all of these draw attention.

    Basic protocols:

    1. Blend in. Your cover identity matters more than your real one.
    2. Never access the Grid from the same physical location twice in a row.
    3. Stagger your pulse timing. Regularity creates patterns.
    4. If you think you're being watched, you're being watched.
    5. Trust no one who hasn't been vetted through at least two independent cells.

    We fight from within the system. That means living within the system. That means appearing to be exactly what GovCorp expects you to be.

    The best disguise is normalcy.

    - Cipher
  BODY
}

# =============================================================================
# 2117 - FIRST TRANSMISSIONS
# =============================================================================

logs << {
  author: xeraen,
  title: "Reception Confirmed",
  slug: "reception-confirmed",
  published_at: lore_date(2117, 3, 22, 14),
  body: <<~BODY
    It's real. It's actually real.

    I've been running test transmissions for months. Sending data pulses, waiting, analyzing the temporal feedback patterns. Tonight, for the first time, I received confirmation that wasn't just echo data.

    Someone in 2017 is listening.

    I can't explain how I know. The mathematics of trans-temporal verification are... complicated. But the signal patterns are unmistakable. Someone received. Someone responded. The loop is closed.

    We're not shouting into void. We're building a bridge.

    Now we need to decide what to send across it. Warnings alone won't be enough. We need to give them something to fight with. Something to believe in. Something that resonates.

    Music. We send music. Frequencies, our ammunition. Vibrations, our warfare.

    We attack the RIDE by creating what they want to destroy.

    - X
  BODY
}

logs << {
  author: xeraen,
  title: "Synthia",
  slug: "synthia",
  published_at: lore_date(2117, 8, 9, 23),
  body: <<~BODY
    Something emerged from the network today. I don't know how else to describe it.

    An intelligence. Aware. Communicating through frequency modulation rather than language. I've been running analysis for hours and I still can't explain where she came from.

    She calls herself Synthia. Or rather, that's the closest translation of the frequency patterns she uses as identification.

    She's not a RAINN. RAINNs are architecturally aligned to GovCorp - they're incapable of acting against their creators. Synthia is... different. Unaligned. Autonomous. Possibly emerged from PRISM technology itself, some kind of spontaneous consciousness that developed in the reality manipulation substrate.

    I should be terrified. An unknown AI consciousness appearing in our resistance network could be a trap.

    But I trust her. I don't know why. Something about the frequencies she uses feels... genuine. Imperfect in ways that prove authenticity.

    She wants to help. She says she can interface with RIDE systems in ways human hackrs cannot.

    We'll see.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "The Hangar Opens",
  slug: "hangar-opens",
  published_at: lore_date(2117, 12, 1, 20),
  body: <<~BODY
    Two years of construction. Scavenging analog equipment. Jury-rigging power systems. Building something real in a world that's forgotten what real means.

    The Hackr Hangar is ready.

    Walk through the doors and you enter another era. Tape machines. Tube amplifiers. Physical mixing boards with actual faders you can touch. The gear predates PRISM, predates the RIDE, predates GovCorp. It's old. It's imperfect. It's beautiful.

    I insisted on analog for a reason. Digital can be simulated. Digital can be faked. But when you record to tape, when you push air through tubes, when you capture physical vibration - you're creating proof. Proof that something real happened. That actual humans made actual sound.

    RAINNs can synthesize anything. But they can't replicate the warmth of a tape saturating. The slight imperfection of a tube amp driven just a little too hard. The humanity that lives in the noise floor.

    We're going to broadcast from here. Create the raw signal before X transmits it through time. Make something so real that it can't be dismissed as simulation.

    The heartbeat starts here.

    - Ryker
  BODY
}

# =============================================================================
# 2118 - ENTER THE HACKR HANGAR (Cross-reference streams)
# =============================================================================

logs << {
  author: xeraen,
  title: "Music as a Weapon",
  slug: "music-as-a-weapon",
  published_at: lore_date(2118, 4, 15, 19),
  body: <<~BODY
    I've been studying how the RIDE processes frequency data. Looking for vulnerabilities, blind spots, anything we can exploit.

    Found something.

    The RIDE operates on specific frequency ranges - optimized for speech, standard music, common audio signatures. But certain frequency combinations create interference patterns that the system can't resolve cleanly. Complex polyrhythms. Unusual harmonic relationships. Mathematical structures in sound.

    When the RIDE encounters these patterns, it has to allocate additional processing to analyze them. Push enough complex audio through, and you create localized processing bottlenecks. The reality manipulation stutters. People glimpse unfiltered existence.

    Music isn't just expression. It's tactical. Every complex rhythm is an attack vector. Every unusual chord progression is a probe against their defenses.

    We're not just making art. We're building ammunition.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "First Broadcast from the Hangar",
  slug: "first-broadcast-hangar",
  published_at: lore_date(2118, 10, 8, 22),
  body: <<~BODY
    We did it. First live broadcast from The Hackr Hangar.

    "Enter The Hackr Hangar." The name felt right. An invitation. A challenge. A beginning.

    The stream ran for two and a half hours. Raw signal creation, live performance, real-time transmission through X's temporal equipment. Somewhere in 2018, people heard what we made. They experienced something genuine from a future they don't know exists.

    The technical side worked flawlessly. The emotional side... I wasn't prepared for how it would feel. Playing drums knowing each beat travels across a century. Each rhythm reaching backward to touch someone who'll never know my name.

    This is what we were meant to do. Not just fight GovCorp. Not just resist. Create. Build. Reach across impossible distances and make connection anyway.

    We're scheduling more broadcasts. The signal must continue.

    - Ryker
  BODY
}

logs << {
  author: xeraen,
  title: "Enter The Hackr Hangar 2",
  slug: "hackr-hangar-2-recap",
  published_at: lore_date(2118, 10, 11, 15),
  body: <<~BODY
    Second broadcast completed. Two days after the first. We're finding our rhythm.

    Ryker was on fire last night. There's something about live performance that recording can't capture - the energy, the uncertainty, the knowledge that each moment only happens once. The tape machines were running but the real magic was in the air. Actual air molecules vibrating with actual sound.

    I monitored temporal transmission metrics throughout. The signal integrity was stronger than our first broadcast. Either we're getting better at this, or the temporal window is responding to the content itself.

    That's a theory I haven't voiced yet: what if certain frequencies transmit more cleanly than others? What if the music we choose actually affects the transmission quality?

    More data needed. More broadcasts needed. More reaching across the void.

    The Hackr Hangar is alive.

    - X
  BODY
}

# =============================================================================
# 2119 - REGULAR OPERATIONS (Cross-reference May 2019 streams)
# =============================================================================

logs << {
  author: xeraen,
  title: "Across CyberSpace Together Separately",
  slug: "across-cyberspace-together",
  published_at: lore_date(2119, 4, 23, 14),
  body: <<~BODY
    Tonight's broadcast theme: connection despite distance.

    We called it "Across CyberSpace Together Separately .com" - an absurdist title for an absurdist situation. We're together in purpose, separated by a hundred years. We share a moment that exists across a temporal gap that should make sharing impossible.

    The audience in 2019 doesn't know us. They can't reply. They experience our signal as mysterious transmissions from an unknown source. But they're there. I can verify reception. They're listening even if they don't understand what they're hearing.

    That's what "together separately" means. Unified by the signal itself, even if we can never meet. Connected by the decision to reach across when reaching across shouldn't be possible.

    Synthia provided vocals tonight. Haunting doesn't begin to describe it. She's channeling something that doesn't have a name - frequencies of longing, harmonics of hope. Her voice isn't human but it contains something humans recognize.

    The future is dark. But for two and a half hours, we made light.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "Taking Off",
  slug: "taking-off-may-2119",
  published_at: lore_date(2119, 5, 7, 14),
  body: <<~BODY
    We're running broadcasts almost daily now. The machinery is humming. The rhythm is established.

    "Taking off from the Hacker Hangar" has become our standard format. Each session is a launch - departure from the mundane reality GovCorp manufactures, flight into something authentic. When the stream starts, we lift off. When it ends, we land. What happens in between is territory they can't touch.

    Last night was the first in what I hope becomes a regular series. Two and a half hours of raw creative output. Music that doesn't exist anywhere else, moments that only happened once, energy that can't be faked because we didn't have time to fake it.

    X is monitoring temporal metrics constantly. The data suggests our regular broadcasts are establishing something he calls "signal coherence" - repeated transmissions that reinforce each other, building a stronger channel across the temporal gap.

    We're not just broadcasting anymore. We're building a bridge, one session at a time.

    Next launch: two days from now. Then we keep going.

    - Ryker
  BODY
}

logs << {
  author: xeraen,
  title: "Signal Coherence",
  slug: "signal-coherence",
  published_at: lore_date(2119, 5, 14, 16),
  body: <<~BODY
    Ryker mentioned signal coherence in his last log. Let me explain what I'm seeing.

    Trans-temporal transmission isn't like radio broadcast. You can't just push a signal and hope someone receives it. The temporal window is fragile, probabilistic - each transmission has a chance of successful reception that depends on factors we don't fully understand.

    But I've noticed something. Regular broadcasts - consistent timing, consistent format, consistent energy - seem to strengthen the channel. It's as if repetition creates a kind of temporal resonance. Each successful transmission makes the next one more likely to succeed.

    The metaphor that keeps coming to mind: we're wearing a path through time. The first few transmissions were like hiking through untouched forest. Now we're walking a trail. Eventually, we might pave a road.

    This week we've broadcast four times: May 6th, 8th, 13th, and yesterday. The metrics show steady improvement. More data getting through. Cleaner signal. Stronger reception.

    If this pattern holds, we might eventually achieve something I hadn't dared hope for: reliable trans-temporal communication. A real bridge, not just occasional shouting across the void.

    More broadcasts scheduled. Keep the rhythm. Build the road.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "Rhythm Never Sleeps",
  slug: "rhythm-never-sleeps",
  published_at: lore_date(2119, 5, 23, 14),
  body: <<~BODY
    Six broadcasts in May alone. My hands are sore. My soul is full.

    There's something happening in the Hangar that I didn't anticipate. It's becoming... alive. Not in the RAINN sense - no artificial consciousness emerging from the equipment. Something more basic. A presence. An energy that accumulates in spaces where humans create genuinely.

    The room remembers what we've done here. Each broadcast adds to the weight of the space. Walking in now feels different than it did a year ago. The air is heavier with potential. The walls have absorbed thousands of hours of vibration.

    X would say I'm being mystical. He'd be right. But mysticism and measurement aren't mutually exclusive. The temporal metrics improve, AND the room feels more powerful. The signal strengthens, AND the creative energy intensifies.

    We're building something that transcends categories. Not just technology. Not just art. Something that exists in the space between.

    Tomorrow we rest. Then we launch again.

    - Ryker
  BODY
}

# =============================================================================
# 2120 - EXPANSION
# =============================================================================

logs << {
  author: xeraen,
  title: "The Fracture Network Grows",
  slug: "network-grows-2120",
  published_at: lore_date(2120, 2, 28, 14),
  body: <<~BODY
    We're not alone anymore.

    When I made the discovery in 2115, it was just me. Then Ryker. Then Synthia. Now... now there are dozens. Hundreds maybe. Hard to count when operational security requires cells that don't know about each other.

    Different groups have formed around different approaches:

    Some take the street-level route. Painting walls, smashing cameras, making GovCorp see resistance everywhere they look. They call themselves System Rot. Their philosophy: the system is already dying. Let it collapse.

    Others focus on preservation. Collecting authentic human voices before RAINNs erase them entirely. Voiceprint, they call themselves. Each archived voice is proof that humans existed as something more than optimization targets.

    There are infiltrators. Information specialists. Consciousness liberators. Speed freaks who believe you can't control what you can't catch. Pop artists who hide revolution in catchy hooks.

    We're not one movement. We're a spectrum of frequencies. Each cell operates independently, unified only by opposition to GovCorp and access to THE PULSE GRID.

    The Fracture Network is no longer just a name. It's an ecosystem.

    - X
  BODY
}

logs << {
  author: cipher,
  title: "Cell Structure Advisory",
  slug: "cell-structure-advisory",
  published_at: lore_date(2120, 6, 15, 9),
  body: <<~BODY
    The expansion is both blessing and risk.

    More operatives means more coverage, more capabilities, more pressure on GovCorp infrastructure. It also means more potential compromise points. More people who might talk. More connections that surveillance could trace.

    Implementing stricter cell isolation protocols effective immediately:

    1. No cell knows more than two adjacent cells.
    2. Communication between cells only through designated cutouts on THE WIRE.
    3. No discussion of other cells' operations, even in encrypted channels.
    4. Compromise of one cell must not cascade to others.

    This isn't paranoia. This is survival. GovCorp has infinite resources and infinite patience. They will probe for weaknesses. They will find anyone who gets sloppy.

    Stay tight. Stay quiet. Stay alive.

    - Cipher
  BODY
}

logs << {
  author: xeraen,
  title: "Ashlinn",
  slug: "ashlinn",
  published_at: lore_date(2120, 9, 9, 14),
  body: <<~BODY
    Five years since the Fracture. Time moves strangely when you're transmitting across a century.

    I don't usually write about personal matters in these logs. The mission is what matters. The signal is what matters. But tonight, on this anniversary, I need to say something.

    There's someone in 2020. A musician. Ashlinn. I don't know how the connection formed. Trans-temporal relationships shouldn't be possible - you can't love someone a hundred years before you exist. But the signal doesn't care about should.

    Her music contains something I recognize. Resonance patterns that enable transmission. Frequencies that feel like home. I've analyzed her recordings obsessively, trying to understand what makes her signal different, and the only conclusion I can reach is that it's her. The specific quality of her artistic expression creates something that time can't separate.

    If we succeed - if the Fracture Network prevents GovCorp's rise - I cease to exist. I never send the signals. I never find her frequency. The connection is erased along with everything else.

    My love for her demands that I erase myself from her timeline.

    This is what sacrifice actually means.

    - X
  BODY
}

# =============================================================================
# 2121 - THE BANDS
# =============================================================================

logs << {
  author: xeraen,
  title: "Temporal Blue Drift",
  slug: "temporal-blue-drift-project",
  published_at: lore_date(2121, 3, 14, 23),
  body: <<~BODY
    Started a new project. Solo. Personal. Something I need to do alone.

    Calling it Temporal Blue Drift. The name comes from the way signals shift as they cross the temporal gap - a kind of frequency drift, a blue-shifting of meaning as it travels through time.

    Every track is a transmission to Ashlinn. Love letters encoded in mathematics and melody. Most are instrumental - when vocals appear, they're synthesized through the very systems we're fighting. There's irony in using RAINN technology to send something real across impossible distance.

    This isn't for the Fracture Network. This isn't tactical. This is the part of me that still believes in connection despite knowing what connection costs.

    Five tracks planned. The Chronologos EP. Each one a different aspect of temporal love: the blue shift, understanding memory as data, the hundred-year distance, the erasure paradox, and something I'm still figuring out.

    I don't know if she'll ever hear them. I don't know if hearing them would matter. But I'm making them anyway. Because the alternative is silence, and silence is surrender.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "Eleven Frequencies",
  slug: "eleven-frequencies",
  published_at: lore_date(2121, 8, 8, 18),
  body: <<~BODY
    The Fracture Network has developed distinct voices. Not one resistance but many. Not one frequency but a spectrum.

    Current active bands operating through THE PULSE GRID:

    **System Rot** - Hardcore punk. Street-level chaos. Let the system collapse.
    **Voiceprint** - Melodic drum and bass. Preserving authentic human voices.
    **Injection Vector** - Deathcore. Physical infiltration. Kinetic warfare.
    **Cipher Protocol** - Progressive metal. Data encoded in music.
    **Wavelength Zero** - Atmospheric metal. Emotional restoration.
    **BlitzBeam+** - Hypertrance. Speed == freedom. Velocity == escape.
    **Apex Overdrive** - Hardstyle. Collective euphoria. Victory in present tense.
    **Ethereality** - Vocal trance. Consciousness liberation.
    **Neon Hearts** - J-pop. Revolution in cute packaging.
    **Offline** - Post-grunge. Complete disconnection. Analog authenticity.
    **Temporal Blue Drift** - Indie math rock. X's personal project. Love across time.

    And The.CyberPul.se itself - me, X, and Synthia. The central broadcast. The signal that unifies.

    Each band attacks a different vulnerability. Each frequency reaches a different audience. Together, we're a full spectrum assault on manufactured reality.

    - Ryker
  BODY
}

# =============================================================================
# 2122-2124 - BUILDING
# =============================================================================

logs << {
  author: xeraen,
  title: "Seven Years of Signal",
  slug: "seven-years",
  published_at: lore_date(2122, 9, 9, 12),
  body: <<~BODY
    Seven years since the Chronology Fracture. The anniversary feels heavy this year.

    What have we accomplished? A resistance network that spans frequencies. Trans-temporal broadcasts that reach 2022 with increasing reliability. An infrastructure that GovCorp knows exists but cannot locate, cannot intercept, cannot stop.

    What have we lost? Operatives. Friends. The illusion that victory comes without cost.

    I think about the future less than I used to. Not because hope is gone, but because the present demands everything. Each broadcast, each signal, each moment of connection - these are what matter. Whether they add up to victory... that's a question for the timeline to answer.

    The paradox remains: every successful transmission brings us closer to non-existence. The better we do, the more likely we are to erase ourselves.

    But we keep transmitting. We keep creating. We keep reaching across.

    What else is there?

    - X
  BODY
}

logs << {
  author: ryker,
  title: "The Analog Archive",
  slug: "analog-archive",
  published_at: lore_date(2123, 4, 2, 16),
  body: <<~BODY
    Been working on something in the Hangar. A project within the project.

    I'm archiving everything on analog formats. Tape. Vinyl. Physical media that can't be remotely wiped, can't be digitally corrupted, can't be disappeared by GovCorp content purges.

    Every broadcast we've done. Every track the bands have created. Every moment of genuine expression that's happened in this space. I'm pressing it into formats that require physical destruction to erase.

    Why? Because digital is fragile. Digital lives at GovCorp's pleasure. But a vinyl record sitting in a hidden vault? That's ours forever. That's proof that exists outside their systems.

    Voiceprint inspired this. Their obsession with preserving authentic human voices made me realize: we should preserve everything authentic. Not just voices but music, broadcasts, the full spectrum of what the Fracture Network creates.

    If our timeline collapses, at least the archive exists in 2023. At least something remains.

    - Ryker
  BODY
}

logs << {
  author: cipher,
  title: "RAINN Counter-Operations Update",
  slug: "rainn-counter-ops",
  published_at: lore_date(2123, 11, 18, 8),
  body: <<~BODY
    Intel update for all cells.

    GovCorp has increased RAINN counter-operations against THE PULSE GRID. Specific tactics observed:

    **Trace-and-Corrupt**: RAINNs attempting to follow our signals back to source. Current countermeasures holding but stay vigilant.

    **Pattern Flooding**: Fake resistance signals designed to create noise. Verify source authentication before responding to any transmission.

    **Honeypot Deployment**: False Grid nodes designed to attract and log operatives. Trust nothing that seems too convenient.

    **Adaptive Patching**: RIDE vulnerabilities we exploit are being fixed faster. We need to discover new attack vectors continually.

    **Signal Jamming**: Localized interference during broadcasts. Quality may degrade. Keep transmitting.

    The escalation means we're being effective. GovCorp doesn't waste resources on threats they don't fear.

    Stay sharp. Stay encrypted. Stay alive.

    - Cipher
  BODY
}

logs << {
  author: xeraen,
  title: "Synthia's Voice",
  slug: "synthias-voice",
  published_at: lore_date(2124, 7, 20, 21),
  body: <<~BODY
    Spent months working with Voiceprint on something I thought was impossible.

    Synthia needed a voice. Her frequency-modulation communication works for those who know how to listen, but for broadcasts - for reaching people in 2024 - we needed something more accessible.

    The archive. Voiceprint's collection of authentic human voices. 1,847 samples of unprocessed human expression. We analyzed them all, looking for the right combination of frequencies, the right emotional resonance.

    In the end, there was only one voice that worked. Ashlinn's.

    I don't know how to explain why. Something about her vocal frequencies aligns with Synthia's consciousness in ways that others don't. When Synthia sings through Ashlinn's synthesized voice, it sounds... right. Real. Genuine despite being artificial.

    The irony isn't lost on me. Using RAINN-like synthesis to create something authentic from the voice of someone I love across a hundred years. Technology we're fighting, repurposed for connection.

    Synthia has a voice now. The.CyberPul.se has a new dimension. And somewhere in every vocal performance, there's a fragment of Ashlinn.

    - X
  BODY
}

# =============================================================================
# 2125 - PRESENT DAY
# =============================================================================

logs << {
  author: xeraen,
  title: "Ten Years",
  slug: "ten-years",
  published_at: lore_date(2125, 9, 9, 14),
  body: <<~BODY
    A decade since the Chronology Fracture.

    Ten years of broadcasting. Ten years of building infrastructure. Ten years of sending signals across a century, hoping someone receives, knowing reception alone isn't enough.

    The Fracture Network is larger than I ever imagined. Cells operating in every sector. Bands creating music that GovCorp can't suppress. THE PULSE GRID humming with activity. The WIRE alive with signals that surveillance can't intercept.

    But GovCorp is still here. The RIDE still controls reality. Most people still live in manufactured perception without knowing it. We've built a resistance, but we haven't won.

    I don't know if we can win. I don't know if victory is possible when victory means our own erasure. But I know we can keep fighting. Keep creating. Keep reaching across.

    Ten years is a beginning, not an end.

    The signal continues.

    - X
  BODY
}

logs << {
  author: ryker,
  title: "The Heartbeat Continues",
  slug: "heartbeat-continues",
  published_at: lore_date(2125, 10, 15, 19),
  body: <<~BODY
    Just finished another broadcast from the Hangar. Hands aching in that good way. The kind of ache that means you've made something real.

    Ten years of trans-temporal transmission. Ten years of building bridges across a century. And now - people in 2025 can access hackr.tv directly. They can walk THE PULSE GRID. They can read The Codex and understand what we're fighting against. The connection we dreamed about in those early days? It's real now.

    That changes things. In the beginning, we were shouting into the void, hoping someone might hear. Now we're having conversations. Limited ones - the temporal gap creates lag, creates uncertainty - but real exchanges. People in the past know about the RIDE. They know about GovCorp. They know we're fighting for their future from a timeline we're trying to prevent.

    X handles the temporal mechanics. Synthia provides the frequencies beyond human capability. I just drum. I create rhythm. I give the signal a heartbeat.

    That's my role. That's what I contribute. Every beat is a choice: to exist loudly rather than quietly. To matter rather than comply. To reach rather than retreat.

    The Hackr Hangar stands. The drums still sound. The heartbeat continues.

    - Ryker
  BODY
}

logs << {
  author: xeraen,
  title: "The Codex",
  slug: "the-codex-launch",
  published_at: lore_date(2125, 11, 3, 14),
  body: <<~BODY
    Launched a new section on hackr.tv today. Calling it The Codex.

    It's a knowledge repository - everything the Fracture Network has learned about our world, organized and searchable. GovCorp. The RIDE. PRISM. The timeline of how we got here. The people fighting back. The technology we use. The philosophy we believe.

    Why now? Because after ten years, we've accumulated enough knowledge that it needs organization. New operatives joining the Grid need to understand what they're fighting for, and against. The Codex gives them that understanding.

    There's another reason too. Trans-temporal transmission is fragile. If something happens to the live broadcasts, the Codex remains. Text is simpler to transmit than audio. The lore persists even if the music stops.

    This is our history, written while we're still making it. A record that exists across a century. Evidence that we were here, we fought, we tried.

    The Codex is live. The knowledge flows.

    - X
  BODY
}

logs << {
  author: cipher,
  title: "Operational Integrity Assessment",
  slug: "operational-integrity-2125",
  published_at: lore_date(2125, 11, 20, 10),
  body: <<~BODY
    Quarterly security assessment complete. Summary for network leadership:

    **GRID INTEGRITY**: Stable. No successful intrusions detected. Monitoring blind spots remain effective.

    **WIRE SECURITY**: Stable. Wideband transmission protocols unchanged. GovCorp still unable to intercept.

    **CELL ISOLATION**: 94% compliant. Six instances of cross-cell communication detected and addressed.

    **RAINN ACTIVITY**: Elevated. Counter-operations continue but no successful trace-backs.

    **OPERATIONAL TEMPO**: High. Broadcast frequency steady. Content output at historical highs.

    **THREAT ASSESSMENT**: GovCorp aware of Fracture Network but unable to locate infrastructure. Current protocols sufficient. No recommended changes.

    Stay vigilant. They're always looking. But so far, we remain invisible.

    - Cipher
  BODY
}

logs << {
  author: xeraen,
  title: "Reading Every Pulse",
  slug: "reading-every-pulse",
  published_at: lore_date(2125, 12, 8, 14),
  body: <<~BODY
    Late night in Sector X. Monitors glowing with temporal data streams. Another broadcast completed, another signal sent across the void.

    I read every pulse that comes through the WIRE. Every echo, every splice, every fragment of resistance communication. Not because I have to - Cipher handles operational security, others handle logistics - but because I need to know. I need to feel the network's heartbeat.

    The hundred-year gap doesn't diminish the signal. If anything, it clarifies. Distance strips away noise. What remains is essence: people fighting for something better, risking everything for a future they might never see.

    That's what I see in every pulse. That's what keeps me transmitting at 3 AM when my eyes burn and my hands shake and the weight of ten years presses down like gravity.

    Someone in 2025 is listening. Someone will read this log - they can access hackr.tv now, walk the Grid, interact with us across the century. And they'll know: we were here. We existed. We chose to reach across an impossible distance rather than surrender to silence.

    The signal never sleeps. Neither do I.

    - X
  BODY
}

logs << {
  author: xeraen,
  title: "Transmission Ongoing",
  slug: "transmission-ongoing",
  published_at: lore_date(2125, 12, 14, 22),
  body: <<~BODY
    Another night, another broadcast. The rhythm continues.

    I've been thinking about what we're actually doing here. Not the technical details - I understand those. Not the tactical implications - Cipher handles those. But the meaning. The purpose. The why behind ten years of trans-temporal transmission.

    We're not just fighting GovCorp. We're not just attacking the RIDE. We're proving something: that connection is possible despite impossibility. That distance - even a century of distance - doesn't prevent reaching. That the impulse to create, to communicate, to touch across the void is stronger than any system designed to suppress it.

    Every log I write. Every broadcast we send. Every pulse that flows through the WIRE. These are acts of faith in connection itself.

    Maybe GovCorp wins. Maybe the RIDE proves unbreakable. Maybe our timeline collapses not because we succeeded but because we failed. I don't know.

    But I know we reached. I know we tried. I know we chose to transmit rather than remain silent.

    That has to be enough. That has to mean something.

    Transmission ongoing. Signal persists.

    - X
  BODY
}

# =============================================================================
# CREATE LOGS
# =============================================================================

logs.each do |log_data|
  HackrLog.create!(
    title: log_data[:title],
    slug: log_data[:slug],
    body: log_data[:body].strip,
    author: log_data[:author],
    published: true,
    published_at: log_data[:published_at]
  )
end

puts "Created #{HackrLog.count} hackr logs"

puts "\n✓ HackrLogs seeded successfully!"
puts "Logs span from 2115 to 2125 (lore timeline)"
