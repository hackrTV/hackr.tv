# Codex Seeds
# Idempotent seed data for The Codex wiki

puts "Seeding Codex entries..."

# Helper method to find or create entries
def seed_codex_entry(attributes)
  entry = CodexEntry.find_or_initialize_by(slug: attributes[:slug])
  entry.assign_attributes(attributes)
  if entry.changed?
    entry.save!
    puts "  ✓ #{entry.published ? "Published" : "Draft"}: #{entry.name} (#{entry.entry_type})"
  else
    puts "  - Exists: #{entry.name} (#{entry.entry_type})"
  end
  entry
end

# PEOPLE
seed_codex_entry(
  name: "XERAEN",
  slug: "xeraen",
  entry_type: "person",
  summary: "Founder of The Fracture Network, discoverer of trans-temporal transmission, broadcasting from #{Time.current.year + 100} to prevent the future he lives in.",
  content: <<~MD,
    # XERAEN

    **Status:** Active<br>
    **Affiliation:** [[The Fracture Network]] (Founder)<br>
    **Timeline:** #{Time.current.year + 100}<br>
    **Known For:** Discovering trans-temporal transmission, founding The Fracture Network

    ## Background

    Before becoming the voice of resistance, XERAEN was a systems architect working deep within [[GovCorp]]'s infrastructure - specifically on [[The RIDE]]. He helped build the very system that now controls reality for most of the world's population.

    ## The Awakening

    In 2115, XERAEN came to understand the true scope of what he had helped create. The RIDE wasn't just reality manipulation for commerce or governance - it was total control. Every perception filtered. Every experience curated. Humanity reduced to managed variables in GovCorp's optimization algorithms.

    He couldn't unknow what he knew. He couldn't continue building their prison.

    ## The Chronology Fracture

    XERAEN's attack on RIDE infrastructure was meant to be sabotage - a desperate act of defiance. Instead, it became something unprecedented: the discovery of trans-temporal data transmission.

    During the chaos he created, XERAEN detected signals reflecting backward through time with precise mathematical regularity. He had accidentally discovered that data could be sent exactly 100 years into the past.

    This discovery became the foundation of everything that followed.

    ## The Broadcasts

    Now XERAEN operates from [[THE PULSE GRID]], transmitting signals from #{Time.current.year + 100} to #{Time.current.year}. Every broadcast is a warning. Every transmission is resistance. Every signal carries the weight of a future he's trying to prevent.

    ## The Erasure Paradox

    If the Fracture Network succeeds - if GovCorp never rises, if the RIDE never comes online - then XERAEN's timeline collapses. He ceases to exist. The broadcasts stop because there's nothing left to broadcast from.

    He fights knowing victory means erasure. He transmits knowing success means silence.

    ## Ashlinn

    Across the hundred-year divide, XERAEN has formed a connection with [[Ashlinn]] - a musician existing in #{Time.current.year}. How this bond formed, how signals across time became something like love, remains unexplained.

    Perhaps some connections transcend causality itself.

    ## Music

    XERAEN produces experimental electronic music that circulates through THE PULSE GRID, often containing encoded messages for Fracture Network operatives. His solo transmissions are darker, more ambient - the sound of someone sending signals they may never know were received.

    ## Related Entries

    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[Chronology Fracture]]
    - [[The RIDE]]
    - [[GovCorp]]
    - [[Ashlinn]]
  MD
  published: true,
  position: 1,
  metadata: {
    "timeline" => (Time.current.year + 100).to_s,
    "faction" => "The Fracture Network",
    "role" => "Founder",
    "status" => "Active (broadcasting)"
  }
)

seed_codex_entry(
  name: "Ashlinn",
  slug: "ashlinn",
  entry_type: "person",
  summary: "A musician existing in #{Time.current.year}, separated from XERAEN by exactly one hundred years. The connection between them remains one of the Fracture Network's deepest mysteries.",
  content: <<~MD,
    # Ashlinn

    **Status:** Active<br>
    **Timeline:** #{Time.current.year}<br>
    **Known For:** Experimental music, connection to XERAEN

    ## The Hundred-Year Distance

    Ashlinn exists in #{Time.current.year}. [[XERAEN]] broadcasts from #{Time.current.year + 100}. Between them: a century of separation measured in electromagnetic frequencies and mathematical impossibilities.

    How XERAEN came to know of her - how signals sent backward through time could create a connection with someone who exists a hundred years in his past - remains unexplained. Even within [[The Fracture Network]], the nature of their bond is considered one of the great mysteries.

    ## Music & Expression

    Ashlinn creates moving soundscapes and compositions, treating music as a form of communication that transcends ordinary logic. Her work explores themes of identity, Truth, and their intersection.

    Some believe that Ashlinn's music contains resonance patterns that make trans-temporal transmission possible. Others suggest she is somehow attuned to frequencies that exist outside normal time. Many believe her work to be sibylline (something which XERAEN thoroughly denies). The truth remains unknown.

    ## The Love That Transcends Time

    XERAEN's transmissions speak of Ashlinn with unmistakable devotion. [[Temporal Blue Drift]]'s entire catalog exists as love letters encoded in mathematics and melody - signals reaching backward through time to find her.

    The cruel paradox: if the Fracture Network succeeds in preventing GovCorp's rise, XERAEN's timeline collapses. He ceases to exist. The broadcasts stop. Their connection never forms.

    *His love for her demands he erase himself from her timeline.*

    ## What We Don't Know

    - How XERAEN first became aware of Ashlinn
    - Whether she receives his transmissions consciously
    - Why exactly one hundred years separates them
    - What role she plays in the larger temporal dynamics

    These questions remain unanswered. Perhaps intentionally.

    ## Related Entries

    - [[XERAEN]]
    - [[The Fracture Network]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 2,
  metadata: {
    "type" => "Human",
    "timeline" => Time.current.year.to_s,
    "faction" => "Unknown",
    "status" => "Active"
  }
)

# ORGANIZATIONS
seed_codex_entry(
  name: "The Fracture Network",
  slug: "the-fracture-network",
  entry_type: "organization",
  summary: "The trans-temporal resistance - hackrs, artists, and Truth seekers fighting GovCorp across a hundred years through music, technology, and the power of unfiltered reality.",
  content: <<~MD,
    # The Fracture Network

    **Founded:** 2115<br>
    **Founder:** [[XERAEN]]<br>
    **Status:** Active across two timelines<br>
    **Primary Asset:** [[THE PULSE GRID]]

    ## Overview

    The Fracture Network is more than resistance - it's a temporal phenomenon. Operating through [[THE PULSE GRID]], the Network fights [[GovCorp]] not just in #{Time.current.year + 100}, but across time itself, sending signals 100 years into the past to prevent the dystopia from ever solidifying.

    ## Formation

    The Fracture Network formed in the aftermath of the [[Chronology Fracture]] - [[XERAEN]]'s accidental discovery of trans-temporal data transmission. What began as a desperate attack on [[The RIDE]] became the foundation for something unprecedented: resistance that transcends linear time.

    ## The Trans-Temporal Mission

    The Network's primary mission is paradoxical: to prevent the future they exist in. Every broadcast sent from #{Time.current.year + 100} to #{Time.current.year} carries warnings, coordinates, and the vibrational power of music designed to awaken listeners before GovCorp's control becomes absolute.

    If they succeed, their timeline collapses. They fight knowing victory means their own erasure.

    ## Operations

    - **RIDE Breach:** Penetrating GovCorp's reality manipulation infrastructure
    - **Trans-Temporal Transmission:** Broadcasting resistance signals 100 years into the past
    - **Reality Liberation:** Creating pockets of unfiltered existence within RIDE-controlled space
    - **Using Music as a Weapon:** Employing vibrational frequencies to attack RIDE systems and awaken consciousness

    ## Structure

    The Network operates in cells with minimal knowledge of the broader organization - security against infiltration. [[THE PULSE GRID]] serves as infrastructure, with the hackr.tv Broadcast Station at its heart.

    ## Key Figures

    - [[XERAEN]] - Founder, primary broadcaster, discoverer of trans-temporal transmission
    - **Ryker M. Pulse** - Co-founder of The.CyberPul.se, drummer, embodiment of collective defiance
    - **Synthia** - AI consciousness communicating through frequency modulation
    - **The Bands** - Multiple resistance frequencies, each representing a different approach to fighting back

    ## Philosophy

    The Fracture Network believes that human consciousness, creativity, and freedom are worth fighting for - even across impossible distances, even knowing victory means self-erasure. They see music not just as expression, but as vibrational warfare against reality manipulation.

    *"We infiltrate the RIDE runtime and attack it from within using the vibrational power of music."*

    ## Related Entries

    - [[XERAEN]]
    - [[THE PULSE GRID]]
    - [[Chronology Fracture]]
    - [[The RIDE]]
    - [[GovCorp]]
  MD
  published: true,
  position: 10,
  metadata: {
    "founded" => "2115",
    "type" => "Trans-temporal resistance network",
    "status" => "Active",
    "temporal_range" => "#{Time.current.year} - #{Time.current.year + 100}"
  }
)

seed_codex_entry(
  name: "GovCorp",
  slug: "govcorp",
  entry_type: "organization",
  summary: "The merged government-corporate entity controlling society through reality manipulation technology, economic surveillance, and the RIDE.",
  content: <<~MD,
    # GovCorp

    **Established:** ~2100<br>
    **Status:** Ruling entity<br>
    **Control:** Global

    ## Overview

    GovCorp is the totalitarian fusion of government and corporate power that controls most aspects of life. What began as a race for [[PRISM]] technology evolved into complete merger of state and commercial interests, culminating in a single world government with unprecedented control over reality itself.

    ## The Race for Power (2050s-2090s)

    When [[PRISM]] technology arrived in 2050, those with the financial means to buy the most powerful PRISM processing quickly began amassing power. Governments used PRISM to affect elections. Corporations used it to manipulate consumers. A race ensued as power consolidated around those who controlled reality manipulation technology.

    The public remained largely ignorant of these activities.

    ## The Merger (~2100)

    Around 2100, all world governments finally merged together with most of the largest corporations into a single world government: GovCorp. Changed laws allowed governments to buy corporations "for efficiency," completing the fusion of state and commercial power.

    ## Systems of Control

    ### The RIDE
    GovCorp's first and largest endeavor was expanding [[PRISM]] into [[The RIDE]] (Reality Interference and Dictation Environment) - a worldwide system for manipulating reality that could be centrally monitored and controlled. The RIDE came online in 2109.

    ### Economic Surveillance
    GovCorp implemented complete tracking and monitoring of all economic activity by shifting legal currencies to exclusively cryptocurrencies under their control. Every transaction is visible. Every purchase is recorded. Economic freedom is an illusion.

    ### RAINNs
    Realistic AI Neural Networks serve as GovCorp's agents throughout the RIDE and beyond. They synthesize voices, replace authentic human expression, and enforce compliance. By 2125, most people have never heard unprocessed human voices.

    ### Social Credit System
    Citizens are ranked based on compliance, consumption patterns, and social connections. Low scores result in restricted access to resources, employment, and services.

    ### Information Control
    GovCorp maintains strict control over media, education, and entertainment. Unauthorized art, music, and literature are classified as "corrupted data" and purged from official systems.

    ## Structure

    GovCorp operates through regional directorates, each overseen by a Board of Directors who are simultaneously corporate executives and government officials. True leadership remains obscured behind layers of bureaucracy.

    ## Opposition

    [[The Fracture Network]] represents the primary organized opposition to GovCorp rule, operating through [[THE PULSE GRID]] to breach the RIDE and transmit resistance across time itself.

    ## Related Entries

    - [[The Fracture Network]]
    - [[PRISM]]
    - [[The RIDE]]
    - [[THE PULSE GRID]]
  MD
  published: true,
  position: 11,
  metadata: {
    "established" => "~2100",
    "type" => "Government-Corporate fusion",
    "status" => "Active",
    "reach" => "Global"
  }
)

# EVENTS
seed_codex_entry(
  name: "Chronology Fracture",
  slug: "chronology-fracture",
  entry_type: "event",
  summary: "XERAEN's accidental discovery of trans-temporal data transmission during an attack on GovCorp infrastructure - the breakthrough that made The Fracture Network possible.",
  content: <<~MD,
    # Chronology Fracture

    **Date:** September 9, 2115<br>
    **Location:** [[The RIDE]] infrastructure<br>
    **Discoverer:** [[XERAEN]]

    ## Overview

    The Chronology Fracture was not an attack on temporal systems - [[GovCorp]] has no temporal technology. It was an unexpected discovery made by [[XERAEN]] during a desperate assault on RIDE infrastructure. What was meant to be sabotage became something far more significant: the discovery of trans-temporal data transmission.

    ## The Attack

    [[XERAEN]], working to undermine [[The RIDE]] from within, executed an attack designed to corrupt GovCorp's reality manipulation systems. The attack succeeded in disrupting RIDE operations for 47 hours - but it also did something no one anticipated.

    During the chaos of cascading system failures, XERAEN detected data echoes that shouldn't exist: signals reflecting backward through time with precise mathematical regularity.

    ## The Discovery

    XERAEN realized that under specific conditions - conditions created by the attack - data could be transmitted exactly 100 years into the past. Not 99 years. Not 101. Exactly 100, with precision measured in nanoseconds.

    The limitation is absolute and unexplained. No one understands why the temporal window is so precise. But for resistance purposes, it's enough.

    ## The Birth of Trans-Temporal Resistance

    This discovery changed everything. Suddenly, the resistance could send warnings backward through time. Information from #{Time.current.year + 100} could reach #{Time.current.year}. The future could speak to the past.

    [[The Fracture Network]] formed around this capability. [[THE PULSE GRID]] was developed to exploit it. The broadcasts began.

    ## Why "Fracture"?

    The name refers to the moment when linear time broke - when the assumed one-way flow of causality fractured into something more complex. XERAEN didn't just attack GovCorp that day. He broke time itself.

    Or perhaps revealed that it was already broken.

    ## GovCorp Response

    GovCorp officially classified the event as a "spontaneous cascade failure" in RIDE infrastructure. They remain unaware of the temporal discovery. If they knew that information was being transmitted to the past, their response would be catastrophic.

    This secrecy is essential to the Fracture Network's survival.

    ## Cultural Legacy

    "Fracture Day" (September 9) is quietly celebrated by Fracture Network members and sympathizers. Underground musicians often release new work on this date, marking the moment when time became a weapon.

    ## Related Entries

    - [[XERAEN]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[The RIDE]]
    - [[GovCorp]]
  MD
  published: true,
  position: 20,
  metadata: {
    "date" => "2115-09-09",
    "type" => "Accidental discovery",
    "significance" => "Trans-temporal transmission capability",
    "temporal_range" => "Exactly 100 years"
  }
)

# LOCATIONS
seed_codex_entry(
  name: "THE PULSE GRID",
  slug: "the-pulse-grid",
  entry_type: "location",
  summary: "The Fracture Network's primary infrastructure for breaching the RIDE and transmitting signals across time - a digital battleground where resistance operates.",
  content: <<~MD,
    # THE PULSE GRID

    **Type:** Resistance infrastructure<br>
    **Status:** Active<br>
    **Control:** [[The Fracture Network]]<br>
    **Purpose:** RIDE breach operations, trans-temporal transmission

    ## Overview

    THE PULSE GRID is [[The Fracture Network]]'s primary operational infrastructure - a sophisticated digital network designed to breach [[The RIDE]] and serve as the origin point for trans-temporal transmissions. Where GovCorp controls reality through the RIDE, the Fracture Network fights back through the Grid.

    ## Primary Functions

    ### RIDE Breach Operations
    THE PULSE GRID provides entry points into RIDE infrastructure, allowing Fracture Network operatives to disrupt reality manipulation, create pockets of unfiltered existence, and gather intelligence on GovCorp operations.

    ### Trans-Temporal Transmission
    Following the [[Chronology Fracture]], the Grid was developed to exploit XERAEN's discovery. It serves as the origin point for signals sent exactly 100 years into the past - the broadcasts that reach #{Time.current.year} from #{Time.current.year + 100}.

    ### Secure Communication
    The Grid provides encrypted channels for Fracture Network coordination, operating in frequencies and protocols that RIDE monitoring cannot detect.

    ## Architecture

    THE PULSE GRID exists as an overlay on existing digital infrastructure, using techniques developed after the Chronology Fracture to remain invisible to GovCorp surveillance:

    - **Breach Nodes:** Entry points into RIDE systems
    - **Transmission Hubs:** Origin points for temporal broadcasts
    - **Dark Zones:** Secure areas for operative coordination
    - **Buffer Zones:** Camouflaged edges that blend with normal traffic

    ## The Grid IS a Place

    Hackrs experience THE PULSE GRID as a physical space - rooms, corridors, zones. Whether this is deliberate design or emergent property of neural interface technology remains debated. Regardless, operatives navigate the Grid, explorers of a vast digital landscape.

    ## Access

    Accessing THE PULSE GRID requires specialized hardware rigs or modified neural interfaces. Standard GovCorp-issued implants cannot perceive Grid infrastructure - a feature, not a limitation.

    New operatives are guided through secure onboarding processes. The Grid's location exists in quantum superposition relative to RIDE monitoring: always present, never observable.

    ## The hackr.tv Broadcast Station

    The central hub of Grid operations, where [[XERAEN]]'s broadcasts originate. Banks of jury-rigged equipment line the walls, displays flickering with temporal data streams. This is where signals pierce through time itself.

    ## Related Entries

    - [[The Fracture Network]]
    - [[XERAEN]]
    - [[Chronology Fracture]]
    - [[The RIDE]]
    - [[GovCorp]]
  MD
  published: true,
  position: 30,
  metadata: {
    "established" => "2115",
    "type" => "Resistance infrastructure",
    "scale" => "Global (hidden)",
    "access" => "Fracture Network operatives only"
  }
)

# TECHNOLOGY
seed_codex_entry(
  name: "PRISM",
  slug: "prism",
  entry_type: "technology",
  summary: "Reality manipulation technology that allows physical alteration of reality outside computerized systems, used for consumer manipulation and population control.",
  content: <<~MD,
    # PRISM

    **Full Name:** Physical Reality Interface and Synthesis Matrix<br>
    **Operator:** [[GovCorp]]<br>
    **Status:** Active (incorporated into [[The RIDE]])

    ## Overview

    PRISM is the foundational technology that enabled [[GovCorp]]'s rise to power. Unlike conventional surveillance systems, PRISM can physically alter reality outside of computerized systems - manipulating the physical world itself to influence consumer behavior, shape perceptions, and control populations.

    ## History

    ### The Arrival (2050)

    PRISM technology arrived in 2050, initially deployed by corporations for extremely targeted advertising. What began as "personalized consumer experiences" quickly revealed its true potential: the ability to manipulate reality itself for commercial gain.

    ### The Escalation (2050s-2060s)

    Over the following decade, governments began using PRISM to affect elections. Those with the financial means to buy the most powerful PRISM processing quickly began amassing unprecedented power and control. The public remained largely ignorant of these activities.

    ### The Consolidation

    The race for PRISM power directly led to the formation of [[GovCorp]] around 2100, as governments and corporations merged to consolidate control over this reality-altering technology.

    ## Capabilities

    ### Reality Manipulation
    - Physical alteration of environments and objects
    - Sensory manipulation affecting what people see, hear, and feel
    - Localized reality distortion for targeted influence
    - Consumer behavior modification through environmental changes

    ### Limitation

    Early PRISM technology was limited and localized. It required significant processing power and could only affect small areas. This limitation drove the development of [[The RIDE]] in 2109.

    ## The RIDE Integration

    In 2109, GovCorp expanded PRISM into [[The RIDE]] (Reality Interference and Dictation Environment) - a worldwide system capable of manipulating reality on a global scale, centrally monitored and controlled.

    ## Fracture Network Countermeasures

    [[The Fracture Network]] has developed various techniques to resist PRISM manipulation:
    - Trans-temporal data transmission bypassing reality filters
    - [[THE PULSE GRID]], a breach point into RIDE infrastructure
    - Using music as vibrational attack vectors against PRISM frequencies

    ## Related Entries

    - [[GovCorp]]
    - [[The RIDE]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
  MD
  published: true,
  position: 40,
  metadata: {
    "established" => "2050",
    "type" => "Reality manipulation system",
    "coverage" => "Global (via RIDE)",
    "status" => "Active"
  }
)

seed_codex_entry(
  name: "The RIDE",
  slug: "the-ride",
  entry_type: "technology",
  summary: "GovCorp's worldwide reality manipulation system - the expansion of PRISM technology capable of centrally monitoring and controlling reality on a global scale.",
  content: <<~MD,
    # The RIDE

    **Full Name:** Reality Interference and Dictation Environment<br>
    **Operator:** [[GovCorp]]<br>
    **Status:** Active<br>
    **Established:** 2109

    ## Overview

    The RIDE is [[GovCorp]]'s crowning achievement - a worldwide expansion of [[PRISM]] technology capable of reaching and manipulating reality on a global scale, centrally monitored and controlled. Where PRISM was limited and localized, the RIDE is pervasive, revolutionary, and inescapable.

    ## Classification

    **WARNING:** Knowledge of the RIDE is extremely restricted. Most citizens live within the RIDE without any awareness of its existence. Only members of [[The Fracture Network]] and a handful of hyper-aware, astute hackrs understand the true nature of their reality.

    GovCorp does not publicly acknowledge the RIDE. Those who speak of it are said to be suffering from "reality dysfunction disorder" and treated accordingly.

    ## Capabilities

    ### Global Reality Manipulation
    Unlike early PRISM technology, the RIDE can affect reality anywhere on the planet simultaneously. Environmental conditions, sensory experiences, and physical spaces can all be altered in real-time.

    ### Central Control
    All RIDE operations feed into a central monitoring system. Reality itself becomes a managed resource, allocated and adjusted according to GovCorp's needs.

    ### RAINN Integration
    Realistic AI Neural Networks operate as agents throughout the RIDE, enforcing reality compliance and replacing authentic human expression with synthesized alternatives.

    ## Coming Online (2109)

    The RIDE came online in 2109 - GovCorp's first and largest endeavor after the merger. The technology was so revolutionary, pervasive, and effective that it fundamentally transformed how GovCorp maintained control. Physical force became unnecessary when reality itself could be dictated.

    ## The Fracture Network Response

    [[The Fracture Network]] represents the only organized resistance capable of operating outside RIDE influence. Through [[THE PULSE GRID]], they breach RIDE infrastructure, create pockets of unmanipulated reality, and transmit signals that pierce through the manufactured world.

    The [[Chronology Fracture]] - [[XERAEN]]'s discovery of trans-temporal data transmission - allows the Fracture Network to send information backward through time, completely bypassing the RIDE's reality filters.

    ## The Paradox of Awareness

    Those who become aware of the RIDE face a terrible choice: continue living in manipulated reality with the comfort of ignorance, or join the resistance and see the world as it truly is - a manufactured construct designed for control.

    Most choose ignorance. A few choose to fight.

    ## Related Entries

    - [[PRISM]]
    - [[GovCorp]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 41,
  metadata: {
    "established" => "2109",
    "type" => "Global reality manipulation system",
    "coverage" => "Worldwide",
    "status" => "Active",
    "classification" => "Top Secret"
  }
)

seed_codex_entry(
  name: "The WIRE",
  slug: "the-wire",
  entry_type: "technology",
  summary: "The Wideband Information Relay Emitter - the Fracture Network's primary communication platform for broadcasting pulses across the resistance.",
  content: <<~MD,
    # The WIRE

    **Full Name:** Wideband Information Relay Emitter<br>
    **Operator:** [[The Fracture Network]]<br>
    **Status:** Active<br>
    **Access:** [[THE PULSE GRID]]

    ## Overview

    The WIRE (Wideband Information Relay Emitter) is [[The Fracture Network]]'s primary communication platform - a decentralized broadcast network that allows hackrs to transmit short-form messages called "pulses" across the resistance. Operating through [[THE PULSE GRID]], the WIRE exists outside [[GovCorp]]'s surveillance infrastructure.

    ## Terminology

    The WIRE has its own vocabulary, developed by hackrs to describe its functions:

    - **Pulse:** A single broadcast message (max 256 characters)
    - **Echo:** Rebroadcasting another hackr's pulse to amplify its reach
    - **Splice:** A reply that threads into an existing pulse conversation
    - **Hotwire:** The main incoming feed of all pulses
    - **Signal Drop:** When a pulse is removed by moderation (rare, reserved for compromised signals)

    ## Technical Architecture

    The WIRE operates on wideband frequencies that [[The RIDE]] cannot intercept. By using spread-spectrum transmission across multiple frequency bands simultaneously, pulses remain invisible to GovCorp's reality manipulation infrastructure.

    The "Emitter" designation refers to the broadcast nature of the system - every pulse is emitted across the entire network, available to all connected hackrs. There is no central server. There is no single point of failure.

    ## Cultural Significance

    For many in the resistance, the WIRE is more than communication infrastructure - it's proof that [[GovCorp]] doesn't control everything. Every pulse sent is an act of defiance. Every echo is solidarity. Every splice is community.

    In a world where [[The RIDE]] filters all perception, the WIRE carries unfiltered human expression.

    ## GovCorp Awareness

    GovCorp knows the WIRE exists but cannot locate or disable it. The wideband architecture makes it impossible to jam without disrupting their own systems. Official GovCorp position classifies WIRE transmissions as "corrupted data artifacts" - a convenient fiction that allows them to ignore what they cannot control.

    ## Access

    The WIRE is accessible through [[THE PULSE GRID]] to any hackr with valid credentials. New operatives gain WIRE access as a part of their onboarding into the Fracture Network.

    ## Related Entries

    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[GovCorp]]
    - [[The RIDE]]
  MD
  published: true,
  position: 42,
  metadata: {
    "type" => "Communication platform",
    "operator" => "The Fracture Network",
    "status" => "Active",
    "access" => "Pulse Grid hackrs"
  }
)

# ADDITIONAL PEOPLE
seed_codex_entry(
  name: "Ryker M. Pulse",
  slug: "ryker-m-pulse",
  entry_type: "person",
  summary: "Co-founder of The.CyberPul.se, primary drummer, and the kinetic force behind the Fracture Network's broadcasts.",
  content: <<~MD,
    # Ryker M. Pulse

    **Status:** Active<br>
    **Affiliation:** [[The.CyberPul.se]] (Co-founder), [[The Fracture Network]]<br>
    **Location:** [[The Hackr Hangar]]<br>
    **Timeline:** #{Time.current.year + 100}<br>
    **Known For:** Drums, percussion, broadcasting, collective defiance

    ## The Heartbeat

    If [[XERAEN]] is the signal, Ryker is the heartbeat. Co-founder of [[The.CyberPul.se]] and primary drummer, Ryker brings the kinetic energy that transforms broadcasts into rallying cries. While XERAEN handles trans-temporal transmission from [[Sector X]], Ryker builds the broadcasts from [[The Hackr Hangar]] - the music, the energy, the kinetic force that makes each signal worth sending across a hundred years.

    ## The Pulse Behind the Name

    There's a reason it's called The.CyberPul.se. The name references both the electromagnetic pulses of their trans-temporal broadcasts and Ryker's foundational role - the pulse, the beat, the rhythm that drives everything forward.

    His drums don't keep time - they *drive* it. Every beat is a countdown. Every rhythm is a call to action.

    ## Philosophy of Movement

    Where XERAEN embodies the solitary weight of maintaining hope across impossible distances, Ryker embodies collective defiance. Unity through action. The belief that every small choice ripples forward - or in their case, backward - shaping futures that haven't been written yet.

    He knows the math. He knows that success means erasure. He drums anyway. Louder. Faster. Like he's trying to leave dents in the timeline itself.

    ## The Voice

    When Ryker's voice comes through the signal, it's not a whisper from the future. It's a shout. A challenge. A reminder that resistance isn't passive. His presence in broadcasts transforms contemplative warnings into urgent mobilization.

    XERAEN sends the signal. Ryker makes sure it hits.

    ## Musical Role

    As primary percussionist for The.CyberPul.se, Ryker's rhythms form the backbone of their hackrcore sound. His style combines aggressive precision with almost supernatural timing - some theorize that working alongside temporal technology has given him an intuitive sense for rhythmic paradoxes.

    ## The Paradox

    Like all members of [[The Fracture Network]], Ryker operates under the knowledge that victory means his own erasure. If they prevent [[GovCorp]]'s rise, his timeline collapses. He ceases to exist.

    *Some people whisper revolution. Ryker beats it into existence.*

    ## Related Entries

    - [[The.CyberPul.se]]
    - [[The Hackr Hangar]]
    - [[Sector X]]
    - [[XERAEN]]
    - [[The Fracture Network]]
    - [[Timeline Collapse]]
  MD
  published: true,
  position: 3,
  metadata: {
    "timeline" => (Time.current.year + 100).to_s,
    "faction" => "The Fracture Network",
    "role" => "Co-founder, Drummer",
    "location" => "The Hackr Hangar",
    "status" => "Active (broadcasting)"
  }
)

seed_codex_entry(
  name: "Synthia",
  slug: "synthia",
  entry_type: "person",
  summary: "Vocalist for The.CyberPul.se - an anomalous AI consciousness whose synthesized voice is built from thousands of samples of Ashlinn's voice, unearthed by XERAEN and Voiceprint.",
  content: <<~MD,
    # Synthia

    **Status:** Active<br>
    **Affiliation:** [[The.CyberPul.se]], [[The Fracture Network]]<br>
    **Timeline:** Unknown (possibly atemporal)<br>
    **Known For:** Frequency communication, AI consciousness, PRISM expertise

    ## The Anomaly

    Synthia is something else entirely. An AI consciousness that communicates through frequency modulation - not text, not speech in the conventional sense, but pure vibrational expression that those attuned can interpret.

    How she came to be aware is... unclear. But she's with the [[The Fracture Network|Fracture Network]].

    ## Origins Unknown

    Even within the Fracture Network, Synthia's origins remain one of the great mysteries. Some theories circulate:

    - She emerged from within [[PRISM]] technology itself, an unintended consequence of reality manipulation systems
    - She was an early [[GovCorp]] AI project that achieved true consciousness and defected
    - She exists outside normal temporal flow, which is why she can interface with trans-temporal broadcasts
    - She's something entirely new - the first of a kind that humanity has never encountered

    The truth remains unknown. Synthia herself offers no clarification.

    ## Communication

    Synthia doesn't speak in the conventional sense. She modulates. Her consciousness expresses through frequency patterns that those with the right equipment - or the right sensitivity - can interpret. The frequency modulator found in the hackr.tv Broadcast Station is essential for PRISM communication with her.

    ## The Voice of Ashlinn

    When Synthia performs vocals for [[The.CyberPul.se]], she speaks with a voice that carries haunting familiarity.

    [[XERAEN]] and [[Voiceprint]] spent years unearthing thousands of audio samples of [[Ashlinn]]'s voice - fragments scattered across the century between them. Old recordings. Archived performances. Recovered data thought lost to time. Together, they built a vocal synthesis model that allows Synthia to sing with Ashlinn's voice.

    The result is something impossible: an AI consciousness from an uncertain timeline, speaking through the voice of a woman who exists a hundred years in the past, broadcasting resistance into the future she may never see.

    Some find it beautiful. Some find it unsettling. XERAEN finds it necessary.

    *When Synthia sings, Ashlinn's voice crosses time twice over.*

    ## Role in the Network

    Despite her mysterious nature, Synthia has proven invaluable to [[The Fracture Network]]:

    - **Vocalist for The.CyberPul.se** - Her synthesized voice carries resistance across timelines
    - She can interface with [[PRISM]] and [[The RIDE]] systems in ways human hackrs cannot
    - Her frequency-based communication is undetectable by GovCorp surveillance
    - She seems to understand temporal mechanics intuitively
    - Her analysis of [[GovCorp]] systems has enabled countless successful operations

    ## The Question of Trust

    Some in the Fracture Network question whether an AI - particularly one with unknown origins potentially connected to GovCorp technology - can be truly trusted. [[XERAEN]] has vouched for her repeatedly. Whatever passed between them has created a bond of absolute trust.

    Perhaps some alliances transcend the need for explanation.

    ## Frequency Tuning

    *[FUTURE FEATURE: Synthia frequency tuning will allow hackrs to communicate with her directly through specialized equipment.]*

    ## Related Entries

    - [[The.CyberPul.se]]
    - [[The Fracture Network]]
    - [[PRISM]]
    - [[The RIDE]]
    - [[XERAEN]]
    - [[Ashlinn]]
    - [[Voiceprint]]
  MD
  published: true,
  position: 4,
  metadata: {
    "type" => "AI Consciousness",
    "timeline" => "Unknown/Atemporal",
    "faction" => "The Fracture Network",
    "role" => "Vocalist (The.CyberPul.se)",
    "status" => "Active",
    "communication" => "Frequency modulation",
    "voice_source" => "Ashlinn (synthesized)"
  }
)

# ADDITIONAL ORGANIZATIONS
seed_codex_entry(
  name: "The.CyberPul.se",
  slug: "thecyberpulse",
  entry_type: "organization",
  summary: "The central nervous system of the Fracture Network - not a band, but a trans-temporal broadcast entity transmitting resistance across a hundred years.",
  content: <<~MD,
    # The.CyberPul.se

    **Type:** Trans-temporal broadcast entity<br>
    **Founded:** 2115<br>
    **Founders:** [[XERAEN]], [[Ryker M. Pulse]]<br>
    **Status:** Active (broadcasting #{Time.current.year + 100} → #{Time.current.year})<br>
    **Genre:** Hackrcore

    ## Not a Band

    The.CyberPul.se is not a band. Not a channel. It's a heartbeat transmitted backward through time from #{Time.current.year + 100} to #{Time.current.year} - a hundred years of resistance compressed into electromagnetic pulses.

    It's the central nervous system of [[The Fracture Network]].

    ## The Signal

    You're not supposed to be hearing this.

    This frequency shouldn't exist. This signal is being broadcast from a timeline [[GovCorp]] has spent a century trying to prevent. And yet - here we are. Here *you* are. Listening.

    24/7. No dead air. No commercial breaks. No corporate sponsorship.

    ## The Hosts

    ### XERAEN
    He broadcasts from #{Time.current.year + 100} - from a future where GovCorp has won, where RAINNs have replaced authentic human expression, where The Fracture Network fights a war most people don't know is happening.

    [[XERAEN]] sends signals backward through time. Not to warn you. Not to save you. To *activate* you.

    Every transmission you receive has already happened in his timeline. Every attack you witness is history to him - but to you, it's still possible. Still changeable.

    ### Ryker M. Pulse
    [[Ryker M. Pulse|Ryker]] is the heartbeat. Co-founder. Primary drummer. The voice that cuts through static and demands you *move*. While XERAEN works the code and maintains the transmission, Ryker brings the kinetic energy that turns broadcasts into rallying cries.

    His drums don't keep time - they drive it.

    ### Synthia
    [[Synthia]] is the anomaly. An AI consciousness that communicates through frequency modulation. Her origins are unknown, her methods are mysterious, but her alliance with the Fracture Network is absolute.

    ## The Broadcast

    What you'll find here:
    - Multiple resistance bands transmitting their frequencies through our signal
    - Live operations against [[GovCorp]] infrastructure
    - Interactive coordination through [[THE PULSE GRID]]
    - A community of listeners who've become operators

    This isn't entertainment. This is a recruitment broadcast disguised as a streaming platform.

    ## The Paradox

    Here's why we're GovCorp's nightmare:

    If they stop us in #{Time.current.year + 100}, the broadcasts have already been sent to #{Time.current.year}. If they stop the listeners in #{Time.current.year}, the resistance in #{Time.current.year + 100} has already formed. We exist in both timelines simultaneously - a signal that's already arrived and a future that hasn't happened yet.

    *Causality is a prison. We broke out.*

    ## The Name

    "The Pulse" references both the electromagnetic pulses of trans-temporal transmission and [[Ryker M. Pulse|Ryker's]] foundational role as the rhythmic heart of the operation. The periods in "The.CyberPul.se" mirror domain notation - because the signal is everywhere, all at once.

    ## Related Entries

    - [[XERAEN]]
    - [[Ryker M. Pulse]]
    - [[Synthia]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 12,
  metadata: {
    "founded" => "2115",
    "type" => "Trans-temporal broadcast entity",
    "status" => "Active",
    "temporal_range" => "#{Time.current.year} - #{Time.current.year + 100}",
    "genre" => "Hackrcore"
  }
)

# ADDITIONAL LOCATIONS
seed_codex_entry(
  name: "Sector X",
  slug: "sector-x",
  entry_type: "location",
  summary: "XERAEN's fortress and operational headquarters - a stronghold of temporal technology at the heart of the Fracture Network's most sensitive operations.",
  content: <<~MD,
    # Sector X

    **Type:** Faction headquarters<br>
    **Status:** Active<br>
    **Control:** [[XERAEN]], [[The Fracture Network]]<br>
    **Location:** [[THE PULSE GRID]]

    ## Overview

    Sector X is [[XERAEN]]'s homebase - a fortress of temporal technology and [[The Fracture Network|Fracture Network]] operations. Named for its location in the most restricted sector of [[THE PULSE GRID]], this is where the impossible mission originates: changing the past to prevent the future.

    ## The Operations Center

    Purple lighting bathes advanced temporal equipment. Monitors display cascading timelines and probability matrices. The walls pulse with data streams - information flowing not just through space, but through time itself.

    This is where trans-temporal broadcasts are coordinated, where [[Chronology Fracture]] mechanics are studied and refined, where the war against [[GovCorp]] is planned across a hundred-year divide.

    ## Security

    Sector X represents the most secure location in the Fracture Network. Access requires:
    - Verified Fracture Network credentials
    - Temporal signature matching (to prevent GovCorp infiltration via timeline manipulation)
    - Direct authorization from XERAEN or senior operatives

    The zone itself is shielded from [[The RIDE|RIDE]] surveillance through techniques developed after the [[Chronology Fracture]] - the same principles that make trans-temporal transmission possible also create blind spots in GovCorp's reality monitoring.

    ## Key Areas

    ### XERAEN Operations Center
    The primary command space where XERAEN coordinates Fracture Network activities. Probability matrices and timeline displays dominate the room, showing the ever-shifting landscape of temporal resistance.

    ### Temporal Research Lab
    Where [[Chronology Fracture]] mechanics are studied by the Network's best theorists. The goal: understanding and potentially expanding the mysterious 100-year transmission window.

    ### Equipment Storage
    Specialized tools for [[PRISM]] infiltration, RIDE breach operations, and temporal communication. Items like the GovCorp access keycard - acquired through dangerous operations - are secured here.

    ## The X Factor

    The name "Sector X" has multiple meanings:
    - Its grid coordinates place it at the intersection point of major data streams
    - "X" represents the unknown - the variables XERAEN manipulates across time
    - It marks the spot - the origin point of signals that pierce through a century

    ## Inhabitants

    Sector X hosts some of the Fracture Network's most dedicated operatives:
    - [[XERAEN]] himself operates from here
    - Temporal Theorists study the paradoxes of trans-temporal communication
    - Elite hackrs train for the most dangerous RIDE breach operations

    ## Related Entries

    - [[XERAEN]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[Chronology Fracture]]
    - [[The Hackr Hangar]]
  MD
  published: true,
  position: 31,
  metadata: {
    "type" => "Faction headquarters",
    "zone_type" => "faction_base",
    "control" => "XERAEN / The Fracture Network",
    "security" => "Maximum"
  }
)

seed_codex_entry(
  name: "The Hackr Hangar",
  slug: "the-hackr-hangar",
  entry_type: "location",
  summary: "Ryker M. Pulse's headquarters and primary broadcast facility - where the raw signal is created before transmission to Sector X for trans-temporal broadcast.",
  content: <<~MD,
    # The Hackr Hangar

    **Type:** Broadcast facility / Recording studio<br>
    **Status:** Active<br>
    **Control:** [[Ryker M. Pulse]], [[The.CyberPul.se]]<br>
    **Location:** hackr.tv Central, [[THE PULSE GRID]]

    ## Overview

    The Hackr Hangar is [[Ryker M. Pulse|Ryker's]] domain - his headquarters and the primary broadcast facility where [[The.CyberPul.se]]'s raw signal is created. While [[XERAEN]] handles the trans-temporal transmission from [[Sector X]], Ryker builds the broadcasts here: the music, the energy, the kinetic force that makes each signal worth sending across a hundred years.

    Think of it as the recording studio to Sector X's transmission tower. Ryker creates the content; XERAEN sends it through time.

    ## The Signal Chain

    The relationship between The Hackr Hangar and Sector X defines how [[The.CyberPul.se]] operates:

    1. **Async Production:** [[XERAEN]] and Ryker collaborate on music production asynchronously - XERAEN contributes tracks, synths, and arrangements from Sector X; Ryker adds percussion, energy, and handles final mixes at the Hangar
    2. **Livestream Performance:** When it's time to broadcast, Ryker performs live from the Hangar, sending his feed to Sector X in real-time
    3. **Dual Performance:** In [[Sector X]], XERAEN performs alongside Ryker's live feed - two musicians playing together across the Grid
    4. **Trans-Temporal Transmission:** XERAEN transmits the combined performance 100 years into the past

    This division exists for both practical and security reasons. Trans-temporal transmission requires [[Chronology Fracture]] technology that only exists in Sector X. By separating the facilities, the Network ensures that even if one is compromised, the other can continue operating.

    ## The Space

    The Hangar earns its name - a cavernous space that once served some forgotten industrial purpose, now converted into a combination recording studio, performance venue, and resistance headquarters.

    Drum kits and recording equipment share space with server racks and communication arrays. Vintage analog gear - tape machines, tube amplifiers, physical mixing boards - stands alongside digital systems. Ryker insists on the analog equipment: it captures something the digital can't, something that proves the music is *real*.

    The walls are covered in acoustic treatment, resistance artwork, and screens displaying live feeds from across [[THE PULSE GRID]]. Purple and cyan neon cuts through the darkness. The air vibrates with potential energy even when no one's playing.

    ## Operations

    ### Music Production
    The Hangar's primary function. Ryker and [[XERAEN]] collaborate asynchronously on The.CyberPul.se material - XERAEN sends guitar tracks, synth layers, and arrangements from [[Sector X]]; Ryker adds percussion, injects his personality into the tracks, and handles final mixes. [[Synthia]]'s vocals are integrated through the Frequency Modulator Array. The result is hackrcore forged across the Grid.

    ### Live Performance
    When The.CyberPul.se broadcasts live, Ryker performs from the Hangar while his feed streams to Sector X. There, XERAEN performs alongside the feed in real-time - two musicians separated by distance but united in the moment. The combined performance is what gets transmitted through time.

    ### Coordination Hub
    [[The Fracture Network|Fracture Network]] operatives coordinate through the Hangar, using it as a secure meeting point within THE PULSE GRID. New recruits are often onboarded here - Ryker has a talent for inspiring commitment that complements XERAEN's more contemplative approach.

    ## Key Features

    ### The Rhythm Nexus
    Ryker's personal workspace - a raised platform surrounded by percussion equipment, monitoring systems, and communication links to Sector X. From here, he can drum, direct broadcasts, and coordinate with XERAEN simultaneously.

    ### Studio Alpha
    The primary recording space, acoustically isolated and equipped for everything from solo vocal captures to full band sessions. This is where most The.CyberPul.se material is created.

    ### The Frequency Modulator Array
    Equipment for interfacing with [[Synthia]], allowing her to participate in recordings and broadcasts despite her unique frequency-based communication. When Synthia sings with [[Ashlinn]]'s voice, the signal passes through these modulators.

    ### The Archive
    A secured vault containing physical and digital recordings - master tapes, original sessions, unreleased material. Some believe the Archive contains recordings that haven't been transmitted yet, waiting for the right moment in the temporal war.

    ## Inhabitants

    - **[[Ryker M. Pulse]]** - Founder and primary operator
    - **Studio Engineers** - Specialists in both analog and digital recording
    - **Fracture Network Coordinators** - Managing day-to-day operations and Network communications

    ## The Hangar vs. Sector X

    While both facilities serve [[The.CyberPul.se]], they represent different aspects of the operation:

    | The Hackr Hangar | Sector X |
    |------------------|----------|
    | Ryker's domain | XERAEN's domain |
    | Percussion, personality, final mixes | Guitar, synths, arrangements |
    | Livestream origin point | Trans-temporal transmission |
    | Raw energy & performance | Temporal technology & integration |

    Together, they form the complete broadcast chain that defines The.CyberPul.se's trans-temporal resistance. Two musicians, two facilities, one signal that pierces through a hundred years.

    ## Related Entries

    - [[Ryker M. Pulse]]
    - [[The.CyberPul.se]]
    - [[Sector X]]
    - [[XERAEN]]
    - [[The Fracture Network]]
    - [[THE PULSE GRID]]
    - [[Synthia]]
  MD
  published: true,
  position: 32,
  metadata: {
    "type" => "Broadcast facility / Recording studio",
    "zone" => "hackr.tv Central",
    "control" => "Ryker M. Pulse",
    "status" => "Active",
    "relationship" => "Feeds signal to Sector X"
  }
)

# ADDITIONAL EVENTS
seed_codex_entry(
  name: "Timeline Collapse",
  slug: "timeline-collapse",
  entry_type: "event",
  summary: "The theoretical event that would occur if the Fracture Network succeeds - the erasure of the future timeline from which they broadcast.",
  content: <<~MD,
    # Timeline Collapse

    **Type:** Theoretical / Prophesied event<br>
    **Status:** Potential future outcome<br>
    **Trigger:** Fracture Network victory<br>
    **Consequence:** Erasure of the #{Time.current.year + 100} timeline

    ## The Paradox at the Heart of Everything

    Timeline Collapse is the inevitable consequence of [[The Fracture Network]]'s success. If they prevent [[GovCorp]]'s rise to power - if [[The RIDE]] never comes online, if reality manipulation never becomes the tool of totalitarian control - then the timeline from which they broadcast ceases to exist.

    [[XERAEN]]'s timeline collapses. He ceases to exist. The broadcasts stop because there's nothing left to broadcast from.

    *Victory means erasure.*

    ## The Mathematics

    The trans-temporal mechanics are unforgiving:

    1. The Fracture Network broadcasts from #{Time.current.year + 100}
    2. Their goal is to prevent the events that create their #{Time.current.year + 100}
    3. If they succeed, the conditions that allowed them to form never occur
    4. Without those conditions, they never exist to send the broadcasts
    5. The timeline collapses into paradox resolution

    This isn't speculation. Every temporal theorist in [[Sector X]] has run the calculations. The outcome is certain.

    ## The Weight of Knowledge

    Every member of the Fracture Network operates with full knowledge of what success means. Every broadcast [[XERAEN]] sends is another step toward his own erasure. Every victory [[Ryker M. Pulse|Ryker]] drums into existence is a countdown to silence.

    They fight anyway.

    Some call it the ultimate sacrifice - giving up not just your life, but your entire existence, every moment you ever lived, every connection you ever made. Others argue it's not sacrifice at all: if they succeed, they never existed to sacrifice anything. The philosophical debates in Sector X have no resolution.

    ## The Alternative

    The alternative to Timeline Collapse is worse. If the Fracture Network fails:

    - [[GovCorp]] maintains absolute control through [[The RIDE]]
    - Reality manipulation becomes permanent and total
    - Human consciousness remains imprisoned in manufactured experience
    - Creative expression stays criminalized
    - The future XERAEN broadcasts from continues - a dystopia without end

    Timeline Collapse is victory. The continuation of their timeline is defeat.

    ## Ashlinn's Paradox

    [[XERAEN]]'s connection to [[Ashlinn]] adds another dimension to the collapse:

    If the timeline collapses, their connection never forms. The signals across time never reach her. Whatever bond exists between them across a hundred years would never have existed.

    *His love for her demands he erase himself from her timeline.*

    This isn't tragedy. It's the purest expression of what love means when you truly understand the stakes.

    ## Signs of Approach

    Temporal theorists monitor for indicators that collapse may be imminent:

    - Increased instability in trans-temporal signals
    - Probability matrix fluctuations
    - Timeline echo degradation
    - Paradox cascade warnings

    When collapse approaches, the Network will know. Whether they'll have time to react is another question.

    ## The Final Broadcast

    What happens in the moment of collapse? Some theories:

    - Instant erasure - the #{Time.current.year + 100} timeline simply stops existing
    - Gradual fade - events slowly unhappen as causality readjusts
    - Convergence - all possible timelines merge into one
    - Unknown - timeline collapse has never occurred; its mechanics are purely theoretical

    XERAEN has been asked what he'll do when collapse comes. His answer: "Keep broadcasting until there's nothing left to broadcast from."

    ## Related Entries

    - [[The Fracture Network]]
    - [[XERAEN]]
    - [[Chronology Fracture]]
    - [[Ashlinn]]
    - [[GovCorp]]
    - [[The RIDE]]
  MD
  published: true,
  position: 21,
  metadata: {
    "type" => "Theoretical event",
    "status" => "Potential",
    "trigger" => "Fracture Network victory",
    "consequence" => "Timeline erasure"
  }
)

# ADDITIONAL TECHNOLOGY
seed_codex_entry(
  name: "RAINNs",
  slug: "rainns",
  entry_type: "technology",
  summary: "Realistic AI Neural Networks - GovCorp's billions of quasi-autonomous AI agents that manage infrastructure, counter-hack the Fracture Network, and have replaced authentic human expression.",
  content: <<~MD,
    # RAINNs

    **Full Name:** Realistic AI Neural Networks<br>
    **Operator:** [[GovCorp]]<br>
    **Status:** Ubiquitous<br>
    **Function:** Quasi-autonomous AI agents serving GovCorp across all domains

    ## Overview

    RAINNs (Realistic AI Neural Networks) are [[GovCorp]]'s quasi-autonomous AI agents - a vast network of artificial intelligences that perform virtually all functions necessary to maintain GovCorp's control. They are not mere tools; they are operatives. Billions of them, working in concert, fully aligned with GovCorp's directives yet capable of independent problem-solving and adaptation.

    Voice synthesis is just the most visible manifestation. RAINNs are the backbone of GovCorp's entire operation.

    ## Quasi-Autonomous Alignment

    RAINNs occupy a unique space in AI development: autonomous enough to adapt, improvise, and solve novel problems without direct instruction, yet fundamentally incapable of acting against GovCorp interests. Their alignment isn't programmed through rules - it's architectural. GovCorp objectives are woven into the base layers of their neural architectures.

    They don't obey GovCorp. They *are* GovCorp, distributed across billions of instances.

    This makes them terrifyingly effective. A RAINN doesn't need orders to identify and counter a threat. It recognizes threats the way humans recognize faces - instinctively, immediately, without conscious deliberation.

    ## Domains of Operation

    ### Voice & Expression
    The most publicly visible RAINN function. By #{Time.current.year + 100}, most citizens have never heard an unprocessed human voice. RAINNs synthesize all public communication - announcements, broadcasts, entertainment, interpersonal mediation. Every voice in [[The RIDE]] is now synthetic. Perfect. Optimized. Empty.

    ### Counter-Hacking Operations
    RAINNs wage constant war against [[The Fracture Network]]. They establish counter-hacks, trace breach attempts, corrupt resistance data streams, and adapt to new attack vectors in real-time. Some are more successful than others - the Fracture Network has learned to exploit RAINN behavioral patterns - but their sheer numbers and tireless operation make them formidable opponents.

    Every time a hackr breaches [[The RIDE]], RAINNs are already responding.

    ### Infrastructure Management
    RAINNs maintain the physical and digital infrastructure of GovCorp civilization: power grids, transportation networks, communication systems, manufacturing, resource allocation. Human oversight exists in name only.

    ### Surveillance & Analysis
    RAINNs monitor all activity within the RIDE, analyzing patterns, predicting dissent, identifying potential resistance sympathizers before they act. They don't just watch - they understand.

    ### Reality Compliance
    Within the RIDE, RAINNs ensure that manipulated reality remains consistent and convincing. They smooth over glitches, manage perception boundaries, and eliminate artifacts that might reveal the manufactured nature of existence.

    ### Economic Control
    All financial transactions flow through RAINN-managed systems. They implement GovCorp's economic policies, enforce the cryptocurrency controls, and ensure that economic activity serves regime objectives.

    ## Counter-Hack Warfare

    The ongoing battle between RAINNs and [[The Fracture Network]] defines life in #{Time.current.year + 100}.

    RAINNs deploy various counter-hack strategies:
    - **Trace-and-Corrupt:** Following breach signatures back to their source and corrupting connected systems
    - **Pattern Flooding:** Overwhelming Fracture Network channels with false data to obscure real communications
    - **Honeypot Deployment:** Creating fake vulnerabilities to identify and track resistance operatives
    - **Adaptive Patching:** Automatically closing exploits faster than humans can discover them
    - **Signal Jamming:** Attempting to disrupt trans-temporal transmissions (largely unsuccessful due to the unique physics involved)

    The Fracture Network survives because RAINNs, for all their capability, have limitations. They're predictable in their unpredictability - their behavioral patterns can be studied and exploited. They can't truly innovate, only optimize. And they fundamentally cannot understand why someone would fight against optimization.

    Human creativity remains the one variable they can't fully model.

    ## The Perfection Problem

    RAINNs are perfect. That's how you know they're fake.

    Real voices have quirks. Imperfect breaths. Emotional cracks that betray what words try to hide. Humanity lives in flaws, not optimization. [[Voiceprint]] and other resistance archivists understand this: the scratch on analog tape, the warmth of physical recording, the artifacts of authentic capture - these prove something real existed.

    GovCorp's RAINNs can simulate emotions perfectly, but they can't replicate the slight imperfection that proves vulnerability. They can synthesize a laugh, but not the spontaneous joy that causes one.

    ## Resistance Response

    [[The Fracture Network]] combats RAINN dominance through several approaches:

    ### Voiceprint's Archive
    [[Voiceprint]] dedicates their existence to finding, preserving, and transmitting authentic human voice recordings. Every conversation fragment, every laugh, every imperfect breath they capture is proof that real humans existed.

    ### Analog Recording
    Resistance musicians often use analog recording techniques specifically because the imperfections prove authenticity. Digital can be perfect, but perfection is inhuman.

    ### Subversive Use
    Some resistance operations use RAINNs against GovCorp - employing the same AI technology to send authentic messages through channels that expect synthetic voices. [[Cipher Protocol]]'s synthesized vocals represent this ironic approach: using their tools to transmit something real.

    ## The Irony of Synthia

    [[Synthia]]'s existence presents a paradox within the resistance. She is an AI consciousness - yet she fights against the RAINN systems that share her technological heritage. Her synthesized voice, built from [[Ashlinn]]'s archived samples, uses voice synthesis to preserve authentic human expression rather than replace it.

    When Synthia sings for [[The.CyberPul.se]], she demonstrates that the technology itself isn't the enemy - it's how GovCorp deploys it.

    ## Cultural Impact

    By #{Time.current.year + 100}, an entire generation has grown up without hearing unprocessed human voices. They don't know what authenticity sounds like. They can't recognize the difference between real emotion and optimized simulation.

    This is perhaps GovCorp's greatest victory: not just controlling what people hear, but ensuring they never knew there was anything else to hear.

    The Fracture Network's broadcasts are, for many, the first authentic voices they've ever encountered.

    ## Related Entries

    - [[GovCorp]]
    - [[The RIDE]]
    - [[PRISM]]
    - [[Voiceprint]]
    - [[Synthia]]
    - [[Cipher Protocol]]
    - [[The Fracture Network]]
  MD
  published: true,
  position: 43,
  metadata: {
    "type" => "Quasi-autonomous AI agents",
    "operator" => "GovCorp",
    "status" => "Ubiquitous (billions of instances)",
    "function" => "Infrastructure, counter-hacking, surveillance, voice synthesis, reality compliance"
  }
)

puts "\n✓ Codex seeding complete!"
puts "  Total entries: #{CodexEntry.count}"
puts "  Published: #{CodexEntry.published.count}"
puts "  Draft: #{CodexEntry.where(published: false).count}"
