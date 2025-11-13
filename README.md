# hackr.tv

> A Ruby on Rails music artist showcase platform and text-based MUD game set in a dystopian cyberpunk universe.

**hackr.tv** is a multi-domain music streaming and discovery platform featuring **THE PULSE GRID** - a playable multiplayer MUD (Multi-User Dungeon) set in 2125. Explore the resistance movement through music, lore, and interactive gameplay.

[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.0.3-red.svg)](https://rubyonrails.org/)
[![Tests](https://img.shields.io/badge/Tests-271%20passing-brightgreen.svg)](#testing)
[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)

---

## 🎵 Features

### hackr.fm Music Platform
- **Radio Streaming** - Live web radio with multiple stations (The.CyberPul.se, XERAEN, Sector X Underground, GovCorp Official)
- **Pulse Vault** - Music discovery interface with 66+ tracks, real-time search/filtering, and full-featured HTML5 audio player
- **Auto-play & Playlists** - Automatic track progression with loop functionality
- **Album Art** - Cover image display with hover zoom overlay
- **Bands Directory** - Artist profiles with track counts and genre information

### THE PULSE GRID - MUD Game
- **Real-time Multiplayer** - Live chat and movement tracking via Action Cable
- **Interactive NPCs** - Rich dialogue trees with lore-heavy conversations
- **Command History** - Arrow key navigation through previous commands
- **Room Navigation** - Explore zones controlled by resistance factions
- **Inventory System** - Collect and manage items
- **Optimized UI** - Clean terminal-style interface with comfortable dark theme

### Multi-Domain Architecture
- Domain-specific routing and layouts (hackr.tv, xeraen.com, rockerboy.net, ashlinn.net, sectorx.media)
- Mobile-responsive TUI (Terminal User Interface) design
- Database-backed redirect system
- Artist-specific branding and theming

---

## 🛠 Tech Stack

- **Backend:** Ruby 3.4.7, Rails 8.0.3, Puma
- **Database:** SQLite3 (development), Active Storage for file attachments
- **Real-time:** Action Cable with Solid Cable adapter
- **Testing:** RSpec, FactoryBot, Faker
- **Code Quality:** StandardRB
- **Assets:** Propshaft, TuiCSS (terminal UI framework)
- **Authentication:** bcrypt for password hashing

---

## 🚀 Getting Started

### Prerequisites
- Ruby 3.4.7
- Bundler
- SQLite3

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/hackrTV/hackr.tv.git
   cd hackr.tv
   ```

2. **Install dependencies**
   ```bash
   bundle install
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
   bin/rails server
   ```

7. **Visit the application**
   - Main site: http://localhost:3000
   - THE PULSE GRID: http://localhost:3000/grid
   - hackr.fm Radio: http://localhost:3000/fm/radio
   - Pulse Vault: http://localhost:3000/fm/pulse_vault

---

## 🎮 Playing THE PULSE GRID

**Default Login Credentials:**
- Username: `XERAEN`
- Password: `hackthefuture`

**Available Commands:**
```
look (l)              - Examine your surroundings
go [direction]        - Move in a direction (north, south, east, west, up, down)
inventory (inv, i)    - Check your items
take [item]           - Pick up an item
drop [item]           - Drop an item
examine [item]        - Inspect an item closely
talk [npc]            - Initiate conversation with an NPC
ask [npc] about [topic] - Ask an NPC about a specific topic
say [message]         - Chat with other players in the room
who                   - List online players
help                  - Show command reference
clear (cls)           - Clear the screen
```

**NPCs with Dialogue:**
- **Resistance Coordinator** (hackr.tv Broadcast Station) - Topics: mission, resistance, help, station, synthia, govcorp
- **Temporal Theorist** (XERAEN Operations Center) - Topics: time, paradox, xeraen, future, 2125, prism, synthia

---

## 📁 Project Structure

```
hackr.tv/
├── app/
│   ├── controllers/
│   │   ├── fm_controller.rb           # hackr.fm music platform
│   │   ├── grid_controller.rb         # THE PULSE GRID MUD
│   │   ├── tracks_controller.rb       # Track showcases
│   │   └── admin/                     # Admin CRUD
│   ├── models/
│   │   ├── artist.rb                  # Music artists
│   │   ├── album.rb                   # Albums with cover images
│   │   ├── track.rb                   # Tracks with audio files
│   │   ├── grid_hackr.rb              # Player accounts
│   │   ├── grid_room.rb               # MUD locations
│   │   └── ...                        # Other Grid models
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── default*.html.erb      # Main site layouts
│   │   │   ├── xeraen*.html.erb       # XERAEN artist layouts
│   │   │   ├── fm.html.erb            # hackr.fm layout
│   │   │   └── grid.html.erb          # THE PULSE GRID layout
│   │   ├── fm/                        # Music platform views
│   │   └── grid/                      # MUD game views
│   └── channels/
│       └── grid_channel.rb            # Real-time multiplayer
├── data/                              # YAML data for import
│   ├── artists.yml                    # 13 artists
│   ├── albums.yml                     # Album metadata
│   ├── tracks.yml                     # 66+ tracks
│   └── [artist_slug]/                 # Artist-specific files
├── lib/tasks/
│   └── import.rake                    # Data import scripts
├── spec/                              # RSpec test suite (271 examples)
└── config/
    ├── routes.rb                      # Multi-domain routing
    └── radio_stations.yml             # Radio station config
```

---

## 🧪 Testing

Run the full test suite:
```bash
bundle exec rspec
```

Run specific test files:
```bash
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
bundle exec rspec spec/services/
```

**Test Coverage:**
- 271 examples, 0 failures
- Models: Artist, Album, Track, GridHackr, GridRoom, HackrLog, Redirect
- Controllers: Grid, FM, Tracks, Pages, HackrLogs
- Services: Grid::CommandParser
- Concerns: GridAuthentication, RequestAnalysis

---

## 🔧 Development

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
5. Place audio files in `data/[artist-slug]/`
6. Run `bin/rails import:from_yaml`

**Add a Radio Station:**
1. Edit `config/radio_stations.yml`
2. Add station metadata (name, slug, description, stream_url)
3. Restart server

---

## 🎨 Design System

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

## 📊 Database Schema

### Music Platform
- **artists** - name, slug, genre
- **albums** - name, slug, album_type, release_date, description, cover_image (Active Storage)
- **tracks** - title, slug, track_number, release_date, duration, featured, streaming_links (JSON), videos (JSON), lyrics, audio_file (Active Storage)

### THE PULSE GRID
- **grid_hackrs** - player accounts with bcrypt authentication
- **grid_rooms** - locations in the game world
- **grid_zones** - areas grouping rooms (faction_base, govcorp, transit)
- **grid_factions** - resistance factions (The.CyberPul.se, XERAEN, GovCorp)
- **grid_exits** - directional connections between rooms
- **grid_items** - objects in rooms or inventories
- **grid_mobs** - NPCs with dialogue trees
- **grid_messages** - chat and system messages

---

## 🌐 Multi-Domain Setup

**Supported Domains:**
- `hackr.tv` - Main site
- `xeraen.com`, `xeraen.net`, `rockerboy.net`, `rockerboy.stream` - XERAEN artist domains
- `ashlinn.net` - Ashlinn redirect
- `sectorx.media` - Sector X
- `cyberpul.se`, `the.cyberpul.se` - The.CyberPul.se

**Domain Logic:**
1. Database-backed redirects (domain + path → destination)
2. Domain-specific redirects (artist domains → hackr.tv/artist)
3. Automatic mobile detection and layout selection

---

## 🎯 Roadmap

### Completed ✅
- [x] Album model with Active Storage cover images
- [x] Comprehensive YAML import system
- [x] hackr.fm Radio with 4 stations
- [x] Pulse Vault music player with search/filter
- [x] Auto-play next track with loop
- [x] THE PULSE GRID real-time multiplayer
- [x] NPC dialogue system
- [x] Command history navigation
- [x] Album cover hover overlay
- [x] Click-anywhere row playback

### In Progress 🚧
- [ ] Faction reputation system
- [ ] Mission/quest system
- [ ] Hacking system
- [ ] Combat mechanics
- [ ] Synthia frequency tuning mechanic

### Future Enhancements 🔮
- [ ] Shuffle mode
- [ ] User playlists
- [ ] Previous/Skip buttons in player
- [ ] Band profile pages with expanded bios
- [ ] More zones and rooms for THE PULSE GRID
- [ ] Persistent inventory between sessions

---

## 📝 License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

See [UNLICENSE](UNLICENSE) for details.

---

## 🤝 Contributing

This project is released into the public domain, so feel free to fork, modify, and use it however you like. If you have an idea for a feature or improvement that would be cool to have merged into the primary codebase, let's discuss in the Issues section!

---

## ⚡ Quick Reference

| Command | Description |
|---------|-------------|
| `bin/rails server` | Start development server |
| `bin/rails console` | Interactive Rails console |
| `bin/rails db:migrate` | Run database migrations |
| `bin/rails import:from_yaml` | Import all YAML data |
| `bundle exec rspec` | Run test suite |
| `bundle exec standardrb` | Lint code |

---

**Built with ❤️ for those who turn toward good, the Hackrs of CyberSpace! The future is not lost!**

*hackr.tv - Where music meets THE GRID.*
