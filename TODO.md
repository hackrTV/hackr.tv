# TODO

**Last Updated:** 2026-01-24

This file tracks planned features, enhancements, and tasks for hackr.tv.

## High Priority

### Content & Media

- [ ] **Upload audio files** - 64 tracks missing audio (2/66 tracks have audio across 2/14 albums)
- [ ] **Add cover images** - 12 albums missing covers (2/14 albums have covers)
- [ ] **Review band bios** - Manually polish all 13 artist profile descriptions for lore accuracy
- [ ] **Missing routes/views** - Create `/streamz`, `/vidz`, `/xeraen/vidz`, `/xeraen/albums/xordium`

### The Codex - Enhancements

- [ ] **Update seed entries** - Review and correct all 7 existing entries (XERAEN, Ashlinn, The Fracture Network, GovCorp, Chronology Fracture, The Pulse Grid, PRISM) for lore accuracy
- [ ] **Expand entries** - Add all 13 bands, key Grid locations, important items, timeline events
- [ ] **Reverse references** - Show "Referenced in" section listing all places that link to each entry
- [ ] **Inline tooltips** - Hover over `[[Entry Name]]` links to see entry summary without navigation

### Technical Debt

- [x] **Remove legacy import tasks** - Deleted `import.rake` and unified catalog into per-artist YAML files
- [ ] **Update db/seeds.rb** - Delegate to `data:load` instead of individual seed files
- [ ] **Standardize JSON errors** - Normalize API error responses (`{error:}` vs `{success: false, error:}`)

## Medium Priority

### THE PULSE GRID - Game Features

- [ ] **Synthia frequency tuning** - Interactive audio puzzle system for unlocking secrets
- [ ] **Faction reputation** - Track player standing with The Fracture Network, GovCorp, and other factions
- [ ] **Mission/quest system** - Structured objectives, storylines, and rewards
- [ ] **Hacking system** - Mini-games for breaking into systems (lockpicking for cyberspace)
- [ ] **Combat system** - Turn-based or real-time mechanics for player vs NPC/player encounters
- [ ] **World expansion** - Add more rooms (currently only 5), NPCs, items, and interactive objects
- [ ] **Persistent progression** - Save player state, inventory, achievements across sessions
- [ ] **Economy system** - Credits, item trading, shops, black market

### Band Profiles

- [ ] **Expand lore** - Add more backstory and world-building to existing 13 artist profiles
- [ ] **Album showcase pages** - Artist-specific album pages with track listings and lore
- [ ] **Enhanced band configs** - Update `bandProfileConfig.tsx` with richer content per band
- [ ] **Discography timelines** - Visual timeline of releases for each artist

## Long-term / Future Ideas

### PulseWire - V2 Features

- [ ] **User follows/followers** - Social graph for filtered feeds
- [ ] **Following feed** - View pulses only from users you follow
- [ ] **@mentions with notifications** - Alert users when mentioned in pulses
- [ ] **Hashtag tracking** - Categorize and search pulses by topics
- [ ] **Media attachments** - Support micro-audio clips, micro-vids in pulses
- [ ] **Encrypted pulses** - PRISM-resistant private messaging
- [ ] **Pulse search** - Full-text search across all pulses
- [ ] **Trending threads** - Surface popular conversations
- [ ] **User blocking/muting** - Filter out unwanted users from your hotwire
- [ ] **Pulse analytics** - View reach, engagement stats for your pulses

### Platform Enhancements

- [ ] **Live streaming chat** - Real-time chat integration for concerts and events
- [ ] **Merch store** - In-universe merchandise with Grid Hackr accounts
- [ ] **Fan artwork gallery** - User-submitted art with moderation
- [ ] **Community forums** - Long-form discussion boards (complement to PulseWire)
- [ ] **Achievement/badge system** - Unlock badges for Grid exploration, music discovery, social activity
- [ ] **Mobile apps** - iOS/Android native apps for hackr.fm and THE PULSE GRID
- [ ] **Public API** - Third-party integrations with OAuth authentication
- [ ] **Podcast/interview series** - Lore-expanding audio content
- [ ] **Interactive timeline** - Visual history of THE.CYBERPUL.SE universe events

### Technical Improvements

- [ ] **Performance optimization** - Database indexing, query optimization, caching strategy
- [ ] **CDN for media** - Move audio/images to CDN for faster delivery
- [ ] **Monitoring/analytics** - Error tracking, performance monitoring, user analytics
- [ ] **Automated backups** - Database and media file backup strategy
- [ ] **CI/CD pipeline** - Automated testing and deployment
- [ ] **Security audit** - Penetration testing, vulnerability scanning

---

## Completed

### Data Architecture Consolidation (2026-01)
- [x] **Unified YAML data system** - Single source of truth with `data:load` task loading all content
- [x] **Consolidated directory structure** - `data/{catalog,world,content,system,playlists,overlays}/`
- [x] **35+ data rake tasks** - `data:load`, `data:audio`, `data:reset`, individual loaders
- [x] **Schema changes** - Added `is_seed` flag to pulses/echoes, slugs to zone_playlists/grid_rooms
- [x] **Read-only admin controllers** - Removed CRUD for seed-only content (13 controllers updated)
- [x] **Audio sideloading** - `data:audio` task supports local imports/ and S3 bucket sources
- [x] **Key playlists** - Radio station linked playlists loaded from YAML
- [x] **HackrLog refactor** - Changed `author` to `grid_hackr` association

### Security & Infrastructure (2026-01)
- [x] **CSRF protection** - Enabled with token auth bypass for API requests
- [x] **Content Security Policy** - Full CSP with nonces, Vite dev support, YouTube iframes
- [x] **Action Cable resilience** - Exponential backoff retry, connection status indicators, ReconnectingBanner component

### OBS Overlay System (2025-12)
- [x] **Overlay scenes & groups** - Fullscreen and composition scenes with element positioning
- [x] **Scene groups** - Collections of scenes for easy switching
- [x] **Now Playing overlay** - Track metadata display for livestreams
- [x] **PulseWire overlay** - Real-time social feed overlay
- [x] **Grid Activity overlay** - Multiplayer game activity feed
- [x] **Lower thirds** - Text overlays with custom slugs
- [x] **Tickers** - Scrolling marquee text
- [x] **Alert system** - Alert notifications via Action Cable

### Hackr Streams (2025-12)
- [x] **Livestream management** - Go live/end stream functionality
- [x] **VOD support** - Video on demand URL storage
- [x] **YouTube integration** - Auto-conversion of YouTube URLs to embed format

### Zone Playlists (2025-12)
- [x] **Zone ambient music** - Per-zone playlists for THE PULSE GRID
- [x] **Admin management** - CRUD interface for zone playlist configuration

### Background Jobs Infrastructure (2025-12)
- [x] **Solid Queue** - Async job processing configured and ready
- [x] **Solid Cache** - Caching layer configured
- [x] **Solid Cable** - Action Cable adapter for WebSocket support

### PulseWire Social Network (2025-11-22)
- [x] **Admin moderation** - Dashboard at `/root/pulse_wire`, signal-drop system, filters, bulk actions, 35 controller tests
- [x] **Core social features** - Pulses (256 char), Echoes (retweets), Splices (replies), Hotwire timeline
- [x] **Real-time updates** - Action Cable broadcasts for new pulses
- [x] **Profanity filtering** - Obscenity gem integration

### The Codex Wiki (2025-11-20)
- [x] **7 entry types** - People, Organizations, Events, Locations, Technology, Factions, Items
- [x] **Markdown rendering** - Full markdown support with auto-linking
- [x] **Global inline linking** - `[[Entry Name]]` syntax works everywhere
- [x] **Admin CRUD** - Full management interface
- [x] **Public SPA** - Search and filter interface

### THE PULSE GRID MUD (2025-11-15 - 2025-11-19)
- [x] **Real-time multiplayer** - Live presence tracking via Action Cable
- [x] **Account system** - Registration, login, roles (operative/admin)
- [x] **Reserved alias protection** - Profanity + reserved name filtering
- [x] **Interactive NPCs** - Dialogue trees (Fracture Coordinator, Temporal Theorist)
- [x] **14+ commands** - Movement, interaction, inventory, social, meta commands
- [x] **Command history** - Arrow key navigation (100 commands)
- [x] **5 zones, 5 rooms** - Foundation with faction-based room types
- [x] **Colorful output** - HTML syntax highlighting, terminal-style UI

### Playlists Feature (2025-11-16)
- [x] **Full CRUD** - Create, read, update, delete playlists
- [x] **Manual ordering** - Drag-and-drop track reordering
- [x] **Share tokens** - Public playlist sharing via unique URLs
- [x] **Queue panel** - Current + next 3 tracks display
- [x] **Auth-gated UI** - Requires Grid Hackr login

### React SPA Architecture (2025-11-16)
- [x] **React 19 + TypeScript** - Modern frontend stack
- [x] **React Router v7** - Client-side routing
- [x] **Persistent audio** - Playback continues across navigation
- [x] **Error boundaries** - Graceful error handling with custom 404
- [x] **Code splitting** - Lazy loading for performance
- [x] **8 custom hooks** - useGridAuth, useActionCable, useCommandHistory, usePlaylist, usePulseWire, useCodexMappings, useMobileDetect, useTerminalAccess

### hackr.fm Platform (2025-11-14)
- [x] **Radio stations** - 4 database-backed stations with admin CRUD
- [x] **Pulse Vault** - Track discovery with search/filter, keyboard shortcuts
- [x] **Bands directory** - 13 artist profiles with track counts
- [x] **Album system** - Active Storage for cover images
- [x] **Persistent audio player** - Continuous playback with queue management

### Infrastructure (2025-11-10 - 2025-11-12)
- [x] **Multi-domain routing** - hackr.tv, xeraen.com, rockerboy.net, ashlinn.net, sectorx.media
- [x] **ViewComponent** - BandProfileComponent with 3 slots
- [x] **YAML data import** - Idempotent import for artists/albums/tracks
- [x] **Hackr Logs blog** - Markdown posts with publish workflow

### Testing (Current)
- [x] **1164 RSpec tests** - Backend test coverage
- [x] **129 Vitest tests** - Frontend test coverage
- [x] **96 test files** - Comprehensive test suite
