# hackr.tv

> A Ruby on Rails music artist showcase platform and text-based MUD.

**hackr.tv** is a multi-domain music streaming and discovery platform featuring **THE PULSE GRID** - a multiplayer MUD (Multi-User Dungeon) set in 2126. Explore the resistance movement through music and interactive experiences.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.2-red.svg)](https://rubyonrails.org/)
[![React](https://img.shields.io/badge/React-19-61dafb.svg)](https://react.dev/)
[![Tests](https://img.shields.io/badge/Tests-1539%20passing-brightgreen.svg)](#testing)
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
- **Band Profile Pages** - 12 custom band pages with config-based architecture
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
- **Pulse Vault** - Music discovery interface with 71 tracks across 15 artists
  - Real-time search/filter by track, artist, album, genre
  - Click-anywhere playback (any cell in row plays/pauses)
  - Row hover highlighting with dynamic now-playing indicators
  - Album covers with hover zoom overlay (300x300px)
  - Custom SQL ordering (The.CyberPul.se, XERAEN, then alphabetical)
  - Keyboard shortcuts (Tab to search, Spacebar to play/pause)
- **Auto-play & Queue** - Automatic track progression with loop functionality
- **Bands Directory** - 15 artist profiles with track counts and genre information
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
- **Interactive NPCs** - Rich dialogue trees with detailed conversations
  - Fracture Network Coordinator (8 topics: mission, fracture, help, station, synthia, govcorp, ride, prism)
  - Temporal Theorist (8 topics: time, paradox, xeraen, future, discovery, ride, prism, synthia)
- **Command History** - Arrow key navigation through previous commands (up to 100 stored)
- **Room Navigation** - Explore zones controlled by Fracture Network factions
- **Inventory System** - Collect and manage items
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
- **Backend:** Ruby 3.4.7, Rails 8.1.2, Puma
- **Database:** SQLite3 (development), Active Storage for file attachments
- **Real-time:** Action Cable 8.1 with Solid Cable adapter
- **Background Jobs:** Solid Queue for async processing
- **Caching:** Solid Cache
- **Email:** Action Mailer with email tracking (SentEmail + EmailObserver)
- **Testing:** RSpec (backend), Vitest (frontend), FactoryBot, Faker
- **Code Quality:** StandardRB, ESLint
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
   - Admin Dashboard: http://localhost:3000/root (requires Grid admin account)

---

## Playing THE PULSE GRID

**Login:** Create an account at `/grid/register`, or create one via Rails console if running locally:
```ruby
GridHackr.create!(hackr_alias: "YourName", password: "yourpassword", role: "admin")
```

**Available Commands:**
```
look (l)               - Examine your surroundings
go [direction]         - Move in a direction (north, south, east, west, up, down)
inventory (inv, i)     - Check your items
take [item]            - Pick up an item
drop [item]            - Drop an item
examine [item]         - Inspect an item closely
talk [npc]             - Initiate conversation with an NPC
ask [npc] about [topic] - Ask an NPC about a specific topic
say [message]          - Talk to other players in the room
who                    - List online players
help                   - Show command reference
clear (cls)            - Clear the screen
```

**Navigation:**
- Use `/disconnect` menu item or type logout command to disconnect from THE PULSE GRID
- Arrow keys navigate through command history

**NPCs with Dialogue:**
- **Fracture Network Coordinator** (hackr.tv Broadcast Station) - Topics: mission, fracture, help, station, synthia, govcorp, ride, prism
- **Temporal Theorist** (XERAEN Operations Center) - Topics: time, paradox, xeraen, future, discovery, ride, prism, synthia

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
│   │   │   ├── pages/                 # 30+ React pages
│   │   │   ├── audio/                 # PlayerBar, SeekBar, QueuePanel
│   │   │   └── playlists/             # CreatePlaylistModal, AddToPlaylistDropdown
│   │   ├── contexts/
│   │   │   └── AudioContext.tsx       # Global audio player state
│   │   └── hooks/                     # useGridAuth, useAudio, useActionCable
│   ├── controllers/
│   │   ├── api/                       # JSON API for React SPA
│   │   ├── admin/                     # Server-rendered admin CRUD
│   │   └── application_controller.rb  # Multi-domain routing
│   ├── models/                        # 40+ Active Record models
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
│   └── channels/
│       ├── grid_channel.rb            # Real-time multiplayer (Action Cable)
│       ├── pulse_wire_channel.rb      # PulseWire social feed updates
│       ├── uplink_channel.rb          # Uplink comms
│       └── overlay_channel.rb         # OBS overlay broadcasts
├── data/                              # YAML seed data
│   ├── artists.yml                    # 15 artists
│   ├── albums.yml                     # 18 albums
│   ├── tracks.yml                     # 71 tracks
│   ├── system/                        # Hackrs, channels, radio, redirects
│   ├── world/                         # Zones, rooms, exits, mobs, items
│   ├── content/                       # Codex, hackr_logs, wire
│   ├── playlists/                     # Curated playlists
│   └── overlays/                      # Overlay scenes, elements, tickers
├── lib/tasks/
│   └── data.rake                      # Unified data loading system
├── spec/                              # Test suite
│   ├── models/                        # Model specs
│   ├── controllers/                   # Controller specs
│   ├── components/                    # ViewComponent specs
│   └── services/                      # Service specs
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
- **Backend:** 1376 examples (RSpec)
- **Frontend:** 163 examples (Vitest)
- **Total:** 1539 passing tests

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
bin/rails data:world                # Factions, zones, rooms, exits, mobs, items
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
1. Add artist to `data/artists.yml`
2. Create directory: `data/[artist-slug]/`
3. Add albums to `data/albums.yml`
4. Add tracks to `data/tracks.yml`
5. Place audio files and cover images in `data/[artist-slug]/`
6. Run `bin/rails data:catalog`

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

### THE PULSE GRID
- **grid_hackrs** - player accounts with bcrypt authentication (role: operative/admin), has_many :playlists
- **grid_rooms** - locations in THE PULSE GRID
- **grid_zones** - areas grouping rooms (faction_base, govcorp, transit)
- **grid_factions** - Fracture Network factions (The.CyberPul.se, XERAEN, GovCorp)
- **grid_exits** - directional connections between rooms
- **grid_items** - objects in rooms or inventories
- **grid_mobs** - NPCs with dialogue trees (dialogue_tree JSON column)
- **grid_messages** - comms and system messages

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
- Band profile pages - 12 artists with config-based routing
- Album model - Active Storage cover images with hover zoom
- Unified data loading system - 26 idempotent tasks with dependency ordering
- hackr.fm Radio - 4 stations with live streaming
- Pulse Vault - 71 tracks, search/filter, click-anywhere playback, custom ordering
- Auto-play next track - Queue management with loop functionality
- THE PULSE GRID - Real-time multiplayer MUD (5 zones, 5 rooms, 2 NPCs)
- NPC dialogue system - 2 NPCs with 13 unique topics
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
- Comprehensive test suite - 1376 backend + 163 frontend tests (1539 total)

### Future Enhancements
- World expansion - More rooms, NPCs, items (currently only 5 rooms)
- Faction reputation system
- Mission/quest system for THE PULSE GRID
- Hacking system
- Combat mechanics (physical/cyber)
- Synthia frequency tuning mechanic
- Persistent inventory between sessions

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
| `bin/rails data:reset` | Reset seed content (preserves user data) |
| `bundle exec rspec` | Run backend test suite (1376 tests) |
| `pnpm test` | Run frontend test suite (163 tests) |
| `bundle exec standardrb` | Lint backend code |
| `pnpm install` | Install frontend dependencies |

---

**Built for those who turn toward good, the Hackrs of CyberSpace! The future is not lost!**

*hackr.tv - Where music meets THE GRID.*
