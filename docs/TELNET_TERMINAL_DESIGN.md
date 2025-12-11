# THE.CYBERPUL.SE Terminal Access System

**Status:** Design Phase
**Created:** 2025-12-10
**Last Updated:** 2025-12-10

## Vision

A unified BBS-style terminal interface providing SSH access to the entire hackr.tv universe. Rather than just "SSH to the MUD", this creates a **full terminal portal** into THE.CYBERPUL.SE - an immersive, interconnected experience where all systems feel like one living world.

This approach is thematically perfect for a cyberpunk setting and enables:
- MUD client support for THE PULSE GRID
- Retro-futuristic aesthetic matching the 2125 timeline
- "Hackable" feel with hidden commands and easter eggs
- True terminal culture experience

---

## Connection Details

```bash
ssh access@hackr.tv -p 9915
```

- **Username:** `access` (shared, public)
- **Port:** `9915` (reference to 9/9/2115 - Fracture Day)
- **Password:** Rotating daily, displayed at `hackr.tv/terminal`

### Why SSH Instead of Telnet?

Raw telnet transmits everything in plaintext, including passwords. SSH provides:
- Encrypted transport (credentials protected)
- Wide client support (native terminal, MUD clients like Mudlet)
- No key management required (password auth only)

### Rotating Password System

The SSH password rotates daily and is displayed on the website. This creates an in-world ritual where users must visit `hackr.tv/terminal` to get current access credentials.

**Implementation:**
- Time-based rotation (daily at midnight UTC)
- Deterministic generation (Rails + SSH server compute same password)
- Two-word format: `word1-word2` (e.g., `neon-cipher`, `ghost-signal`)
- Thematic word list drawn from cyberpunk vocabulary
- Countdown timer shows time until next rotation

**Web Display Page (`/terminal`):**
```
═══════════════════════════════════════════
  TERMINAL ACCESS CREDENTIALS
═══════════════════════════════════════════

  Connection:  ssh access@hackr.tv -p 9915
  Password:    neon-cipher

  Credential rotation: 23:47:12

  ─────────────────────────────────────────
  "GovCorp rotates access tokens daily.
   The Fracture Network adapts."
  ─────────────────────────────────────────
```

**Password Generation (shared between Rails and SSH server):**
```ruby
def current_terminal_password
  seed = Date.current.to_s + "fracture-day-9915"
  words = %w[
    neon chrome pulse grid hack wire signal ghost cipher void
    fracture prism neural static glitch sync node echo flux core
  ]
  rng = Random.new(seed.hash)
  "#{words[rng.rand(words.length)]}-#{words[rng.rand(words.length)]}"
end
```

---

## System Overview

### Main Terminal Menu (Concept)

```
┌─────────────────────────────────────────┐
│  THE.CYBERPUL.SE // TERMINAL ACCESS     │
│  ═══════════════════════════════════════│
│                                         │
│  [1] THE PULSE GRID    - Enter the MUD  │
│  [2] THE WIRE          - PulseWire feed │
│  [3] THE CODEX         - Lore archive   │
│  [4] HACKR.FM          - Band profiles  │
│  [5] PULSE VAULT       - Track listings │
│  [6] WHO'S ONLINE      - Connected hackrs│
│  [0] DISCONNECT                         │
│                                         │
│  > _                                    │
└─────────────────────────────────────────┘
```

---

## Feature Specifications

### 1. THE PULSE GRID (MUD)

**Status:** Core functionality already built via `Grid::CommandParser`

**Telnet Implementation:**
- Natural fit - MUDs were born for telnet
- Reuse existing command parser
- Add ANSI color output format (currently outputs HTML)

**Existing Commands:**
- `look/l` - View current room
- `go [direction]` / `north/south/east/west/up/down` - Movement
- `inventory/inv/i` - View inventory
- `take/drop/examine [item]` - Item interaction
- `talk [npc]` - Start NPC dialogue
- `ask [npc] about [topic]` - NPC topic queries
- `say [message]` - Public chat
- `who` - List online players
- `help` - Command reference
- `clear/cls` - Clear screen

**Telnet-Specific Additions:**
- `/wire` - Quick access to PulseWire from within Grid
- `/codex [entry]` - Look up lore mid-game
- `/pulse "message"` - Post to Wire without leaving Grid

### 2. THE WIRE (PulseWire)

**Purpose:** Read and interact with the micro-broadcast social network

**Terminal Interface Concept:**

```
═══ THE WIRE ═══════════════════════════════
@XERAEN [2h ago]                        #42
The Grid remembers. The Grid waits.
↺ 12 echoes │ ⤷ 3 splices

@Ashlinn [4h ago]                       #41
Signal's been weird in Sector 7. Anyone else?
↺ 4 echoes │ ⤷ 8 splices

────────────────────────────────────────────
[N]ext page │ [P]ost │ [V]iew #ID │ [B]ack
> _
```

**Commands:**
- `wire` or `hotwire` - View main timeline (paginated)
- `wire @username` - View user's pulse history
- `pulse "message"` or `post "message"` - Broadcast new pulse
- `view 42` or `thread 42` - View pulse #42 with full thread
- `splice 42 "message"` - Reply to pulse #42
- `echo 42` - Echo/rebroadcast pulse #42
- `unecho 42` - Remove echo
- `echoes 42` - See who echoed pulse #42

**Real-Time Considerations:**
- Live updates while viewing? (ticker at bottom?)
- Notification of new pulses from followed users?
- "New activity" indicator?

### 3. THE CODEX (Lore Archive)

**Purpose:** Browse and search the wiki/lore system

**Terminal Interface Concept:**

```
═══ THE CODEX ═══════════════════════════════
>> The Fracture Network

TYPE: Organization
───────────────────────────────────────────
A decentralized collective of hackrs who
believe the Chronology Fracture was not an
accident but a deliberate act of temporal
sabotage by GovCorp...

SEE ALSO: [1] XERAEN  [2] Chronology Fracture
          [3] GovCorp

────────────────────────────────────────────
[1-3] Follow link │ [B]ack │ [S]earch
> _
```

**Commands:**
- `codex` - Main codex menu / recent entries
- `codex [entry name]` - View specific entry
- `codex search [term]` - Search entries
- `codex people` - List all person entries
- `codex factions` - List all faction entries
- `codex locations` - List all location entries
- `codex events` - List all event entries
- `codex technology` - List all technology entries
- `codex organizations` - List all organization entries
- `codex items` - List all item entries

**Markdown to ANSI Rendering:**
- `**bold**` → `\e[1mbold\e[0m`
- `*italic*` → `\e[3mitalic\e[0m`
- `## Header` → `═══ HEADER ═══`
- `[[Entry Name]]` → Numbered reference `[1] Entry Name`
- `- list item` → `• list item`
- Code blocks → Highlighted with background color

### 4. HACKR.FM (Band Profiles)

**Purpose:** Explore artist information, albums, and track details

**Terminal Interface Concept:**

```
═══ HACKR.FM ═══════════════════════════════
BANDS ON THE NETWORK:

  1. XERAEN              [Industrial/Cyber]
     4 albums │ 24 tracks

  2. The.CyberPul.se     [Synthwave]
     2 albums │ 12 tracks

  3. System Rot          [Glitch/Noise]
     1 album  │ 8 tracks

  ... (10 more)

────────────────────────────────────────────
[#] View band │ [S]earch │ [B]ack
> _
```

**Commands:**
- `bands` - List all artists
- `band [name]` - View artist profile (bio, genre, albums)
- `albums` - List all albums
- `album [name]` - View album details (tracks, release date, description)
- `lyrics [track name]` - View track lyrics (where available)

**Note:** No audio playback via telnet, but can display:
- Streaming links (Spotify, Bandcamp, etc.)
- "Now playing on hackr.fm" indicator
- Instructions to visit web player

### 5. PULSE VAULT (Track Listings)

**Purpose:** Browse the complete track database

**Terminal Interface Concept:**

```
═══ PULSE VAULT ═══════════════════════════
 #  TRACK                  ARTIST          ALBUM
────────────────────────────────────────────
 1  Hackrs of Cyberspace   XERAEN          Xordium
 2  Kernel Panic           The.CyberPul.se Digital Dreams
 3  System Failure         System Rot      Corruption
 4  Neon Nights            Voiceprint      Frequencies
 ...

PAGE 1/7 │ 66 tracks total
────────────────────────────────────────────
[N]ext │ [P]rev │ [V]iew # │ [S]earch │ [B]ack
> _
```

**Commands:**
- `tracks` or `vault` - Browse all tracks (paginated)
- `tracks by [artist]` - Filter by artist
- `tracks on [album]` - Filter by album
- `tracks search [term]` - Search tracks
- `track [number or name]` - View track details

### 6. WHO'S ONLINE

**Purpose:** See connected users across all systems

**Terminal Interface Concept:**

```
═══ WHO'S ONLINE ═══════════════════════════
CONNECTED HACKRS: 7

  @XERAEN        [THE PULSE GRID] Neon District
  @Ashlinn       [THE WIRE] reading hotwire
  @Ryker         [THE CODEX] viewing: GovCorp
  @ghost_signal  [IDLE] 5m
  @neural_decay  [THE PULSE GRID] Fracture HQ
  @prism_eye     [BANDS] viewing: System Rot
  @you           [WHO'S ONLINE]

────────────────────────────────────────────
[M]essage user │ [B]ack
> _
```

**Features:**
- Show current location/activity
- Idle time tracking
- Direct messaging? (future feature)

---

## Design Decisions Required

### 1. Authentication Model

**Question:** How do users authenticate?

**Options:**
| Option | Pros | Cons |
|--------|------|------|
| A. Use existing GridHackr accounts | Unified identity, existing users | Requires account to do anything |
| B. Anonymous browsing + auth for interaction | Lower barrier to explore | Two-tier experience complexity |
| C. Guest accounts with limited features | Easy onboarding | May not convert to real accounts |

**Recommendation:** Option B - Allow anonymous browsing of Codex, bands, tracks, and read-only Wire access. Require GridHackr login for: posting to Wire, entering the Grid, creating playlists.

**Decision:** TBD

---

### 2. Session State & Navigation

**Question:** How does navigation work?

**Options:**
| Option | Description | Feel |
|--------|-------------|------|
| A. Stack-based | `back` returns to previous screen | Browser-like |
| B. Flat menu | Always return to main menu | BBS-like |
| C. Context-aware | Smart `back` + global commands anywhere | Modern CLI |

**Recommendation:** Option C - Hybrid approach:
- `back` or `b` returns to previous context
- Global commands work anywhere: `/wire`, `/codex`, `/grid`, `/menu`
- Stack maintained for natural flow

**Decision:** TBD

---

### 3. Command Style

**Question:** Menu-driven, command-driven, or hybrid?

**Options:**
| Option | Example | Best For |
|--------|---------|----------|
| A. Menu-driven | Press 1, 2, 3 | Newcomers, simple navigation |
| B. Command-driven | Type `wire`, `codex` | Power users, faster |
| C. Hybrid | Both work | Maximum flexibility |

**Recommendation:** Option C - Both numbered shortcuts and typed commands. Example: `1` and `grid` both enter THE PULSE GRID.

**Decision:** TBD

---

### 4. Real-Time Features

**Question:** How much real-time interactivity?

**Options:**
| Feature | Complexity | Impact |
|---------|------------|--------|
| Live Wire updates while reading | Medium | High immersion |
| Grid chat visible from menu | Medium | Connected feel |
| "New pulse" notifications | Low | Engagement |
| Cross-system activity ticker | High | Living world feel |

**Questions:**
- Should the Wire auto-update while you're reading it?
- Should you see Grid chat while browsing the Codex?
- How to handle notifications without disrupting reading?

**Decision:** TBD

---

### 5. ANSI Art & Theming

**Question:** How styled should the interface be?

**Options:**
| Level | Description |
|-------|-------------|
| Minimal | Basic formatting, few colors |
| Moderate | Consistent color scheme, simple borders |
| Rich | ASCII art banners, animations, heavy theming |

**Color Palette (Cyberpunk):**
- Primary: Green (`\e[32m`) - terminals, success
- Secondary: Cyan (`\e[36m`) - links, highlights
- Accent: Magenta (`\e[35m`) - warnings, special
- Error: Red (`\e[31m`) - errors, danger
- Muted: Gray (`\e[90m`) - timestamps, metadata

**Questions:**
- ASCII art banner for each section?
- Detect terminal capabilities (colors, width)?
- Animated effects (typing, glitch)?

**Decision:** TBD

---

### 6. Cross-System Integration

**Question:** How interconnected should systems be?

**Proposed Integrations:**
| From | To | Command | Purpose |
|------|-----|---------|---------|
| Grid | Wire | `/pulse "msg"` | Post without leaving game |
| Grid | Codex | `/codex [entry]` | Look up lore mid-game |
| Wire | Codex | `codex [entry]` | Research mentioned topics |
| Anywhere | Grid | `/grid` | Quick jump to MUD |
| Anywhere | Wire | `/wire` | Quick jump to timeline |
| Anywhere | Menu | `/menu` or `home` | Return to main |

**Questions:**
- Should examining items in Grid auto-suggest Codex entries?
- Should Codex entries link to related Grid locations?
- Should band profiles mention if artist is "in-world"?

**Decision:** TBD

---

### 7. Easter Eggs & Hackability

**Question:** What hidden features should exist?

**Ideas:**
| Easter Egg | Trigger | Result |
|------------|---------|--------|
| Hidden commands | `hack`, `root`, `sudo` | Special responses or areas |
| Matrix mode | `follow the white rabbit` | Visual effect |
| Dev backdoor | Secret password | Admin info or joke |
| Lore secrets | Specific command sequences | Hidden Codex entries |
| Retro modes | `cga`, `amber`, `green` | Change color scheme |
| Glitch trigger | `corrupt` or `//` | Glitch text effect |

**Hackability Features:**
- Fake "access denied" messages that can be "bypassed"
- Hidden directories reachable via `cd /secret`
- "Encrypted" messages that decode with right command
- In-world "hacking" puzzles

**Decision:** TBD

---

## Technical Architecture

### Server Options

**DECIDED:** SSH server with password authentication. Two implementation approaches:

**Option 1: System SSH + Restricted Shell**

Configure the system's OpenSSH server with a dedicated `access` user whose shell is a custom Ruby script:

```bash
# /etc/passwd entry
access:x:1001:1001:Terminal Access:/home/access:/opt/hackr/bin/terminal_shell

# /opt/hackr/bin/terminal_shell (the "shell" is your app)
#!/usr/bin/env ruby
require '/home/x/dev/hackr.tv/config/environment'
Terminal::Session.new($stdin, $stdout).run
```

**Pros:** Uses battle-tested OpenSSH, handles encryption/auth natively
**Cons:** System-level configuration, password rotation requires PAM or script

**Option 2: Ruby SSH Server (net-ssh gem)**

Pure Ruby SSH server using the `net-ssh` gem:

```ruby
# Gemfile
gem 'net-ssh'

# lib/terminal/server.rb
require 'net/ssh'

# Custom SSH server implementation
# More control, but more complexity
```

**Pros:** All Ruby, full control, easy password rotation
**Cons:** More code to maintain, less battle-tested

**Recommendation:** Option 1 (System SSH + Restricted Shell) for security and simplicity. Password rotation handled by the shell script checking Rails.

### Shared Code Strategy

Reuse existing Rails components:

| Component | Current | Telnet Adaptation |
|-----------|---------|-------------------|
| `Grid::CommandParser` | Returns HTML | Add `:ansi` format option |
| `Pulse` model | JSON API | Same queries, ANSI render |
| `CodexEntry` model | Markdown content | Markdown → ANSI converter |
| `Artist/Album/Track` | JSON API | Same queries, ANSI render |

### New Components Needed

```
lib/
  terminal/
    session.rb          # Per-connection state machine (entry point)
    renderer.rb         # ANSI color/formatting utilities
    markdown_to_ansi.rb # Convert markdown to terminal output
    password.rb         # Rotating password generation (shared logic)

    handlers/
      menu_handler.rb   # Main menu navigation
      grid_handler.rb   # THE PULSE GRID integration
      wire_handler.rb   # PulseWire commands
      codex_handler.rb  # Codex browsing
      bands_handler.rb  # hackr.fm integration
      vault_handler.rb  # Track listings

app/
  controllers/
    terminal_controller.rb  # Serves /terminal page with credentials

  views/
    terminal/
      index.html.erb    # Access credentials display page
```

### Session State Machine

```
┌─────────────┐
│ CONNECTING  │
└──────┬──────┘
       │
       ▼
┌─────────────┐    login     ┌─────────────┐
│  ANONYMOUS  │─────────────▶│ AUTHENTICATED│
└──────┬──────┘              └──────┬──────┘
       │                            │
       ▼                            ▼
┌─────────────┐              ┌─────────────┐
│ BROWSING    │              │ BROWSING    │
│ (read-only) │              │ (full)      │
└─────────────┘              └──────┬──────┘
                                    │
                    ┌───────────────┼───────────────┐
                    ▼               ▼               ▼
              ┌──────────┐   ┌──────────┐   ┌──────────┐
              │ IN_GRID  │   │ ON_WIRE  │   │ IN_CODEX │
              └──────────┘   └──────────┘   └──────────┘
```

### Connection Management

- Track all connected sessions (for `who` command)
- Idle timeout: 30 minutes? Configurable?
- Max connections: 100? Configurable?
- Graceful shutdown handling

### Database Considerations

- Read-heavy workload (browsing)
- Write operations: Wire posts, Grid commands
- Use same SQLite database as Rails app
- Consider connection pooling for concurrent sessions

---

## Implementation Phases

### Phase 1: Foundation
- [ ] SSH server setup (system SSH + restricted shell)
- [ ] Rotating password system (`lib/terminal/password.rb`)
- [ ] Web credentials page (`/terminal` route + controller + view)
- [ ] Session management (`lib/terminal/session.rb`)
- [ ] ANSI rendering utilities
- [ ] Main menu system
- [ ] Basic authentication (GridHackr login inside app)

### Phase 2: Core Features
- [ ] THE PULSE GRID integration (adapt CommandParser)
- [ ] THE WIRE read access
- [ ] THE CODEX browsing
- [ ] Markdown to ANSI converter

### Phase 3: Full Interactivity
- [ ] Wire posting/echoing/splicing
- [ ] Band profiles and track listings
- [ ] Cross-system navigation
- [ ] Who's online

### Phase 4: Polish & Immersion
- [ ] ASCII art banners
- [ ] Color theming
- [ ] Real-time updates
- [ ] Easter eggs and hidden commands

### Phase 5: Advanced Features
- [ ] Direct messaging between users
- [ ] In-world hacking puzzles
- [ ] Terminal capability detection
- [ ] Performance optimization

---

## Open Questions

1. ~~**Port number?**~~ **DECIDED:** Port 9915 (Fracture Day reference: 9/9/2115)

2. ~~**TLS/SSL?**~~ **DECIDED:** SSH instead of telnet - encrypted by default, password auth only (no keys)

3. **Character encoding?** UTF-8 with fallback to ASCII?

4. **Screen width?** Assume 80 columns? Detect? Configurable?

5. **SSH/Terminal clients?** Test with popular apps (Termux, native ssh, Mudlet, etc.)

6. **Rate limiting?** Prevent spam/abuse?

7. **Logging?** What to log for debugging vs. privacy?

8. **Deployment?** Same server as Rails? Separate process? Systemd service?

9. ~~**Authentication transport?**~~ **DECIDED:** Shared SSH user (`access`) with rotating password. Real auth (GridHackr) happens inside the app after SSH connection.

---

## Inspiration & References

- **BBS Systems:** The nostalgic feel of dialing into a local BBS
- **MUD Clients:** Mudlet, TinTin++, MUSHclient compatibility
- **Cyberpunk Terminals:** Fallout terminals, Shadowrun decks
- **Modern Retro:** cool-retro-term, edex-ui aesthetics

---

## Notes

*This document captures the initial design discussion. Update as decisions are made and implementation progresses.*
