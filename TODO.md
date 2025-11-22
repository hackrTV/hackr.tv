# TODO

**Last Updated:** 2025-11-20

This file tracks planned features, enhancements, and tasks for hackr.tv. Items move from this list to the "Completed" section in CLAUDE.md once implemented.

## High Priority

### The Codex - Future Enhancements

- [ ] **Update codex seed entries** - Review and correct all 7 seed entries (XERAEN, Ashlinn, The Fracture Network, GovCorp, Chronology Fracture, The Pulse Grid, PRISM) with accurate lore information
- [ ] **Reverse references** - Show "Referenced in" section on Codex entries listing all places that link to them
- [ ] **Inline tooltips** - Hover over Codex links to see entry summary in a tooltip
- [ ] **More entries** - Expand to cover all bands, Grid locations, key items, and timeline events

### Content & Media

- [ ] Upload audio files for all 66 tracks (currently 30 tracks have audio across 6 albums)
- [ ] Add cover images for all 14 albums (currently 4 albums have covers)
- [ ] Manually review and polish all band profile bios
- [ ] Create missing routes/views: `/streamz`, `/vidz`, `/xeraen/vidz`, `/xeraen/albums/xordium`

## Medium Priority

### THE PULSE GRID - Game Features

- [ ] **Synthia frequency tuning** - Interactive audio puzzle system
- [ ] **Faction reputation system** - Track player standing with The Fracture Network, GovCorp, and other factions
- [ ] **Mission/quest system** - Structured objectives and storylines
- [ ] **Hacking system** - Mini-games for breaking into systems
- [ ] **Combat system** - Turn-based or real-time combat mechanics
- [ ] **World expansion** - Add more zones, rooms, NPCs, and items
- [ ] **Persistent progression** - Save player state, inventory, and achievements

### Band Profiles

- [ ] Add more lore and backstory to existing band profiles (all 13 artists have pages)
- [ ] Create artist-specific album showcase pages
- [ ] Enhance bandProfileConfig.tsx with more detailed content for each band

## Long-term / Ideas

### PulseWire - In-World Social Network

**Status:** ✅ Core Implementation Complete (~85%)

A micro-broadcast social network for GridHackr users functioning like Twitter/X within THE.CYBERPUL.SE universe.

**Core Features (Implemented):**
- [x] Pulse model (256 char posts with threading)
- [x] Echo system (rebroadcasts with toggle)
- [x] Splice threading (replies with parent/root tracking)
- [x] Hotwire timeline (global feed with infinite scroll)
- [x] Real-time updates via Action Cable
- [x] SignalDrop moderation system (data model + API)
- [x] User pulse history pages (`/wire/:username`)
- [x] Single pulse/thread view (`/wire/pulse/:id`)

**Implementation Completed:**
1. [x] Generate models/migrations (Pulse, Echo) - 42 model tests passing
2. [x] Model validations + associations + tests
3. [ ] Admin CRUD (Root::PulseWireController) - TODO
4. [x] API endpoints (PulsesController, EchoesController) - Full REST + WebSocket
5. [x] Action Cable setup (PulseWireChannel) - Real-time broadcasts
6. [x] React components (HotwirePage, PulseComposer, PulseCard, ThreadView, EchoButton, UserPulsesPage, SinglePulsePage)
7. [x] Real-time subscription hookup (usePulseWire hook)
8. [x] TUI styling with glitch effects (pulse_wire.css)
9. [x] Seed sample pulses (14 pulses, 13 echoes, 5 hackrs, 1 thread)
10. [x] Model tests (42 examples, 0 failures)

### Future PulseWire Enhancements

- [ ] User follows/followers
- [ ] Filtered feeds (following only)
- [ ] @mentions with notifications
- [ ] Hashtag/topic tracking
- [ ] Media attachments (micro-audio, micro-vids)
- [ ] Encrypted pulses (PRISM-resistant)
- [ ] Pulse search
- [ ] Trending threads
- [ ] User blocking/muting

### Other Ideas

- [ ] Live streaming integration for concerts/events
- [ ] Merch store integration
- [ ] Fan artwork gallery
- [ ] Community forums or discussion boards
- [ ] Achievement/badge system for Grid hackrs
- [ ] Mobile apps (iOS/Android)
- [ ] API for third-party integrations

## Completed

See CLAUDE.md "Development Roadmap - ✅ Completed" section for full implementation history.

**Recent completions:**
- [x] **PulseWire social network (2025-11-22)** - Core implementation: Pulses/Echoes models, API controllers, real-time via Action Cable, full React SPA (7 components), TUI styling, seed data, 42 model tests passing. Admin UI pending.
- [x] Global inline linking with canonical names (2025-11-20) - `[[Entry Name]]` syntax works everywhere with database lookup for display names
- [x] The Codex wiki (2025-11-20)
- [x] Playlists feature (2025-11-16)
- [x] React SPA migration (2025-11-16)
- [x] THE PULSE GRID colorful output (2025-11-19)
