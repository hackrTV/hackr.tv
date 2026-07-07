# Data Import Guide

This document explains how to load seed data into the Rails database from the YAML files in `data/`.

## Prerequisites

- Database must be created and migrated (`bin/rails db:create db:migrate`)

## Quick Start

```bash
bin/rails data:load
```

This loads everything in dependency order: catalog, system, world, playlists, content, vidz, overlays, and redirects.

To also sideload audio files from S3:

```bash
S3_BUCKET=your-bucket bin/rails data:load
```

## Data Architecture

All seed data lives in YAML files under `data/`, organized into layers:

```
data/
├── catalog/                   # Per-artist files (one file per artist)
│   ├── xeraen.yml             # Artist + albums + tracks
│   ├── thecyberpulse.yml
│   ├── heartbreak_havoc.yml
│   └── ...                    # 16 artist files total
├── system/
│   ├── hackrs.yml             # GridHackr users
│   ├── channels.yml           # Uplink channels
│   ├── radio_stations.yml     # Radio stations
│   ├── zone_playlists.yml     # Ambient zone playlists
│   └── redirects.yml          # Domain redirects
├── world/
│   ├── regions.yml            # Geographic regions (above zones)
│   ├── factions.yml           # Grid factions
│   ├── zones.yml              # Grid zones
│   ├── rooms.yml              # Grid rooms
│   ├── exits.yml              # Room exits
│   ├── mobs.yml               # NPCs
│   ├── item_definitions.yml   # Canonical item catalog
│   ├── items.yml              # Placed item instances
│   ├── salvage_yields.yml     # Salvage output mappings
│   ├── schematics.yml         # Fabrication recipes
│   ├── achievements.yml       # Achievement/badge definitions
│   ├── shop_listings.yml      # Shop vendor listings
│   ├── missions.yml           # Mission arcs, missions, objectives, rewards
│   ├── breach_templates.yml   # BREACH encounter templates
│   ├── breach_encounters.yml  # Placed BREACH encounters
│   ├── pac_facilities.yml     # GovCorp Perception Alignment Center facilities
│   ├── transit_types.yml      # Transit vehicle types
│   ├── transit_routes.yml     # Local transit routes + stops
│   ├── slipstream_routes.yml  # Inter-region slipstream routes + legs
│   ├── starting_rooms.yml     # Graduation starting rooms
│   └── tutorial.yml           # Bootloader tutorial world data
├── content/
│   ├── codex.yml              # Codex entries
│   ├── hackr_logs.yml         # Blog posts
│   ├── handbook.yml           # Handbook sections + articles
│   └── wire.yml               # Seed pulses/echoes
├── playlists/
│   └── key_playlists.yml      # Curated playlists
├── overlays/
│   ├── elements.yml           # Overlay elements
│   ├── tickers.yml            # Ticker overlays
│   ├── lower_thirds.yml       # Lower third overlays
│   ├── scenes.yml             # Overlay scenes
│   ├── scene_elements.yml     # Scene-element assignments
│   └── scene_groups.yml       # Scene groups
└── vidz.yml                   # VODs/streams
```

## Adding a New Track

Edit the artist's file in `data/catalog/{artist_slug}.yml` and add the track under the appropriate album:

```yaml
albums:
  - slug: album-slug
    tracks:
      - title: "New Track"
        slug: new-track
        track_number: 6
        duration: "3:45"
        audio_file: new-track.ogg
        lyrics: |
          Lyrics here...
```

That's it - one file, one edit.

## Import Order

Tasks run in dependency order (the `data:load` master task handles this automatically):

1. **catalog** — artists, albums, tracks (from per-artist files)
2. **system** — hackrs, channels, radio_stations, zone_playlists, redirects
3. **world** — seeded in dependency order:
   1. regions
   2. factions (depends on artists)
   3. zones (depends on regions, factions, zone_playlists)
   4. rooms (depends on zones)
   5. exits (depends on rooms)
   6. mobs (depends on rooms, factions)
   7. item_definitions
   8. items (depends on rooms, item_definitions)
   9. salvage_yields (depends on item_definitions)
   10. schematics (depends on item_definitions)
   11. achievements
   12. shop_listings (depends on mobs, item_definitions)
   13. missions (depends on mobs, rooms, factions, item_definitions, achievements)
   14. breach_templates → breach_encounters (depends on rooms)
   15. pac_facilities (depends on regions)
   16. transit_types → transit_routes → slipstream_routes
   17. starting_rooms
   18. tutorial
4. **playlists** — key_playlists (depends on hackrs, tracks, radio_stations)
5. **content** — codex, hackr_logs, handbook, wire
6. **vidz** — VODs/streams (depends on artists)
7. **overlays** — elements, tickers, lower_thirds, scenes, scene_elements, scene_groups
8. **redirects** — domain redirects

## Available Tasks

### Master Tasks

| Task | Description |
|------|-------------|
| `data:load` | Load everything (set `S3_BUCKET` to also load audio) |
| `data:reset` | Reset seed content only (preserves user data) |
| `data:clear` | Delete ALL data (requires typing `DELETE ALL DATA` to confirm) |

### Layer Tasks

| Task | Loads |
|------|-------|
| `data:catalog` | artists, albums, tracks (from per-artist YAML files) |
| `data:system` | hackrs, channels, radio_stations, zone_playlists, redirects |
| `data:world` | regions, factions, zones, rooms, exits, mobs, item definitions, items, salvage yields, schematics, achievements, shop listings, missions, breach templates/encounters, PAC facilities, transit types/routes, slipstream routes, starting rooms, tutorial |
| `data:playlists` | key_playlists (also ensures catalog, hackrs, radio_stations) |
| `data:content` | codex, hackr_logs, handbook, wire |
| `data:overlays` | all overlay elements, tickers, lower_thirds, scenes, scene_elements, scene_groups |

### Individual Tasks

`data:catalog`, `data:hackrs`, `data:channels`, `data:radio_stations`, `data:zone_playlists`, `data:regions`, `data:factions`, `data:zones`, `data:rooms`, `data:exits`, `data:mobs`, `data:item_definitions`, `data:items`, `data:salvage_yields`, `data:schematics`, `data:achievements`, `data:shop_listings`, `data:missions`, `data:breach_templates`, `data:breach_encounters`, `data:pac_facilities`, `data:transit_types`, `data:slipstream_routes`, `data:starting_rooms`, `data:tutorial`, `data:key_playlists`, `data:codex`, `data:hackr_logs`, `data:handbook`, `data:wire`, `data:vidz`, `data:redirects`, `data:livestream_archive`, `data:audio`.

### Audio Sideloading

```bash
# From S3
S3_BUCKET=your-bucket bin/rails data:audio

# From local imports/ directory
bin/rails data:audio
```

### Livestream Archive

```bash
bin/rails data:livestream_archive
```

Generates a playlist from all tracks that have audio files attached.

## Idempotency

All import tasks are **idempotent**:

- Safe to run multiple times
- Won't create duplicates (matched by slug)
- Updates existing records if data changed
- Skips unchanged records

## YAML Schema

Each artist has a single file at `data/catalog/{artist_slug}.yml`:

```yaml
artist:
  name: "XERAEN"
  genre: "Omniwave"
  artist_type: "band"          # band (default), ost, or voiceover

albums:
  - slug: xordium
    title: "XORDIUM"
    album_type: ep             # ep, lp, single
    release_date: "2124-10-17"
    cover_image: images/xordium.jpg
    tracks:
      - title: "XORDIUM"
        slug: xordium
        track_number: 1
        duration: "2:44"
        audio_file: xordium.ogg
        featured: false
        streaming_links:
          spotify: "https://open.spotify.com/track/..."
        lyrics: |
          Go!
```

- **Artist slug** = filename (e.g. `xeraen.yml` -> slug `xeraen`)
- **Cover images** referenced relative to `data/{artist_slug}/` (existing convention)

### Redirects (`data/system/redirects.yml`)

```yaml
redirects:
  - domain: xeraen.com
    path: /
    destination_url: /xeraen
```

**Current redirect domains:** ashlinn.net, xeraen.com, xeraen.net, rockerboy.net, rockerboy.stream, sectorx.media

## Reset vs Clear

- `data:reset` - Clears only seed content (pulses/echoes marked `is_seed`, hackr_logs, codex entries) then re-imports. Preserves user-generated content.
- `data:clear` - Nuclear option. Deletes ALL data including user-generated content. Requires typing `DELETE ALL DATA` to confirm.

## Troubleshooting

### Error: "Catalog directory not found"

Ensure the `data/catalog/` directory exists and contains per-artist YAML files.

### Error: "Artist not found" when loading dependent data

Run `data:catalog` first, or use `data:load` which handles the order automatically.

### Invalid Date Format

Tracks with non-standard release dates (e.g., "TBA") will have `release_date` set to `nil`. This is expected.
