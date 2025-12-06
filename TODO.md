# TODO

**Last Updated:** 2025-12-06

This file tracks planned features, enhancements, and tasks for hackr.tv. Items move from this list to the "Completed" section in CLAUDE.md once implemented.

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

## Medium Priority

### THE PULSE GRID - Game Features

- [ ] **Synthia frequency tuning** - Interactive audio puzzle system for unlocking secrets
- [ ] **Faction reputation** - Track player standing with The Fracture Network, GovCorp, and other factions
- [ ] **Mission/quest system** - Structured objectives, storylines, and rewards
- [ ] **Hacking system** - Mini-games for breaking into systems (lockpicking for cyberspace)
- [ ] **Combat system** - Turn-based or real-time mechanics for player vs NPC/player encounters
- [ ] **World expansion** - Add more zones, rooms, NPCs, items, and interactive objects
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

- [ ] **Live streaming** - Concerts, events, DJ sets with chat integration
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
- [ ] **Background jobs** - Async processing for heavy tasks (Sidekiq/Solid Queue)
- [ ] **Monitoring/analytics** - Error tracking, performance monitoring, user analytics
- [ ] **Automated backups** - Database and media file backup strategy
- [ ] **CI/CD pipeline** - Automated testing and deployment
- [ ] **Security audit** - Penetration testing, vulnerability scanning

## Completed

See CLAUDE.md "Development Roadmap - ✅ Completed" section for full implementation history.

**Recent completions:**
- [x] **PulseWire admin moderation (2025-11-22)** - Complete admin interface: moderation dashboard (`/root/pulse_wire`), SignalDrop management, filters (status/user/content/date), bulk actions (signal-drop/delete), 35 controller tests passing. PulseWire is now 100% complete!
- [x] **PulseWire social network (2025-11-22)** - Core implementation: Pulses/Echoes models, full REST API, real-time Action Cable updates, React SPA (7 components: Hotwire, UserPulses, SinglePulse, PulseComposer, PulseCard, ThreadView, EchoButton), TUI styling with glitch effects, 14 seed pulses, 42 model tests passing.
- [x] **Global inline linking (2025-11-20)** - `[[Entry Name]]` syntax works everywhere with canonical name lookup
- [x] **The Codex wiki (2025-11-20)** - 7 entry types, markdown with auto-linking, admin CRUD, public SPA with search/filter
- [x] **Playlists feature (2025-11-16)** - Full CRUD, manual ordering, share tokens, queue panel, auth-gated UI
- [x] **React SPA migration (2025-11-16)** - Persistent audio, zero auto-scroll, error boundaries, code splitting
- [x] **THE PULSE GRID colorful output (2025-11-19)** - HTML syntax highlighting, optimized UI, auto-focus
- [x] **THE PULSE GRID MUD (2025-11-15)** - Playable alpha with NPCs, real-time multiplayer, command history
- [x] **hackr.fm platform (2025-11-14)** - Radio, Pulse Vault, Bands directory, album system with Active Storage
- [x] **Multi-domain routing (2025-11-10)** - Artist domains redirect to hackr.tv with preserved paths
- [x] **ViewComponent infrastructure (2025-11-12)** - BandProfileComponent with 3 slots, 4 band profile pages
- [x] **Data import system (2025-11-11)** - YAML-based idempotent import for artists/albums/tracks
