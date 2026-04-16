# hackr.tv

> A Ruby on Rails music artist showcase platform and text-based MUD.

**hackr.tv** is a multi-domain music streaming and discovery platform featuring **THE PULSE GRID** - a multiplayer MUD (Multi-User Dungeon) set in 2126. Explore the resistance movement through music and interactive experiences.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.3-red.svg)](https://rubyonrails.org/)
[![React](https://img.shields.io/badge/React-19.2-61dafb.svg)](https://react.dev/)
[![Tests](https://img.shields.io/badge/Tests-2097%20passing-brightgreen.svg)](#testing)
[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

---

## Features

### React SPA Architecture
- **Full Single Page Application** - Built with React 19, TypeScript, and React Router v7
- **Persistent Audio Player** - Music continues playing across all navigation
- **Code Splitting** - Lazy loading for optimal performance
- **Error Boundaries** - Graceful error handling with custom 404 page
- **Server-Rendered Admin** - Admin section remains traditional Rails for simplicity

### hackr.tv Platform
- **Animated Terminal Homepage** - Retro terminal-style interface with typing animation and keyboard skip
- **Menu System** - Dynamic navigation with artist profiles, services, and conditional admin access
- **Multi-Artist Showcases** - Dedicated pages for The.CyberPul.se, XERAEN, and more
- **Band Profile Pages** - 16 custom band pages with config-based architecture
- **ViewComponent Architecture** - Reusable BandProfileComponent with flexible color schemes
- **Hackr Logs** - Blog platform with Markdown support (remark-gfm, rehype-sanitize)

### hackr.fm Music Platform
- **Radio Stations** - Database-backed with full CRUD admin interface
  - 4 configurable stations (The.CyberPul.se, XERAEN, Sector X Underground, GovCorp Official)
  - Playlist management per station with manual position ordering
  - Live web radio streaming with HTML5 audio player
- **User Playlists** - Full playlist system with Grid Hackr authentication
  - Create/edit/delete playlists
  - Add tracks from Pulse Vault and PlayerBar
  - Manual drag-and-drop ordering
  - Public sharing via unique share tokens (`/shared/:token`)
  - Queue panel showing current + next 3 tracks
  - Playlist context preservation across navigation
- **Pulse Vault** - Music discovery interface with 71 tracks across 16 artists
  - Real-time search/filter by track, artist, album, genre
  - Click-anywhere playback (any cell in row plays/pauses)
  - Row hover highlighting with dynamic now-playing indicators
  - Album covers with hover zoom overlay (300x300px)
  - Custom SQL ordering (The.CyberPul.se, XERAEN, then alphabetical)
  - Keyboard shortcuts (Tab to search, Spacebar to play/pause)
- **Auto-play & Queue** - Automatic track progression with loop functionality
- **Bands Directory** - 16 artist profiles with track counts and genre information
- **Track List Pages** - Artist track listings at `/:artist_slug/trackz`
- **Track Detail Pages** - Individual track pages with lyrics, streaming links, and video embeds
  - Streaming links organized by platform (Bandcamp, YouTube, Spotify, Apple Music, SoundCloud)
  - Lyrics display with Markdown and Codex auto-linking
  - Artist-specific color themes

### The Codex - Wiki
- **Encyclopedia** - Comprehensive wiki documenting THE.CYBERPUL.SE
- **7 Entry Types** - People, organizations, events, locations, technology, factions, items
- **Markdown Content** - Rich formatting with auto-linking via `[[Entry Name]]` syntax
- **Search & Filter** - Find entries by type, search by name/content
- **Admin Interface** - Full CRUD with draft/publish workflow at `/root/codex`

### PulseWire - Social Network
- **Micro-Blogging** - Twitter-like platform for Grid Hackr users
- **Pulses** - 256-character posts with real-time updates via Action Cable
- **Echoes** - Rebroadcast system (like retweets)
- **Splices** - Threaded replies for conversations
- **Hotwire Timeline** - Global feed with infinite scroll
- **User Profiles** - View any user's pulse history at `/wire/:username`
- **Admin Moderation** - SignalDrop system for content moderation

### Uplink - Comms System
- **Channel-Based Comms** - Real-time messaging with multiple configurable channels
- **Slow Mode** - Configurable rate limiting per channel
- **Role-Based Access** - Channels can require minimum roles
- **Livestream Integration** - Channels that activate during livestreams
- **Popout Mode** - Detachable Uplink window at `/uplink/popout`
- **Moderation** - Squelch, blackout, and punishment management

### THE PULSE GRID - MUD
- **Real-time Multiplayer** - Live comms and movement tracking via Action Cable
- **World** - 6 zones, 7 rooms, 4 NPCs, 7 factions, items, and interactive objects
- **Interactive NPCs** - Rich dialogue trees with quest givers, vendors, and conversation topics
- **Persistent Progression** - XP, clearance levels (0–99), vitals (HP/energy/psyche), inventory with rarity and stacking
- **CRED Economy** - Fixed-supply cryptocurrency with append-only ledger, CRED caches, mining rigs, stream bonuses, and Fracture Reserve monetary policy (70% burn, 30% recycle)
- **Shops & Black Market** - Standard and black market vendors with dynamic pricing, clearance-gated listings, and CRED transactions
- **Faction Reputation** - 7 factions with leaf-storage + derived rollup reputation via directed rep-link graph, 8-tier ladder system
- **Achievement System** - Site-wide badges covering Grid, music, social, content, and progression categories with XP + CRED rewards
- **Mission/Quest System** - NPC-gated structured objectives with storyline arcs, prereq chains, clearance/rep gates, 10 objective types, 5 reward types, and per-hackr progress tracking
- **30+ Commands** - Navigation, interaction, inventory, stats, economy (cache, chain, rig, shop, buy, sell), missions (accept, abandon, turn_in, give), social (say, who), and meta commands
- **Command History** - Arrow key navigation through previous commands (up to 100 stored)
- **Feature Access Control** - Admin-grantable access via FeatureGrant system
- **Optimized UI** - Clean terminal-style interface with comfortable dark theme
- **Dedicated Grid Layout** - 700px output window, compact design, no page scrolling

### OBS Overlay System
- **Now Playing Overlay** - Display currently playing track for livestreams
- **PulseWire Overlay** - Show live social activity during streams
- **Grid Activity Overlay** - Stream multiplayer Grid activity
- **Scene Management** - Compose multiple overlay elements with positioning
- **Scene Groups** - Collections of scenes for easy switching during streams (admin at `/root/overlays/groups`)
- **Lower Thirds** - Text overlays with custom slugs and styling
- **Tickers** - Scrolling marquee text for announcements
- **Alert System** - Alert notifications via Action Cable
- **Real-time Updates** - All overlays update via WebSocket broadcasts

### Hackr Streams
- **Livestream Management** - Go live/end stream functionality for artists
- **VOD Support** - Video on demand URL storage for past streams
- **YouTube Integration** - Auto-conversion of YouTube URLs to embed format
- **Stream Timing** - Track stream start/end times with validation

### Account Management & Email
- **Registration** - Email-verified account creation with registration tokens
- **Password Reset** - Token-based password reset via email
- **Email Change** - Self-service email change with verification and notification
- **Email Tracking** - All sent emails recorded via EmailObserver
- **GridMailer** - 4 transactional email types (registration, password reset, email change verification, email change notification)

### Hackr Handbook
- **Documentation Portal** - GitBook-style docs for THE.CYBERPUL.SE at `/handbook`
- **Sections & Articles** - Hierarchical content with visibility scope (public, operative, admin)
- **YAML Seed** - Content managed via YAML data files
- **Markdown Rendering** - Reuses MarkdownContent component from Codex

### Terminal SSH Access
- **BBS-Style Terminal** - SSH access to THE.CYBERPUL.SE at `ssh access@terminal.hackr.tv -p 9915`
- **Daily Rotating Password** - Displayed at `/terminal` page, rotates at midnight UTC
- **Full System Access** - Grid MUD, PulseWire, Codex, hackr.fm bands and Pulse Vault via terminal
- **ASCII Art & Effects** - 12 custom banners, glitch/typing/scanline/decrypt effects
- **Color Schemes** - Cyberpunk (default), amber, green, CGA phosphor modes
- **Easter Eggs** - Hidden hacker commands, Matrix references, GovCorp surveillance intercepts
- **Real-time Updates** - Live Wire and Grid notifications via Action Cable pubsub
- **Docker Deployment** - Single container with `TERMINAL_SSH_ENABLED` toggle, PAM auth, SSH host key persistence

### Zone Playlists
- **Ambient Music** - Per-zone background playlists for THE PULSE GRID
- **Admin Management** - CRUD interface for zone playlist configuration
- **Track Ordering** - Manual position control within zone playlists

### Multi-Domain Architecture
- Domain-specific routing and layouts (hackr.tv, xeraen.com, rockerboy.net, ashlinn.net, sectorx.media)
- Mobile-responsive TUI (Terminal User Interface) design
- Database-backed redirect system
- Artist-specific branding and theming

### API Token Authentication
- **Bearer Token Auth** - Programmatic API access for Grid Hackr accounts
- **Token Generation** - `bin/rails api:generate_token[alias]` rake task
- **Header Format** - `Authorization: Bearer <token>`
- **Use Cases** - CLI tools, integrations, automated workflows

### Prerelease Mode
- **Registration Control** - Disable new user registration during alpha/beta phases
- **Banner System** - Customizable prerelease banner text
- **Configuration** - `config/app_settings.yml` with `prerelease_mode` and `prerelease_banner_text`
- **Settings API** - `GET /api/settings` returns current prerelease state

### Security
- **Content Security Policy** - CSP with nonce-based inline script execution
- **XSS Protection** - Prevents cross-site scripting while allowing dynamic scripts
- **Rate Limiting** - Rack::Attack for request throttling

---

## Tech Stack

- **Frontend:** React 19, TypeScript, React Router v7, Vite
- **Backend:** Ruby 3.4.7, Rails 8.1.3, Puma
- **Database:** SQLite3 (development), Active Storage for file attachments
- **Real-time:** Action Cable 8.1 with Solid Cable adapter
- **Background Jobs:** Solid Queue for async processing
- **Caching:** Solid Cache
- **Email:** Action Mailer with email tracking (SentEmail + EmailObserver)
- **Testing:** RSpec (backend), Vitest (frontend), FactoryBot, Faker
- **Code Quality:** StandardRB, ESLint, Brakeman (security scanner)
- **Assets:** Propshaft, TuiCSS (terminal UI framework)
- **Authentication:** bcrypt for password hashing (Grid Hackr accounts)
- **Markdown:** react-markdown, remark-gfm, rehype-sanitize
- **Content Safety:** Obscenity gem for profanity filtering

---

## Getting Started

### Prerequisites
- Ruby 3.4.7
- Bundler
- SQLite3
- Node.js (for React frontend)
- pnpm (package manager)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hackrTV/hackr.tv.git
   cd hackr.tv
   ```

2. **Install dependencies**
   ```bash
   bundle install
   pnpm install
   ```

3. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. **Load seed data**
   ```bash
   bin/rails data:load
   ```
   See [IMPORT_README.md](IMPORT_README.md) for details on the data loading system.

5. **Start the server**
   ```bash
   bin/dev
   ```

6. **Visit the application**
   - hackr.tv Home: http://localhost:3000
   - The.CyberPul.se: http://localhost:3000/thecyberpulse
   - THE PULSE GRID: http://localhost:3000/grid
   - hackr.fm Radio: http://localhost:3000/fm/radio
   - Pulse Vault: http://localhost:3000/fm/pulse-vault
   - Playlists: http://localhost:3000/fm/playlists (requires Grid login)
   - The Codex: http://localhost:3000/codex
   - PulseWire: http://localhost:3000/wire
   - Uplink: http://localhost:3000/uplink
   - Hackr Handbook: http://localhost:3000/handbook
   - Missions: http://localhost:3000/missions (requires Grid login)
   - Terminal Credentials: http://localhost:3000/terminal
   - Admin Dashboard: http://localhost:3000/root (requires Grid admin account)

---

## Playing THE PULSE GRID

**Login:** Create an account at `/grid/register`, or create one via Rails console if running locally:
```ruby
GridHackr.create!(hackr_alias: "YourName", password: "yourpassword", role: "admin")
```

**Available Commands:**
```
Movement & Exploration
  look (l)                    - Examine your surroundings
  go [direction]              - Move (north/south/east/west/up/down, or n/s/e/w/u/d)
  examine [item] (ex, x)     - Inspect an item closely

Inventory & Items
  inventory (inv, i)          - Check your items
  take [item]                 - Pick up an item
  drop [item]                 - Drop an item
  use [item]                  - Use an item
  salvage [item]              - Break down an item
  give [item] to [npc]        - Give an item to an NPC

NPCs & Social
  talk [npc]                  - Initiate conversation with an NPC
  ask [npc] about [topic]     - Ask an NPC about a specific topic
  say [message]               - Talk to other players in the room
  who                         - List online players

Stats & Progression
  stat (stats, st)            - View your stats, XP, clearance, and vitals
  rep (reputation, standing)  - View faction reputation standings

Economy
  cache                       - Manage CRED caches (create/balance/history/send)
  caches (cred)               - View CRED balance
  chain                       - View blockchain info (latest/tx/cache/supply)
  rig                         - Manage mining rigs (on/off/install/uninstall/inspect)
  shop (browse)               - Browse shop listings
  buy [item]                  - Purchase from a shop
  sell [item]                 - Sell an item

Missions
  missions (quests)           - List available and active missions
  mission [slug]              - View mission details
  accept [slug]               - Accept a mission
  abandon [slug]              - Abandon an active mission
  turn_in [slug] (turnin, ti) - Turn in a completed mission

Meta
  help (?)                    - Show command reference
  clear (cls)                 - Clear the screen
```

**Navigation:**
- Use `/disconnect` menu item or type logout command to disconnect from THE PULSE GRID
- Arrow keys navigate through command history

**NPCs:**
- **Fracture Network Coordinator** (hackr.tv Broadcast Station) - Quest giver
- **Codec** (Transit Corridor Alpha) - Vendor
- **GHOST** (The Blacksite) - Quest giver
- **Temporal Theorist** (XERAEN Operations Center) - Quest giver

---

## Project Structure

```
hackr.tv/
├── app/
│   ├── javascript/                    # React SPA (TypeScript)
│   │   ├── entrypoints/
│   │   │   └── application.tsx        # React app entry point
│   │   ├── components/
│   │   │   ├── layouts/               # AppLayout, Header, Footer
│   │   │   ├── pages/                 # React pages
│   │   │   ├── audio/                 # PlayerBar, SeekBar, QueuePanel
│   │   │   └── playlists/             # CreatePlaylistModal, AddToPlaylistDropdown
│   │   ├── contexts/
│   │   │   └── AudioContext.tsx       # Global audio player state
│   │   └── hooks/                     # 14 custom hooks (useGridAuth, useUplink, etc.)
│   ├── controllers/
│   │   ├── api/                       # JSON API for React SPA
│   │   ├── admin/                     # Server-rendered admin CRUD
│   │   └── application_controller.rb  # Multi-domain routing
│   ├── models/                        # 69 Active Record models (28 Grid-specific)
│   ├── services/
│   │   └── grid/                      # Grid services (economy, missions, reputation, shops, etc.)
│   ├── mailers/
│   │   └── grid_mailer.rb             # Transactional emails
│   ├── observers/
│   │   └── email_observer.rb          # Email tracking
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── application.html.erb   # React SPA shell
│   │   │   └── admin.html.erb         # Admin layout
│   │   └── admin/                     # Admin views (server-rendered)
│   ├── components/
│   │   └── band_profile_component.rb  # Reusable band profile (ViewComponent)
│   └── channels/                      # 7 Action Cable channels
│       ├── grid_channel.rb            # Real-time multiplayer
│       ├── achievement_channel.rb     # Per-hackr achievement/mission broadcasts
│       ├── live_chat_channel.rb       # Uplink comms
│       ├── pulse_wire_channel.rb      # PulseWire social feed updates
│       ├── stream_status_channel.rb   # Livestream state changes
│       └── overlay_channel.rb         # OBS overlay broadcasts
├── data/                              # YAML seed data
│   ├── catalog/                       # Per-artist YAML files (16 artists)
│   ├── system/                        # Hackrs, channels, radio, redirects
│   ├── world/                         # Zones, rooms, exits, mobs, items, factions,
│   │                                  #   achievements, missions, shop_listings
│   ├── content/                       # Codex, hackr_logs, wire, handbook
│   ├── playlists/                     # Curated playlists
│   └── overlays/                      # Overlay scenes, elements, tickers
├── lib/
│   ├── tasks/
│   │   └── data.rake                  # Unified data loading system
│   └── terminal/                      # SSH terminal system
│       ├── session.rb                 # State machine, input loop
│       ├── password.rb                # Daily rotating password
│       ├── renderer.rb                # HTML-to-ANSI converter
│       ├── art.rb                     # ASCII art loader
│       ├── effects.rb                 # Visual effects (glitch, typing, scanline)
│       ├── easter_eggs.rb             # Hidden commands
│       ├── realtime_subscriber.rb     # Action Cable pubsub for terminal
│       └── handlers/                  # Terminal command handlers
├── spec/                              # Test suite (2097 total)
│   ├── models/                        # Model specs
│   ├── controllers/                   # Controller specs
│   ├── components/                    # ViewComponent specs
│   ├── services/                      # Service specs
│   └── lib/terminal/                  # Terminal specs (198 examples)
└── config/
    └── routes.rb                      # Multi-domain routing
```

---

## Testing

Run the full test suite:
```bash
# Backend tests
bundle exec rspec

# Frontend tests
pnpm test
```

Run specific test files:
```bash
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
bundle exec rspec spec/services/
bundle exec rspec spec/components/
```

**Test Coverage:**
- **Backend:** 1853 examples (RSpec)
- **Frontend:** 244 examples (Vitest)
- **Total:** 2097 passing tests

---

## Development

### Code Quality
```bash
bundle exec standardrb              # Lint code
bundle exec standardrb --fix        # Auto-fix issues
```

### Data Loading
The data loading system uses YAML files as the single source of truth for all seed content:

```bash
bin/rails data:load                 # Load everything
bin/rails data:catalog              # Artists, albums, tracks only
bin/rails data:system               # Hackrs, channels, radio, redirects
bin/rails data:world                # Factions, zones, rooms, exits, mobs, items, achievements, missions, shop_listings
bin/rails data:content              # Codex, hackr_logs, wire
bin/rails data:overlays             # Overlay scenes, elements, tickers
```

See [IMPORT_README.md](IMPORT_README.md) for the full data loading reference.

**Features:**
- Idempotent operations (safe to re-run)
- Dependency-aware ordering (26 tasks in correct sequence)
- S3 audio sideloading (`S3_BUCKET=bucket bin/rails data:audio`)
- Reset seed content without touching user data (`data:reset`)

### Adding New Content

**Add a New Artist:**
1. Create `data/catalog/[artist-slug].yml` with artist, albums, and tracks
2. Create directory: `data/[artist-slug]/` for audio files and cover images
3. Run `bin/rails data:catalog`

**Add a Radio Station:**
1. Login to admin at `/root` with Grid admin account
2. Navigate to Radio Stations, then New
3. Fill in station details (name, description, genre, stream_url, color)
4. Add playlists to the station
5. Reorder playlists as needed via drag-and-drop

---

## Design System

**TuiCSS Framework:**
- Monospace fonts with terminal styling
- ANSI 168 color palette
- Green-on-black aesthetic with purple accents
- Responsive `.show-on-small` / `.hide-on-med-and-up` classes
- Terminal window components (`.tui-window`, `.tui-fieldset`, `.tui-button`)

**Color Scheme:**
- Primary: `#7c3aed` (purple)
- Secondary: `#a78bfa` (light purple)
- Accent: `#00d9ff` (cyan)
- Background: `#0a0a0a`, `#1a1a1a`
- Text: `#ccc`, `#888`, `#666`

---

## Database Schema

### Music Platform
- **artists** - name, slug, genre, artist_type (band/ost/voiceover)
- **albums** - title, slug, album_type, release_date, description, cover_image (Active Storage)
- **tracks** - title, slug, track_number, release_date, duration, genre, featured, streaming_links (JSON), videos (JSON), lyrics, audio_file (Active Storage)
- **playlists** - name, description, is_public, share_token, belongs_to :grid_hackr
- **playlist_tracks** - position (1+), belongs_to :playlist, belongs_to :track
- **radio_stations** - name, slug, description, genre, color, stream_url, position
- **radio_station_playlists** - position (1+), belongs_to :radio_station, belongs_to :playlist

### THE PULSE GRID — Core
- **grid_hackrs** - player accounts with bcrypt auth (role: operative/operator/admin), XP, clearance (0–99), vitals, CRED balance, mining stats, has_many :playlists
- **grid_rooms** - locations in THE PULSE GRID
- **grid_zones** - areas grouping rooms (faction_base, govcorp, transit, black_market)
- **grid_factions** - 7 factions (The Fracture Network, Hackrcore, Blackout, Frontwave, Offline, GovCorp, Dante Russo)
- **grid_exits** - directional connections between rooms
- **grid_items** - objects with rarity, stacking, equippable flag, room or inventory placement
- **grid_mobs** - NPCs with dialogue trees, mob_type (quest_giver, vendor)
- **grid_messages** - comms and system messages

### THE PULSE GRID — Economy
- **grid_caches** - CRED wallets (one per hackr), balance tracking
- **grid_transactions** - append-only ledger for all CRED movement (transfer, mining_reward, gameplay_reward, burn, redemption, genesis)
- **grid_mining_rigs** - per-hackr mining hardware with PSU/CPU/GPU/RAM components
- **grid_shop_listings** - vendor inventory with price, clearance requirements, stock limits
- **grid_shop_transactions** - purchase audit log

### THE PULSE GRID — Reputation & Achievements
- **grid_hackr_reputations** - per-hackr per-faction rep values (leaf storage)
- **grid_faction_rep_links** - directed graph for rep rollup between factions
- **grid_reputation_events** - audit log of rep changes
- **grid_achievements** - badge definitions with trigger types, thresholds, and XP/CRED rewards
- **grid_hackr_achievements** - per-hackr unlock tracking with awarded_at

### THE PULSE GRID — Missions
- **grid_mission_arcs** - optional storyline grouping
- **grid_missions** - definitions with prereq chains, clearance/rep gates, NPC giver, published status
- **grid_mission_objectives** - 10 types (visit_room, talk_npc, collect_item, deliver_item, spend_cred, buy_item, reach_rep, reach_clearance, use_item, salvage_item)
- **grid_mission_rewards** - 5 types (xp, cred, faction_rep, item_grant, grant_achievement)
- **grid_hackr_missions** - per-hackr mission state (active/completed/abandoned), partial unique index on active instances
- **grid_hackr_mission_objectives** - per-objective progress tracking

### Account Management
- **grid_registration_tokens** - email, token, expires_at, used_at, ip_address
- **grid_verification_tokens** - purpose (password_reset/email_change), token, expires_at, metadata (JSON)
- **feature_grants** - grid_hackr_id, feature (controls access to features like THE PULSE GRID)
- **sent_emails** - to, from, subject, mailer_class, mailer_action, emailable (polymorphic)

### Uplink
- **chat_channels** - name, slug, description, minimum_role, requires_livestream, slow_mode_seconds, is_active
- **chat_messages** - content, dropped, belongs_to :chat_channel, belongs_to :grid_hackr

### Moderation
- **user_punishments** - punishment_type, reason, expires_at, belongs_to :grid_hackr
- **moderation_logs** - action, reason, duration_minutes, actor_id, target_id

### Blog
- **hackr_logs** - blog posts with Markdown content, published status

### The Codex
- **codex_entries** - name, slug, entry_type (person/organization/event/location/technology/faction/item), summary, content (markdown), metadata (JSON), published, position

### PulseWire
- **pulses** - content (256 char max), parent_pulse_id, thread_root_id, echo_count, splice_count, pulsed_at, signal_dropped, is_seed, belongs_to :grid_hackr
- **echoes** - echoed_at, belongs_to :pulse (counter_cache), belongs_to :grid_hackr

### Streaming
- **hackr_streams** - live_url, vod_url, started_at, ended_at, belongs_to :artist

### Zone Playlists
- **zone_playlists** - name, belongs_to :grid_zone
- **zone_playlist_tracks** - position, belongs_to :zone_playlist, belongs_to :track

### OBS Overlays
- **overlay_scenes** - name, slug, scene_type (fullscreen/composition)
- **overlay_elements** - element_type, config (JSON)
- **overlay_scene_elements** - position_x, position_y, width, height, z_index, belongs_to :overlay_scene, belongs_to :overlay_element
- **overlay_scene_groups** - name, slug, has_many :overlay_scenes
- **overlay_scene_group_scenes** - position, belongs_to :overlay_scene_group, belongs_to :overlay_scene
- **overlay_now_playings** - track metadata singleton
- **overlay_alerts** - message, alert_type
- **overlay_tickers** - text, speed
- **overlay_lower_thirds** - title, subtitle, slug

---

## Multi-Domain Setup

**Supported Domains:**
- `hackr.tv` - Main site
- `xeraen.com`, `xeraen.net`, `rockerboy.net`, `rockerboy.stream` - XERAEN artist domains
- `ashlinn.net` - Ashlinn redirect
- `sectorx.media` - Sector X
- `cyberpul.se`, `the.cyberpul.se` - The.CyberPul.se

**Domain Logic:**
1. Database-backed redirects (domain + path to destination)
2. Domain-specific redirects (artist domains to hackr.tv/artist)
3. Automatic mobile detection and layout selection

---

## Roadmap

### Completed
- React SPA Migration - Full SPA with React 19, TypeScript, React Router v7
- Database-Backed Radio Stations - Full CRUD admin interface with playlist management
- User Playlists - Create/edit/delete with Grid Hackr auth and public sharing
- Queue Panel - Current + next 3 tracks display with click-to-jump
- Animated terminal homepage - Typing effect & keyboard skip
- ViewComponent architecture - Reusable band profiles with flexible color schemes
- Band profile pages - 16 artists with config-based routing
- Album model - Active Storage cover images with hover zoom
- Unified data loading system - Idempotent tasks with dependency ordering
- hackr.fm Radio - 4 stations with live streaming
- Pulse Vault - 71 tracks, search/filter, click-anywhere playback, custom ordering
- Auto-play next track - Queue management with loop functionality
- THE PULSE GRID - Real-time multiplayer MUD (6 zones, 7 rooms, 4 NPCs, 7 factions)
- NPC dialogue system - Quest givers, vendors, and conversation topics
- Command history - Arrow key navigation (100 commands)
- Feature access control - Admin-grantable feature grants for Grid access
- Hackr Logs - Blog platform with Markdown support
- The Codex wiki - 7 entry types, markdown with auto-linking, admin CRUD, public SPA
- PulseWire social network - Pulses, Echoes, Splices, real-time updates, admin moderation
- OBS Overlay system - Scenes, groups, now playing, lower thirds, tickers, alerts
- Hackr Streams - Livestream management with go live/VOD support
- Zone Playlists - Per-zone ambient music for THE PULSE GRID
- Uplink - Channel-based real-time comms with moderation and popout mode
- Email system - Registration verification, password reset, email change, sent email tracking
- Background infrastructure - Solid Queue, Solid Cache, Solid Cable configured
- Terminal SSH Access - BBS-style SSH terminal with ASCII art, effects, real-time updates
- Persistent Progression - XP, clearance levels (0–99), vitals, inventory with rarity/stacking
- CRED Economy - Fixed-supply cryptocurrency with caches, append-only ledger, mining rigs
- Shops & Black Market - Standard and black market vendors with dynamic pricing
- Faction Reputation - 7 factions, leaf-storage + rollup rep, 8-tier ladder
- Achievement/Badge System - Site-wide badges with XP + CRED rewards
- Mission/Quest System - NPC-gated objectives, storyline arcs, prereq chains, 10 objective types
- Hackr Handbook - GitBook-style documentation portal
- Comprehensive test suite - 1853 backend + 244 frontend tests (2097 total)

### Future Enhancements
- World expansion - More rooms, NPCs, items, and interactive objects
- Hacking system - Mini-games for breaking into systems
- Combat mechanics - Physical/cyber encounters
- Synthia frequency tuning mechanic
- Twitter/X auto-posting for admin events

---

## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

See [UNLICENSE](UNLICENSE) for details.

---

## Contributing

This project is released into the public domain, so feel free to fork, modify, and use it however you like. If you have an idea for a feature or improvement that would be cool to have merged into the primary codebase, let's discuss in the Issues section!

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `bin/dev` | Start development server (Rails + Vite) |
| `bin/rails console` | Interactive Rails console |
| `bin/rails db:migrate` | Run database migrations |
| `bin/rails data:load` | Load all seed data from YAML |
| `bin/rails data:catalog` | Load artists, albums, tracks only |
| `bin/rails data:world` | Load factions, zones, rooms, mobs, items, achievements, missions, shops |
| `bin/rails data:reset` | Reset seed content (preserves user data) |
| `bundle exec rspec` | Run backend test suite (1853 tests) |
| `pnpm test` | Run frontend test suite (244 tests) |
| `bundle exec standardrb` | Lint backend code |
| `bundle exec brakeman` | Run security scanner |
| `./bin/terminal-test` | Test SSH terminal locally (no SSH needed) |
| `pnpm install` | Install frontend dependencies |

---

**Built for those who turn toward good, the Hackrs of CyberSpace! The future is not lost!**

*hackr.tv - Where music meets THE GRID.*
