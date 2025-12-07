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

    In 2119, XERAEN came to understand the true scope of what he had helped create. The RIDE wasn't just reality manipulation for commerce or governance - it was total control. Every perception filtered. Every experience curated. Humanity reduced to managed variables in GovCorp's optimization algorithms.

    He couldn't unknow what he knew. He couldn't continue building their prison.

    ## The Chronology Fracture

    XERAEN's attack on RIDE infrastructure was meant to be sabotage - a desperate act of defiance. Instead, it became something unprecedented: the discovery of trans-temporal data transmission.

    During the chaos he created, XERAEN detected signals reflecting backward through time with precise mathematical regularity. He had accidentally discovered that data could be sent exactly 100 years into the past.

    This discovery became the foundation of everything that followed.

    ## The Broadcasts

    Now XERAEN operates from [[The Pulse Grid]], transmitting signals from #{Time.current.year + 100} to #{Time.current.year}. Every broadcast is a warning. Every transmission is resistance. Every signal carries the weight of a future he's trying to prevent.

    ## The Erasure Paradox

    If the Fracture Network succeeds - if GovCorp never rises, if the RIDE never comes online - then XERAEN's timeline collapses. He ceases to exist. The broadcasts stop because there's nothing left to broadcast from.

    He fights knowing victory means erasure. He transmits knowing success means silence.

    ## Ashlinn

    Across the hundred-year divide, XERAEN has formed a connection with [[Ashlinn]] - a musician existing in #{Time.current.year}. How this bond formed, how signals across time became something like love, remains unexplained.

    Perhaps some connections transcend causality itself.

    ## Music

    XERAEN produces experimental electronic music that circulates through The Pulse Grid, often containing encoded messages for Fracture Network operatives. His solo transmissions are darker, more ambient - the sound of someone sending signals they may never know were received.

    ## Related Entries

    - [[The Fracture Network]]
    - [[The Pulse Grid]]
    - [[Chronology Fracture]]
    - [[The RIDE]]
    - [[GovCorp]]
    - [[Ashlinn]]
  MD
  published: true,
  position: 1,
  metadata: {
    "timeline" => "#{Time.current.year + 100}",
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

    Ashlinn creates moving soundscapes and compositions, treating music as a form of communication that transcends ordinary logic. her work explores themes of identity, Truth, and their intersection.

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
    "timeline" => "#{Time.current.year}",
    "faction" => "Unknown",
    "status" => "Active"
  }
)

# ORGANIZATIONS
seed_codex_entry(
  name: "The Fracture Network",
  slug: "the-fracture-network",
  entry_type: "organization",
  summary: "The trans-temporal resistance - hackrs, artists, and free thinkers fighting GovCorp across a hundred years through music, technology, and the power of unfiltered reality.",
  content: <<~MD,
    # The Fracture Network

    **Founded:** 2119<br>
    **Founder:** [[XERAEN]]<br>
    **Status:** Active across two timelines<br>
    **Primary Asset:** [[The Pulse Grid]]

    ## Overview

    The Fracture Network is more than resistance - it's a temporal phenomenon. Operating through [[The Pulse Grid]], the Network fights [[GovCorp]] not just in #{Time.current.year + 100}, but across time itself, sending signals 100 years into the past to prevent the dystopia from ever solidifying.

    ## Formation

    The Fracture Network formed in the aftermath of the [[Chronology Fracture]] - [[XERAEN]]'s accidental discovery of trans-temporal data transmission. What began as a desperate attack on [[The RIDE]] became the foundation for something unprecedented: resistance that transcends linear time.

    ## The Trans-Temporal Mission

    The Network's primary mission is paradoxical: to prevent the future they exist in. Every broadcast sent from #{Time.current.year + 100} to #{Time.current.year} carries warnings, coordinates, and the vibrational power of music designed to awaken listeners before GovCorp's control becomes absolute.

    If they succeed, their timeline collapses. They fight knowing victory means their own erasure.

    ## Operations

    - **RIDE Breach:** Penetrating GovCorp's reality manipulation infrastructure
    - **Trans-Temporal Transmission:** Broadcasting resistance signals 100 years into the past
    - **Reality Liberation:** Creating pockets of unfiltered existence within RIDE-controlled space
    - **Music as Weapon:** Using vibrational frequencies to attack RIDE systems and awaken consciousness

    ## Structure

    The Network operates in cells with minimal knowledge of the broader organization - security against infiltration. [[The Pulse Grid]] serves as infrastructure, with the hackr.tv Broadcast Station at its heart.

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
    - [[The Pulse Grid]]
    - [[Chronology Fracture]]
    - [[The RIDE]]
    - [[GovCorp]]
  MD
  published: true,
  position: 10,
  metadata: {
    "founded" => "2119",
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

    [[The Fracture Network]] represents the primary organized opposition to GovCorp rule, operating through [[The Pulse Grid]] to breach the RIDE and transmit resistance across time itself.

    ## Related Entries

    - [[The Fracture Network]]
    - [[PRISM]]
    - [[The RIDE]]
    - [[The Pulse Grid]]
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

    **Date:** September 9, 2119<br>
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

    [[The Fracture Network]] formed around this capability. [[The Pulse Grid]] was developed to exploit it. The broadcasts began.

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
    - [[The Pulse Grid]]
    - [[The RIDE]]
    - [[GovCorp]]
  MD
  published: true,
  position: 20,
  metadata: {
    "date" => "2119-09-09",
    "type" => "Accidental discovery",
    "significance" => "Trans-temporal transmission capability",
    "temporal_range" => "Exactly 100 years"
  }
)

# LOCATIONS
seed_codex_entry(
  name: "The Pulse Grid",
  slug: "the-pulse-grid",
  entry_type: "location",
  summary: "The Fracture Network's primary infrastructure for breaching the RIDE and transmitting signals across time - a digital battleground where resistance operates.",
  content: <<~MD,
    # The Pulse Grid

    **Type:** Resistance infrastructure<br>
    **Status:** Active<br>
    **Control:** [[The Fracture Network]]<br>
    **Purpose:** RIDE breach operations, trans-temporal transmission

    ## Overview

    The Pulse Grid is [[The Fracture Network]]'s primary operational infrastructure - a sophisticated digital network designed to breach [[The RIDE]] and serve as the origin point for trans-temporal transmissions. Where GovCorp controls reality through the RIDE, the Fracture Network fights back through the Grid.

    ## Primary Functions

    ### RIDE Breach Operations
    The Pulse Grid provides entry points into RIDE infrastructure, allowing Fracture Network operatives to disrupt reality manipulation, create pockets of unfiltered existence, and gather intelligence on GovCorp operations.

    ### Trans-Temporal Transmission
    Following the [[Chronology Fracture]], the Grid was developed to exploit XERAEN's discovery. It serves as the origin point for signals sent exactly 100 years into the past - the broadcasts that reach #{Time.current.year} from #{Time.current.year + 100}.

    ### Secure Communication
    The Grid provides encrypted channels for Fracture Network coordination, operating in frequencies and protocols that RIDE monitoring cannot detect.

    ## Architecture

    The Pulse Grid exists as an overlay on existing digital infrastructure, using techniques developed after the Chronology Fracture to remain invisible to GovCorp surveillance:

    - **Breach Nodes:** Entry points into RIDE systems
    - **Transmission Hubs:** Origin points for temporal broadcasts
    - **Dark Zones:** Secure areas for operative coordination
    - **Buffer Zones:** Camouflaged edges that blend with normal traffic

    ## The Grid as Place

    Hackrs experience The Pulse Grid as a physical space - rooms, corridors, zones. Whether this is deliberate design or emergent property of neural interface technology remains debated. Regardless, operatives navigate the Grid as explorers of a vast digital landscape.

    ## Access

    Accessing The Pulse Grid requires specialized hardware rigs or modified neural interfaces. Standard GovCorp-issued implants cannot perceive Grid infrastructure - a feature, not a limitation.

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
    "established" => "2119",
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
    - [[The Pulse Grid]] as a breach point into RIDE infrastructure
    - Music as vibrational attack vectors against PRISM frequencies

    ## Related Entries

    - [[GovCorp]]
    - [[The RIDE]]
    - [[The Fracture Network]]
    - [[The Pulse Grid]]
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

    GovCorp does not publicly acknowledge the RIDE. Those who speak of it are classified as suffering from "reality dysfunction disorder" and treated accordingly.

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

    [[The Fracture Network]] represents the only organized resistance capable of operating outside RIDE influence. Through [[The Pulse Grid]], they breach RIDE infrastructure, create pockets of unmanipulated reality, and transmit signals that pierce through the manufactured world.

    The [[Chronology Fracture]] - [[XERAEN]]'s discovery of trans-temporal data transmission - allows the Fracture Network to send information backward through time, completely bypassing the RIDE's reality filters.

    ## The Paradox of Awareness

    Those who become aware of the RIDE face a terrible choice: continue living in manipulated reality with the comfort of ignorance, or join the resistance and see the world as it truly is - a manufactured construct designed for control.

    Most choose ignorance. A few choose to fight.

    ## Related Entries

    - [[PRISM]]
    - [[GovCorp]]
    - [[The Fracture Network]]
    - [[The Pulse Grid]]
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

puts "\n✓ Codex seeding complete!"
puts "  Total entries: #{CodexEntry.count}"
puts "  Published: #{CodexEntry.published.count}"
puts "  Draft: #{CodexEntry.where(published: false).count}"
