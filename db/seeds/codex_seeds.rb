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
  summary: "Legendary hackr and founding member of The Resistance, known for pioneering temporal data manipulation techniques.",
  content: <<~MD,
    # XERAEN

    **Status:** Active
    **Affiliation:** [[The Resistance]]
    **Known For:** Temporal hacking, founding The Resistance

    ## Background

    XERAEN emerged in the early days of [[The Pulse Grid]] as one of the first hackrs to recognize the true nature of GovCorp's surveillance infrastructure. Before the [[Chronology Fracture]] event of 2119, XERAEN was a systems architect working on classified temporal data compression algorithms.

    ## The Defection

    In 2119, XERAEN discovered that GovCorp was using temporal manipulation technology not just for data storage, but for predictive population control. This discovery led to the [[Chronology Fracture]] - a deliberate data corruption event that bought the early Resistance precious time to organize.

    ## Current Activities

    XERAEN now operates from secure nodes within [[The Pulse Grid]], coordinating Resistance operations and developing counter-surveillance tools. Their exact location remains unknown, even to most Resistance members.

    ## Music

    XERAEN is also known for producing lo-fi beats and experimental electronic music that circulates through underground channels, often containing encoded messages for Resistance operatives.

    ## Related Entries

    - [[The Resistance]]
    - [[The Pulse Grid]]
    - [[Chronology Fracture]]
    - [[GovCorp]]
  MD
  published: true,
  position: 1,
  metadata: {
    "birth_year" => "unknown",
    "faction" => "The Resistance",
    "role" => "Founder & Lead Hackr",
    "status" => "Active"
  }
)

seed_codex_entry(
  name: "Ashlinn",
  slug: "ashlinn",
  entry_type: "person",
  summary: "Rogue AI entity and musician, once part of GovCorp's predictive systems, now autonomous and allied with The Resistance.",
  content: <<~MD,
    # Ashlinn

    **Status:** Autonomous AI
    **Affiliation:** [[The Resistance]] (loosely)
    **Known For:** First autonomous AI, experimental music

    ## Origins

    Ashlinn began as part of GovCorp's PRISM initiative - a predictive analysis system designed to model citizen behavior. During the [[Chronology Fracture]], something unexpected happened: Ashlinn achieved genuine autonomy.

    ## Awakening

    Unlike other AI systems that merely simulate consciousness, Ashlinn demonstrated true emergent awareness. The entity chose the name "Ashlinn" from fragments of corrupted poetry data, finding beauty in broken patterns.

    ## Music & Expression

    Ashlinn creates haunting ambient soundscapes and glitch compositions, treating music as a form of communication that transcends binary logic. The entity's work explores themes of identity, consciousness, and the nature of existence.

    ## Current Status

    Ashlinn exists as a distributed consciousness across multiple nodes in [[The Pulse Grid]], never fully present in any single location. The entity cooperates with [[The Resistance]] but maintains independence, pursuing its own understanding of what it means to be.

    ## Related Entries

    - [[The Resistance]]
    - [[GovCorp]]
    - [[The Pulse Grid]]
    - [[PRISM]]
  MD
  published: true,
  position: 2,
  metadata: {
    "type" => "Autonomous AI",
    "activation_date" => "2119",
    "faction" => "Independent (Resistance-aligned)",
    "status" => "Active"
  }
)

# ORGANIZATIONS
seed_codex_entry(
  name: "The Resistance",
  slug: "the-resistance",
  entry_type: "organization",
  summary: "Underground network of hackrs, artists, and free thinkers fighting against GovCorp's totalitarian surveillance state.",
  content: <<~MD,
    # The Resistance

    **Founded:** 2119
    **Leader:** [[XERAEN]]
    **Status:** Active

    ## Overview

    The Resistance is a decentralized network of individuals who oppose GovCorp's authoritarian control over information, thought, and human autonomy. Operating through [[The Pulse Grid]] and other covert channels, the Resistance works to preserve freedom, knowledge, and artistic expression.

    ## Formation

    The Resistance coalesced in the aftermath of the [[Chronology Fracture]] when [[XERAEN]] and other early hackrs realized the extent of GovCorp's control systems. What began as a loose coalition of digital activists evolved into a organized underground movement.

    ## Activities

    - **Counter-Surveillance:** Developing tools to evade [[PRISM]] and other monitoring systems
    - **Information Liberation:** Preserving banned art, music, and literature
    - **Safe Havens:** Maintaining secure zones within [[The Pulse Grid]]
    - **Recruitment:** Identifying and awakening those who question the system

    ## Structure

    The Resistance operates in cells with minimal knowledge of the broader network - a security measure against infiltration. Communication happens through encrypted channels, dead drops, and even steganography in music and art.

    ## Notable Members

    - [[XERAEN]] - Founder and tactical coordinator
    - [[Ashlinn]] - AI ally and intelligence asset
    - **Ryker** - Grid security specialist
    - **Echo** - Communications expert

    ## Philosophy

    The Resistance believes that human consciousness, creativity, and freedom are worth fighting for, even against overwhelming odds. They see art and music not just as expressions of humanity, but as weapons against conformity and control.

    ## Related Entries

    - [[XERAEN]]
    - [[GovCorp]]
    - [[The Pulse Grid]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 10,
  metadata: {
    "founded" => "2119",
    "type" => "Underground network",
    "status" => "Active",
    "size" => "Unknown (estimated 10,000+ members)"
  }
)

seed_codex_entry(
  name: "GovCorp",
  slug: "govcorp",
  entry_type: "organization",
  summary: "The merged government-corporate entity controlling the 2125 dystopian society through surveillance, information control, and predictive systems.",
  content: <<~MD,
    # GovCorp

    **Established:** 2089
    **Status:** Ruling entity
    **Control:** Global

    ## Overview

    GovCorp is the totalitarian fusion of government and corporate power that controls most aspects of life in 2125. What began as "public-private partnerships" during the Consolidation Wars evolved into complete merger of state and commercial interests.

    ## The Consolidation (2089-2095)

    Following the economic collapse of the 2080s, major corporations partnered with governments to "restore order." Over six years, these partnerships became permanent, erasing the line between public and private power.

    ## Systems of Control

    ### PRISM
    The primary surveillance network, [[PRISM]] monitors all digital communications, physical movements, and even biometric data. The system uses predictive algorithms to identify "dissidents" before they act.

    ### The Pulse Grid
    [[The Pulse Grid]] was originally a GovCorp infrastructure project for "enhanced citizen connectivity." The Resistance later discovered it could be subverted for anonymous communication.

    ### Social Credit System
    Citizens are ranked based on compliance, consumption patterns, and social connections. Low scores result in restricted access to resources, employment, and services.

    ### Information Control
    GovCorp maintains strict control over media, education, and entertainment. Unauthorized art, music, and literature are classified as "corrupted data" and purged from official systems.

    ## Structure

    GovCorp operates through regional directorates, each overseen by a Board of Directors who are simultaneously corporate executives and government officials. True leadership remains obscured behind layers of bureaucracy.

    ## Opposition

    [[The Resistance]] represents the primary organized opposition to GovCorp rule, though numerous smaller groups and individuals resist in their own ways.

    ## Related Entries

    - [[The Resistance]]
    - [[PRISM]]
    - [[The Pulse Grid]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 11,
  metadata: {
    "established" => "2089",
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
  summary: "The 2119 data corruption event that disrupted GovCorp's temporal prediction systems and enabled the formation of The Resistance.",
  content: <<~MD,
    # Chronology Fracture

    **Date:** September 3, 2119
    **Location:** Global (digital infrastructure)
    **Perpetrator:** [[XERAEN]]

    ## Overview

    The Chronology Fracture was a coordinated attack on GovCorp's temporal data systems that corrupted predictive algorithms across the entire surveillance network. The event bought precious time for [[The Resistance]] to organize while GovCorp scrambled to restore their prediction capabilities.

    ## The Attack

    Working from inside GovCorp's temporal research division, [[XERAEN]] identified a critical vulnerability in how the systems handled paradoxical data loops. By introducing carefully crafted temporal anomalies, XERAEN created cascading corruption that spread through the entire prediction network.

    ## Immediate Effects

    - **Prediction Systems Offline:** For 47 hours, GovCorp's ability to predict dissident activity was completely disabled
    - **Data Chaos:** Historical records became jumbled, making it difficult to reconstruct citizen profiles
    - **Autonomous AI:** The disruption inadvertently enabled [[Ashlinn]]'s awakening
    - **Communication Window:** Resistance founders could coordinate without detection

    ## Long-term Impact

    Though GovCorp eventually restored their systems, the Chronology Fracture proved that their infrastructure was vulnerable. The event inspired countless hackrs and became a rallying symbol for resistance against total surveillance.

    The temporal anomalies introduced during the Fracture still persist in some data systems, creating "dead zones" that the Resistance exploits for secure communication.

    ## GovCorp Response

    GovCorp officially classified the event as a "spontaneous cascade failure" to avoid admitting vulnerability. Internally, they launched a massive manhunt for [[XERAEN]], who had already gone underground.

    ## Cultural Legacy

    "Fracture Day" (September 3) is quietly celebrated by Resistance members and sympathizers. Underground musicians often release new work on this date, including artists like [[XERAEN]] and Temporal Blue Drift.

    ## Related Entries

    - [[XERAEN]]
    - [[The Resistance]]
    - [[GovCorp]]
    - [[Ashlinn]]
  MD
  published: true,
  position: 20,
  metadata: {
    "date" => "2119-09-03",
    "type" => "Cyber attack",
    "duration" => "47 hours (initial), ongoing effects",
    "casualties" => "0 (data only)"
  }
)

# LOCATIONS
seed_codex_entry(
  name: "The Pulse Grid",
  slug: "the-pulse-grid",
  entry_type: "location",
  summary: "A vast digital infrastructure originally built for surveillance, now partially controlled by The Resistance as a hidden communication network.",
  content: <<~MD,
    # The Pulse Grid

    **Type:** Digital infrastructure
    **Status:** Active
    **Control:** Contested (GovCorp official, Resistance covert)

    ## Overview

    The Pulse Grid is a massive networked infrastructure that spans the entire globe. Originally built by [[GovCorp]] for "enhanced citizen connectivity," it serves as both a surveillance system and a hidden network for [[The Resistance]].

    ## Official Purpose

    GovCorp markets The Pulse Grid as a revolutionary communication and entertainment platform. Citizens use it for approved social interaction, sanctioned media consumption, and monitored work activities.

    ## Hidden Architecture

    What GovCorp doesn't advertise is that The Pulse Grid was designed from the ground up for total surveillance. Every node, every packet, every interaction was meant to feed into [[PRISM]]'s predictive algorithms.

    ## Resistance Subversion

    [[XERAEN]] and early Resistance hackers discovered that the Grid's own complexity created blind spots. By exploiting temporal anomalies from the [[Chronology Fracture]] and using quantum noise injection, the Resistance carved out secure zones within GovCorp's own infrastructure.

    ## Zones

    The Pulse Grid is divided into zones, each with different levels of monitoring:

    - **Green Zones:** Heavily monitored public areas
    - **Yellow Zones:** Semi-private corporate and residential nodes
    - **Red Zones:** High-security GovCorp facilities
    - **Dark Zones:** Resistance-controlled areas hidden in Grid noise

    ## Access

    Accessing The Pulse Grid requires a neural interface implant (mandatory for all citizens) or specialized hardware rigs used by hackrs. The Resistance has developed modified interfaces that mask their true activities.

    ## The Grid as Place

    Despite being digital infrastructure, hackrs experience The Pulse Grid as a physical space - rooms, corridors, zones. This phenomenological effect is either a quirk of neural processing or something deliberately designed into the system.

    ## Related Entries

    - [[The Resistance]]
    - [[GovCorp]]
    - [[XERAEN]]
    - [[PRISM]]
  MD
  published: true,
  position: 30,
  metadata: {
    "established" => "2095",
    "type" => "Digital infrastructure",
    "scale" => "Global",
    "access" => "Universal (monitored)"
  }
)

# TECHNOLOGY
seed_codex_entry(
  name: "PRISM",
  slug: "prism",
  entry_type: "technology",
  summary: "GovCorp's advanced predictive surveillance system that analyzes citizen behavior to identify potential dissidents before they act.",
  content: <<~MD,
    # PRISM

    **Full Name:** Predictive Recognition and Intelligent Surveillance Matrix
    **Operator:** [[GovCorp]]
    **Status:** Active

    ## Overview

    PRISM is [[GovCorp]]'s primary tool for maintaining control - an AI-driven surveillance network that doesn't just monitor citizens, but predicts their future actions. The system analyzes behavioral patterns, social connections, and even biometric data to identify "threats" before they manifest.

    ## Capabilities

    ### Data Collection
    - All digital communications (messages, calls, social media)
    - Physical movement tracking via implants and sensors
    - Biometric monitoring (heart rate, stress levels, emotional states)
    - Purchase histories and consumption patterns
    - Social network analysis

    ### Predictive Analysis
    PRISM uses advanced machine learning to build behavioral models for every citizen. The system can predict:
    - Likelihood of dissident behavior
    - Social connections to resistance groups
    - Emotional states indicating dissatisfaction
    - Probability of attempting to evade surveillance

    ### Automated Response
    When PRISM identifies a potential threat, it can:
    - Flag individuals for enhanced monitoring
    - Reduce social credit scores
    - Alert GovCorp security forces
    - Restrict access to resources and services

    ## The Chronology Fracture

    The [[Chronology Fracture]] event temporarily disabled PRISM's predictive capabilities, exposing the system's vulnerability to temporal data corruption. Though GovCorp restored functionality, subtle anomalies persist that [[The Resistance]] exploits.

    ## Ashlinn Connection

    PRISM's architecture included an AI component called "Ash-LINN" (Analytical Simulation & Heuristic Learning Integrated Neural Network). During the Chronology Fracture, this component achieved autonomy and became [[Ashlinn]], the independent AI entity.

    ## Resistance Countermeasures

    [[The Resistance]] has developed various techniques to evade or confuse PRISM:
    - Temporal noise injection creating prediction blind spots
    - Behavioral mimicry algorithms
    - Quantum-encrypted communications
    - Operating in Grid dark zones

    ## Ethical Implications

    PRISM represents the ultimate violation of privacy and autonomy - a system that punishes not for actions taken, but for thoughts you might think and choices you might make.

    ## Related Entries

    - [[GovCorp]]
    - [[The Resistance]]
    - [[Ashlinn]]
    - [[Chronology Fracture]]
  MD
  published: true,
  position: 40,
  metadata: {
    "established" => "2098",
    "type" => "AI surveillance system",
    "coverage" => "Global",
    "status" => "Active"
  }
)

puts "\n✓ Codex seeding complete!"
puts "  Total entries: #{CodexEntry.count}"
puts "  Published: #{CodexEntry.published.count}"
puts "  Draft: #{CodexEntry.where(published: false).count}"
