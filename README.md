# hackr.tv

> A Ruby on Rails music artist showcase platform and text-based MUD game set in a dystopian cyberpunk universe.

**hackr.tv** is a multi-domain music streaming and discovery platform featuring **THE PULSE GRID** - a playable multiplayer MUD (Multi-User Dungeon) set in 2125. Explore the resistance movement through music, lore, and interactive gameplay.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.2-red.svg)](https://rubyonrails.org/)
[![React](https://img.shields.io/badge/React-19-61dafb.svg)](https://react.dev/)
[![Tests](https://img.shields.io/badge/Tests-1233%20passing-brightgreen.svg)](#testing)
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
- **Band Profile Pages** - 13 custom band pages with config-based architecture
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
  - Public sharing via unique share tokens
  - Queue panel showing current + next 3 tracks
  - Playlist context preservation across navigation
- **Pulse Vault** - Music discovery interface with 66+ tracks
  - Real-time search/filter by track, artist, album, genre
  - Click-anywhere playback (any cell in row plays/pauses)
  - Row hover highlighting with dynamic now-playing indicators
  - Album covers with hover zoom overlay (300x300px)
  - Custom SQL ordering (The.CyberPul.se, XERAEN, then alphabetical)
  - Keyboard shortcuts (Tab to search, Spacebar to play/pause)
- **Auto-play & Queue** - Automatic track progression with loop functionality
- **Bands Directory** - Artist profiles with track counts and genre information

### The Codex - Lore Wiki
- **In-World Encyclopedia** - Comprehensive wiki documenting THE.CYBERPUL.SE universe
- **7 Entry Types** - People, organizations, events, locations, technology, factions, items
- **Markdown Content** - Rich formatting with auto-linking via `[[Entry Name]]` syntax
- **Search & Filter** - Find entries by type, search by name/content
- **Admin Interface** - Full CRUD with draft/publish workflow at `/root/codex`

### PulseWire - Social Network
- **In-World Micro-Blogging** - Twitter-like platform for Grid Hackr users
- **Pulses** - 256-character posts with real-time updates via Action Cable
- **Echoes** - Rebroadcast system (like retweets)
- **Splices** - Threaded replies for conversations
- **Hotwire Timeline** - Global feed with infinite scroll
- **User Profiles** - View any user's pulse history at `/wire/:username`
- **Admin Moderation** - SignalDrop system for content moderation

### THE PULSE GRID - MUD Game
- **Real-time Multiplayer** - Live chat and movement tracking via Action Cable
- **Interactive NPCs** - Rich dialogue trees with lore-heavy conversations
  - Fracture Network Coordinator (6 topics: mission, fracture, help, station, synthia, govcorp)
  - Temporal Theorist (7 topics: time, paradox, xeraen, future, 2125, prism, synthia)
- **Command History** - Arrow key navigation through previous commands (up to 100 stored)
- **Room Navigation** - Explore zones controlled by Fracture Network factions
- **Inventory System** - Collect and manage items
- **Optimized UI** - Clean terminal-style interface with comfortable dark theme
- **Dedicated Grid Layout** - 700px output window, compact design, no page scrolling

### OBS Overlay System
- **Now Playing Overlay** - Display currently playing track for livestreams
- **PulseWire Overlay** - Show live social activity during streams
- **Grid Activity Overlay** - Stream multiplayer game activity
- **Scene Management** - Compose multiple overlay elements with positioning
- **Scene Groups** - Collections of scenes for easy switching during streams
- **Lower Thirds** - Text overlays with custom slugs and styling
- **Tickers** - Scrolling marquee text for announcements
- **Alert System** - Alert notifications via Action Cable
- **Real-time Updates** - All overlays update via WebSocket broadcasts

### Hackr Streams
- **Livestream Management** - Go live/end stream functionality for artists
- **VOD Support** - Video on demand URL storage for past streams
- **YouTube Integration** - Auto-conversion of YouTube URLs to embed format
- **Stream Timing** - Track stream start/end times with validation

### Zone Playlists
- **Ambient Music** - Per-zone background playlists for THE PULSE GRID
- **Admin Management** - CRUD interface for zone playlist configuration
- **Track Ordering** - Manual position control within zone playlists

### Multi-Domain Architecture
- Domain-specific routing and layouts (hackr.tv, xeraen.com, rockerboy.net, ashlinn.net, sectorx.media)
- Mobile-responsive TUI (Terminal User Interface) design
- Database-backed redirect system
- Artist-specific branding and theming

---

## Tech Stack

- **Frontend:** React 19, TypeScript, React Router v7, Vite
- **Backend:** Ruby 3.4.7, Rails 8.1.2, Puma
- **Database:** SQLite3 (development), Active Storage for file attachments
- **Real-time:** Action Cable 8.1 with Solid Cable adapter
- **Background Jobs:** Solid Queue for async processing
- **Caching:** Solid Cache
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

4. **Import artist/track data**
   ```bash
   bin/rails import:from_yaml
   ```

5. **Seed THE PULSE GRID world**
   ```bash
   bin/rails db:seed
   ```

6. **Start the server**
   ```bash
   bin/dev
   ```

7. **Visit the application**
   - hackr.tv Home: http://localhost:3000
   - The.CyberPul.se: http://localhost:3000/thecyberpulse
   - THE PULSE GRID: http://localhost:3000/grid
   - hackr.fm Radio: http://localhost:3000/fm/radio
   - Pulse Vault: http://localhost:3000/fm/pulse-vault
   - Playlists: http://localhost:3000/fm/playlists (requires Grid login)
   - The Codex: http://localhost:3000/codex
   - PulseWire: http://localhost:3000/wire
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
say [message]          - Chat with other players in the room
who                    - List online players
help                   - Show command reference
clear (cls)            - Clear the screen
```

**Navigation:**
- Use `/disconnect` menu item or type logout command to disconnect from THE PULSE GRID
- Arrow keys navigate through command history

**NPCs with Dialogue:**
- **Fracture Network Coordinator** (hackr.tv Broadcast Station) - Topics: mission, fracture, help, station, synthia, govcorp
- **Temporal Theorist** (XERAEN Operations Center) - Topics: time, paradox, xeraen, future, 2125, prism, synthia

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
│   │   │   ├── pages/                 # React pages (HomePage, PulseVaultPage, etc.)
│   │   │   ├── audio/                 # PlayerBar, SeekBar, QueuePanel
│   │   │   └── playlists/             # CreatePlaylistModal, AddToPlaylistDropdown
│   │   ├── contexts/
│   │   │   └── AudioContext.tsx       # Global audio player state
│   │   └── hooks/                     # useGridAuth, useAudio, useActionCable
│   ├── controllers/
│   │   ├── api/                       # JSON API for React SPA
│   │   │   ├── radio_controller.rb    # Radio stations & playlists endpoint
│   │   │   ├── playlists_controller.rb # User playlist CRUD
│   │   │   └── grid_controller.rb     # Grid game API
│   │   ├── admin/                     # Server-rendered admin CRUD
│   │   │   ├── radio_stations_controller.rb
│   │   │   ├── tracks_controller.rb
│   │   │   └── hackr_logs_controller.rb
│   │   └── application_controller.rb  # Multi-domain routing
│   ├── models/
│   │   ├── artist.rb                  # Music artists
│   │   ├── album.rb                   # Albums with cover images
│   │   ├── track.rb                   # Tracks with audio files
│   │   ├── playlist.rb                # User playlists
│   │   ├── playlist_track.rb          # Playlist tracks (join table)
│   │   ├── radio_station.rb           # Radio stations
│   │   ├── radio_station_playlist.rb  # Station playlists (join table)
│   │   ├── grid_hackr.rb              # Player accounts (owns playlists)
│   │   ├── grid_room.rb               # MUD locations
│   │   └── ...                        # Other Grid models
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
│       └── overlay_channel.rb         # OBS overlay broadcasts
├── data/                              # YAML data for import
│   ├── artists.yml                    # 14 artists
│   ├── albums.yml                     # 15 albums
│   ├── tracks.yml                     # 66+ tracks
│   └── [artist_slug]/                 # Artist-specific files
├── lib/tasks/
│   └── import.rake                    # Data import scripts
├── spec/                              # Test suite
│   ├── models/                        # Model specs (backend)
│   ├── controllers/                   # Controller specs (backend)
│   ├── components/                    # Component specs (frontend Vitest)
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
- **Backend:** 1104 examples, 0 failures (RSpec)
- **Frontend:** 129 examples (Vitest)
- **Total:** 1233 passing tests

**Tested Components:**
- **Models:** Artist, Album, Track, Playlist, PlaylistTrack, RadioStation, RadioStationPlaylist, GridHackr, GridRoom, HackrLog, Redirect, CodexEntry, Pulse, Echo
- **Controllers:** Grid, API (Radio, Playlists, PlaylistTracks, SharedPlaylists, Codex, Pulses, Echoes), Admin (RadioStations, Tracks, HackrLogs, CodexEntries, PulseWire), FM, Tracks, Pages
- **Components:** BandProfileComponent (ViewComponent), AudioPlayer, PlayerBar, SeekBar (React/Vitest)
- **Services:** Grid::CommandParser
- **Concerns:** GridAuthentication, RequestAnalysis

---

## Development

### Code Quality
```bash
bundle exec standardrb              # Lint code
bundle exec standardrb --fix        # Auto-fix issues
```

### Data Import
The import system supports YAML-based data loading with file attachments:

```bash
bin/rails import:from_yaml          # Import all data
bin/rails import:yaml_artists       # Artists only
bin/rails import:yaml_albums        # Albums only
bin/rails import:yaml_tracks        # Tracks only
```

**Features:**
- Idempotent operations (safe to re-run)
- Auto-generates release dates for TBA releases (99-100 years in future)
- Attaches cover images and audio files from artist directories
- Filters lyrics section markers (`[Chorus]`, `[Verse]`, etc.)
- Auto-assigns sequential track numbers

### Adding New Content

**Add a New Artist:**
1. Add artist to `data/artists.yml`
2. Create directory: `data/[artist-slug]/`
3. Add albums to `data/albums.yml`
4. Add tracks to `data/tracks.yml` or `data/[artist-slug]/trackz/`
5. Place audio files and cover images in `data/[artist-slug]/`
6. Run `bin/rails import:from_yaml`

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
- **artists** - name, slug, genre
- **albums** - name, slug, album_type, release_date, description, cover_image (Active Storage)
- **tracks** - title, slug, track_number, release_date, duration, featured, streaming_links (JSON), videos (JSON), lyrics, audio_file (Active Storage)
- **playlists** - name, description, is_public, share_token, belongs_to :grid_hackr
- **playlist_tracks** - position (1+), belongs_to :playlist, belongs_to :track
- **radio_stations** - name, slug, description, genre, color, stream_url, position
- **radio_station_playlists** - position (1+), belongs_to :radio_station, belongs_to :playlist

### THE PULSE GRID
- **grid_hackrs** - player accounts with bcrypt authentication (role: operative/admin), has_many :playlists
- **grid_rooms** - locations in the game world
- **grid_zones** - areas grouping rooms (faction_base, govcorp, transit)
- **grid_factions** - Fracture Network factions (The.CyberPul.se, XERAEN, GovCorp)
- **grid_exits** - directional connections between rooms
- **grid_items** - objects in rooms or inventories
- **grid_mobs** - NPCs with dialogue trees (dialogue_tree JSON column)
- **grid_messages** - chat and system messages

### Blog
- **hackr_logs** - blog posts with Markdown content, published status

### The Codex
- **codex_entries** - name, slug, entry_type (person/organization/event/location/technology/faction/item), summary, content (markdown), metadata (JSON), published, position

### PulseWire
- **pulses** - content (256 char max), parent_pulse_id, thread_root_id, echo_count, splice_count, pulsed_at, signal_dropped, belongs_to :grid_hackr
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
- Band profile pages - 13 artists with config-based routing
- Album model - Active Storage cover images with hover zoom
- Comprehensive YAML import - Idempotent, multi-document support
- hackr.fm Radio - 4 stations with live streaming
- Pulse Vault - Search/filter, click-anywhere playback, custom ordering
- Auto-play next track - Queue management with loop functionality
- THE PULSE GRID - Real-time multiplayer MUD (5 zones, 5 rooms, 2 NPCs)
- NPC dialogue system - 2 NPCs with 13 total topics
- Command history - Arrow key navigation (100 commands)
- Hackr Logs - Blog platform with Markdown support
- Comprehensive test suite - 1104 backend + 129 frontend tests (100% passing)
- The Codex wiki - 7 entry types, markdown with auto-linking, admin CRUD, public SPA
- PulseWire social network - Pulses, Echoes, Splices, real-time updates, admin moderation
- OBS Overlay system - Scenes, groups, now playing, lower thirds, tickers, alerts
- Hackr Streams - Livestream management with go live/VOD support
- Zone Playlists - Per-zone ambient music for THE PULSE GRID
- Background infrastructure - Solid Queue, Solid Cache, Solid Cable configured

### Future Enhancements
- World expansion - More rooms, NPCs, items (currently only 5 rooms)
- Faction reputation system
- Mission/quest system for THE PULSE GRID
- Hacking system (core gameplay mechanic)
- Combat mechanics (physical/cyber)
- Synthia frequency tuning mechanic
- Persistent inventory between sessions
- Upload remaining audio files (64 of 66 tracks need audio)

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
| `bin/rails import:from_yaml` | Import all YAML data (artists, albums, tracks) |
| `bundle exec rspec` | Run backend test suite (1104 tests) |
| `pnpm test` | Run frontend test suite (129 tests) |
| `bundle exec standardrb` | Lint backend code |
| `pnpm install` | Install frontend dependencies |

---

**Built for those who turn toward good, the Hackrs of CyberSpace! The future is not lost!**

*hackr.tv - Where music meets THE GRID.*
