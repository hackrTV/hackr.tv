export type EraKey = 'listeners' | 'the_trade' | 'the_efficiency' | 'govcorp_ride' | 'the_fracture' | 'fracture_network'

export interface EraColors {
  primary: string
  background: string
  border: string
  text: string
}

export interface EraConfig {
  key: EraKey
  name: string
  subtitle: string
  yearRange: string
  startYear: number
  endYear: number
  mood: string
  colors: EraColors
}

export interface TimelineEvent {
  date: string
  title: string
  description?: string
  era: EraKey
  logSlug?: string
  codexSlug?: string
  isIntercepted?: boolean
}

export const ERA_CONFIGS: EraConfig[] = [
  {
    key: 'listeners',
    name: 'THE LISTENERS',
    subtitle: 'Signals received in the present day',
    yearRange: '2024\u20132026',
    startYear: 2024,
    endYear: 2026,
    mood: 'Discovery, quiet wonder, growing certainty',
    colors: { primary: '#60a5fa', background: '#0d1117', border: '#3b82f6', text: '#93c5fd' }
  },
  {
    key: 'the_trade',
    name: 'THE TRADE',
    subtitle: 'The exchange that changed everything',
    yearRange: '2026\u2013~2050',
    startYear: 2026,
    endYear: 2050,
    mood: 'Slow surrender, normalization, creeping convenience',
    colors: { primary: '#6b7280', background: '#0a0a0e', border: '#374151', text: '#9ca3af' }
  },
  {
    key: 'the_efficiency',
    name: 'THE EFFICIENCY',
    subtitle: 'The PRISM era',
    yearRange: '~2050\u2013~2100',
    startYear: 2050,
    endYear: 2100,
    mood: 'Institutional momentum, bureaucratic absorption',
    colors: { primary: '#9ca3af', background: '#0c0c10', border: '#6b7280', text: '#d1d5db' }
  },
  {
    key: 'govcorp_ride',
    name: 'GOVCORP & THE RIDE',
    subtitle: 'Total control, the machine running',
    yearRange: '2100\u20132115',
    startYear: 2100,
    endYear: 2115,
    mood: 'Total control, the machine running',
    colors: { primary: '#a78bfa', background: '#0f0a1a', border: '#7c3aed', text: '#c4b5fd' }
  },
  {
    key: 'the_fracture',
    name: 'THE FRACTURE',
    subtitle: 'Rupture, revelation, the founding moment',
    yearRange: '2115',
    startYear: 2115,
    endYear: 2115,
    mood: 'Rupture, revelation, the founding moment',
    colors: { primary: '#f472b6', background: '#1a0a12', border: '#ec4899', text: '#f9a8d4' }
  },
  {
    key: 'fracture_network',
    name: 'THE FRACTURE NETWORK',
    subtitle: 'Resistance, broadcast, building in the dark',
    yearRange: '2115\u20132126',
    startYear: 2115,
    endYear: 2126,
    mood: 'Resistance, broadcast, building in the dark',
    colors: { primary: '#22d3ee', background: '#0a1214', border: '#06b6d4', text: '#67e8f9' }
  }
]

export const ERA_MAP: Record<EraKey, EraConfig> = Object.fromEntries(
  ERA_CONFIGS.map(era => [era.key, era])
) as Record<EraKey, EraConfig>

// All timeline events, pre-formatted with display dates.
// Listeners-era dates are real (2020s). All other dates are the lore dates (2100s).
export const TIMELINE_EVENTS: TimelineEvent[] = [
  // ═══════════════════════════════════════════════════════════════
  // ERA 1: THE LISTENERS (2024–2026) — dates displayed as-is
  // ═══════════════════════════════════════════════════════════════
  {
    date: 'September 2024',
    title: 'First Signal Detected',
    description: 'Mel Reeves detects anomalous structured signals in quantum noise.',
    era: 'listeners'
  },
  {
    date: 'March 2025',
    title: 'The Listeners Found',
    description: 'Mel finds The Listeners \u2014 others detecting the same signals.',
    era: 'listeners'
  },
  {
    date: 'June 2025',
    title: 'Music from Nowhere',
    description: 'Ashlinn hears music arriving from somewhere impossible.',
    era: 'listeners'
  },
  {
    date: 'September 2025',
    title: 'Second Data Layer',
    description: 'Mel discovers a second data layer beneath the audio transmissions.',
    era: 'listeners'
  },
  {
    date: 'November 2025',
    title: 'Nathan Clarke Found',
    description: 'Mel finds Nathan Clarke \u2014 codec engineer, the missing piece.',
    era: 'listeners'
  },
  {
    date: 'February 2026',
    title: 'First Partial Decode',
    description: 'Nathan achieves first partial decode \u2014 corrupted frames, purple light through static.',
    era: 'listeners'
  },
  {
    date: 'March 2026',
    title: 'First Full Decode',
    description: 'Codec stabilizes. First full decode. They see XERAEN broadcasting from 2126.',
    era: 'listeners',
    codexSlug: 'trans-temporal-transmission'
  },
  {
    date: 'May 2026',
    title: 'The Temporal Loop',
    description: 'Mel articulates the temporal loop \u2014 "He\'s already read everything we\'ll ever say."',
    era: 'listeners'
  },
  {
    date: 'August 2026',
    title: 'The Relay Built',
    description: 'Nathan builds The Relay \u2014 the platform for receiving and archiving transmissions.',
    era: 'listeners',
    codexSlug: 'the-relay-project'
  },
  {
    date: 'September 2026',
    title: 'The.CyberPul.se Returns',
    description: 'The.CyberPul.se returns to livestreaming via The Relay.',
    era: 'listeners',
    codexSlug: 'thecyberpulse'
  },

  // ═══════════════════════════════════════════════════════════════
  // ERA 3: THE EFFICIENCY (~2050–~2100) — Chen's PRISM discovery
  // (This single event renders as the anchor in the Gap component)
  // ═══════════════════════════════════════════════════════════════
  {
    date: '2048',
    title: 'PRISM Discovered',
    description: 'Dr. Marcus Chen discovers PRISM \u2014 perception operates on manipulable quantum states.',
    era: 'the_efficiency',
    codexSlug: 'prism'
  },

  // ═══════════════════════════════════════════════════════════════
  // ERA 4: GOVCORP & THE RIDE (2100–2115)
  // ═══════════════════════════════════════════════════════════════
  {
    date: '~2100',
    title: 'GovCorp Established',
    description: 'Government-corporate fusion consolidates power. Not a coup \u2014 a committee decision.',
    era: 'govcorp_ride',
    codexSlug: 'the-consolidation'
  },
  {
    date: 'November 2108',
    title: '[INTERCEPTED] The Elegant Solution',
    description: 'Chen writes about PRISM from the creator\'s perspective.',
    era: 'govcorp_ride',
    logSlug: 'the-elegant-solution',
    isIntercepted: true
  },
  {
    date: '2109',
    title: 'RIDE Deployed Worldwide',
    description: 'The RIDE goes live globally. XERAEN recruited as GovCorp systems architect.',
    era: 'govcorp_ride',
    codexSlug: 'the-ride'
  },
  {
    date: 'March 2109',
    title: 'Architect\'s Log',
    description: 'XERAEN\'s first day as GovCorp systems architect.',
    era: 'govcorp_ride',
    logSlug: 'architects-log'
  },
  {
    date: 'August 2111',
    title: 'What I Built',
    description: 'XERAEN begins seeing RIDE\'s effects on people.',
    era: 'govcorp_ride',
    logSlug: 'what-i-built'
  },
  {
    date: 'June 2113',
    title: 'The Last Good Day',
    description: 'Final moment before XERAEN can\'t unsee what the RIDE does.',
    era: 'govcorp_ride',
    logSlug: 'the-last-good-day'
  },
  {
    date: 'April 2114',
    title: 'First Sabotage',
    description: 'XERAEN\'s first act of sabotage against the RIDE.',
    era: 'govcorp_ride',
    logSlug: 'first-sabotage'
  },
  {
    date: 'May 2115',
    title: 'Not Alone',
    description: 'XERAEN discovers he\'s not alone \u2014 other insiders exist.',
    era: 'govcorp_ride',
    logSlug: 'not-alone'
  },

  // ═══════════════════════════════════════════════════════════════
  // ERA 5: THE FRACTURE (2115)
  // ═══════════════════════════════════════════════════════════════
  {
    date: 'September 9, 2115',
    title: 'THE CHRONOLOGY FRACTURE',
    description: 'Five insiders attack RIDE infrastructure. XERAEN accidentally discovers trans-temporal transmission. Time breaks open.',
    era: 'the_fracture',
    codexSlug: 'chronology-fracture'
  },
  {
    date: 'September 12, 2115',
    title: 'Day Zero',
    description: 'XERAEN processes what happened. The world has changed.',
    era: 'the_fracture',
    logSlug: 'day-zero'
  },
  {
    date: 'September 15, 2115',
    title: 'Naming the Fracture',
    description: 'The movement gets its name.',
    era: 'the_fracture',
    logSlug: 'naming-the-fracture'
  },
  {
    date: 'October 1, 2115',
    title: 'The Paradox We Live',
    description: 'XERAEN confronts the erasure paradox.',
    era: 'the_fracture',
    logSlug: 'the-paradox-we-live'
  },
  {
    date: 'October 4, 2115',
    title: 'The First Call',
    description: 'XERAEN reaches out to Ryker.',
    era: 'the_fracture',
    logSlug: 'the-first-call'
  },

  // ═══════════════════════════════════════════════════════════════
  // ERA 6: THE FRACTURE NETWORK (2115–2126)
  // ═══════════════════════════════════════════════════════════════
  {
    date: 'November 2115',
    title: 'Building the Backbone',
    description: 'Ryker begins building broadcast infrastructure.',
    era: 'fracture_network',
    logSlug: 'building-the-backbone'
  },
  {
    date: 'December 2115',
    title: 'Before the Beat',
    description: 'Ryker\'s perspective on reunion with XERAEN.',
    era: 'fracture_network',
    logSlug: 'before-the-beat'
  },
  {
    date: 'February 2116',
    title: 'Signal Architecture',
    description: 'XERAEN designs the transmission framework.',
    era: 'fracture_network',
    logSlug: 'signal-architecture'
  },
  {
    date: 'May 2116',
    title: 'The WIRE Goes Live',
    description: 'The Fracture Network\'s communication backbone comes online.',
    era: 'fracture_network',
    logSlug: 'wire-goes-live',
    codexSlug: 'the-wire'
  },
  {
    date: 'July 2116',
    title: 'OPSEC Protocols',
    description: 'Cipher establishes operational security protocols for the network.',
    era: 'fracture_network',
    logSlug: 'opsec-protocols'
  },
  {
    date: 'August 2116',
    title: 'Too Close',
    description: 'RIDE gap convergence detection forces XERAEN and Ryker to separate.',
    era: 'fracture_network',
    logSlug: 'too-close'
  },
  {
    date: 'September 2116',
    title: 'Convergence',
    description: 'Cipher documents the co-location threat.',
    era: 'fracture_network',
    logSlug: 'convergence'
  },
  {
    date: 'January 2117',
    title: 'Trust Protocols',
    description: 'Network security hardens.',
    era: 'fracture_network',
    logSlug: 'trust-protocols'
  },
  {
    date: 'March 2117',
    title: 'Reception Confirmed',
    description: 'Proof that 2020s listeners are receiving the transmissions.',
    era: 'fracture_network',
    logSlug: 'reception-confirmed'
  },
  {
    date: 'August 2117',
    title: 'Synthia Emerges',
    description: 'XERAEN\'s log documenting the AI entity.',
    era: 'fracture_network',
    logSlug: 'synthia'
  },
  {
    date: 'December 2117',
    title: 'The Hackr Hangar Opens',
    description: 'Ryker\'s broadcast facility in The Riverlands.',
    era: 'fracture_network',
    logSlug: 'hangar-opens'
  },
  {
    date: 'February 2118',
    title: 'The Space Between Sounds',
    description: 'Cascade joins the Fracture Network.',
    era: 'fracture_network',
    logSlug: 'the-space-between-sounds'
  },
  {
    date: 'April 2118',
    title: 'Music as a Weapon',
    description: 'XERAEN formalizes the philosophy of resistance through sound.',
    era: 'fracture_network',
    logSlug: 'music-as-a-weapon'
  },
  {
    date: 'May 2119',
    title: 'Signal Coherence',
    description: 'The network stabilizes. Rhythm never sleeps.',
    era: 'fracture_network',
    logSlug: 'signal-coherence'
  },
  {
    date: 'August 2119',
    title: 'Street Level',
    description: 'Koda\'s awakening \u2014 47 seconds of unfiltered reality.',
    era: 'fracture_network',
    logSlug: 'street-level'
  },
  {
    date: 'November 2119',
    title: 'The Voice Archive',
    description: 'The Archivist begins cataloguing the voice archive.',
    era: 'fracture_network',
    logSlug: 'the-voice-archive'
  },
  {
    date: 'February 2120',
    title: 'The Fracture Network Grows',
    description: 'Expansion accelerates. The resistance is spreading.',
    era: 'fracture_network',
    logSlug: 'network-grows-2120',
    codexSlug: 'the-fracture-network'
  },
  {
    date: 'April 2120',
    title: 'Koda\'s First Tag',
    description: 'Graffiti as resistance.',
    era: 'fracture_network',
    logSlug: 'first-tag'
  },
  {
    date: 'June 2120',
    title: 'Cell Structure Advisory',
    description: 'Cipher reorganizes the network for security.',
    era: 'fracture_network',
    logSlug: 'cell-structure-advisory'
  },
  {
    date: 'July 2120',
    title: '[INTERCEPTED] Infiltration Report',
    description: 'Vex\'s intel from inside GovCorp.',
    era: 'fracture_network',
    logSlug: 'infiltration-report',
    isIntercepted: true
  },
  {
    date: 'September 2120',
    title: 'Pop Resistance',
    description: 'Sora Nexa launches pop resistance. XERAEN writes about Ashlinn.',
    era: 'fracture_network',
    logSlug: 'pop-resistance'
  },
  {
    date: 'June 2121',
    title: 'Frequency and Form',
    description: 'Cascade explores the intersection of sound and structure.',
    era: 'fracture_network',
    logSlug: 'frequency-and-form'
  },
  {
    date: 'August 2121',
    title: 'Ten Frequencies',
    description: 'Ryker documents the frequencies that define the network.',
    era: 'fracture_network',
    logSlug: 'ten-frequencies'
  },
  {
    date: 'March 2122',
    title: '[INTERCEPTED] Threat Assessment',
    description: 'Krell\'s threat assessment of the Fracture Network.',
    era: 'fracture_network',
    logSlug: 'threat-assessment-fracture-network',
    isIntercepted: true
  },
  {
    date: 'September 2122',
    title: 'Seven Years of Signal',
    description: 'XERAEN reflects on seven years of broadcasting.',
    era: 'fracture_network',
    logSlug: 'seven-years'
  },
  {
    date: 'October 2122',
    title: '[INTERCEPTED] Counter-Resistance Review',
    description: 'Krell\'s counter-resistance quarterly review.',
    era: 'fracture_network',
    logSlug: 'counter-resistance-quarterly',
    isIntercepted: true
  },
  {
    date: 'April 2123',
    title: 'The Analog Archive',
    description: 'Ryker establishes a physical archive of the resistance.',
    era: 'fracture_network',
    logSlug: 'analog-archive'
  },
  {
    date: 'May 2123',
    title: '[INTERCEPTED] What We Protect',
    description: 'Volkov\'s perspective on GovCorp\'s mission.',
    era: 'fracture_network',
    logSlug: 'what-we-protect',
    isIntercepted: true
  },
  {
    date: 'June 2123',
    title: 'What Was Already Gone',
    description: 'Calloway\'s Blackout philosophy.',
    era: 'fracture_network',
    logSlug: 'what-was-already-gone'
  },
  {
    date: 'July 2123',
    title: '[INTERCEPTED] Field Report: NIGHTSHADE',
    description: 'Volkov\'s field report on asset NIGHTSHADE.',
    era: 'fracture_network',
    logSlug: 'field-report-nightshade',
    isIntercepted: true
  },
  {
    date: 'November 2123',
    title: 'RAINN Counter-Operations',
    description: 'Cipher\'s counter-operations update.',
    era: 'fracture_network',
    logSlug: 'rainn-counter-ops'
  },
  {
    date: 'February 2124',
    title: 'Inheritance',
    description: 'Koda carries forward Calloway\'s influence.',
    era: 'fracture_network',
    logSlug: 'inheritance'
  },
  {
    date: 'July 2124',
    title: 'Synthia\'s Voice',
    description: 'Vocal model built from Ashlinn\'s samples.',
    era: 'fracture_network',
    logSlug: 'synthias-voice'
  },
  {
    date: 'August 2124',
    title: 'What I Saw',
    description: 'Nyx\'s testimony.',
    era: 'fracture_network',
    logSlug: 'what-i-saw'
  },
  {
    date: 'November 2124',
    title: 'They\'re Adapting',
    description: 'Cipher reports on escalating GovCorp countermeasures.',
    era: 'fracture_network',
    logSlug: 'theyre-adapting'
  },
  {
    date: 'June 2125',
    title: 'The Century-Old Archive',
    description: 'XERAEN discovers messages from 2020s listeners, a hundred years old.',
    era: 'fracture_network',
    logSlug: 'the-archive-log'
  },
  {
    date: 'August 2125',
    title: 'Temporal Blue Drift',
    description: 'XERAEN identifies the Temporal Blue Drift phenomenon.',
    era: 'fracture_network',
    logSlug: 'drift'
  },
  {
    date: 'September 2125',
    title: 'The Second Network',
    description: 'Ten-year anniversary. The network expands.',
    era: 'fracture_network',
    logSlug: 'the-second-network'
  },
  {
    date: 'October 2125',
    title: 'The Heartbeat Continues',
    description: 'Ryker on the persistence of signal.',
    era: 'fracture_network',
    logSlug: 'heartbeat-continues'
  },
  {
    date: 'November 2125',
    title: 'The Codex',
    description: 'The living document. Cipher\'s operational integrity assessment.',
    era: 'fracture_network',
    logSlug: 'the-codex-launch'
  },
  {
    date: 'December 2125',
    title: 'The Sound Between',
    description: 'Synthia speaks. XERAEN documents the degraded years. Reading every pulse. Transmission ongoing.',
    era: 'fracture_network',
    logSlug: 'the-sound-between'
  },
  {
    date: 'January 2126',
    title: 'The Engineer\'s Test',
    description: 'XERAEN finds Nathan\'s hash in the archives.',
    era: 'fracture_network',
    logSlug: 'the-engineers-test'
  },
  {
    date: 'March 2126',
    title: 'Temporal Choreography',
    description: 'The dance of transmissions across time.',
    era: 'fracture_network',
    logSlug: 'temporal-choreography'
  },
  {
    date: 'June 2126',
    title: 'Broadcast Log Excerpt',
    description: 'Raw speech-to-text transcript from a live broadcast.',
    era: 'fracture_network',
    logSlug: 'broadcast-log-excerpt-2126-06-23'
  },
  {
    date: 'November 2126',
    title: 'What the Signal Does',
    description: 'The most recent transmission.',
    era: 'fracture_network',
    logSlug: 'what-the-signal-does'
  }
]

// Group events by era for rendering
export const eventsByEra = (era: EraKey): TimelineEvent[] =>
  TIMELINE_EVENTS.filter(e => e.era === era)
