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
├── artists.yml                # 15 artists
├── albums.yml                 # 18 albums
├── tracks.yml                 # 71 tracks
├── catalog/                   # Alternative location (checked first)
│   ├── artists.yml
│   ├── albums.yml
│   └── tracks.yml
├── system/
│   ├── hackrs.yml             # GridHackr users
│   ├── channels.yml           # Chat channels
│   ├── radio_stations.yml     # Radio stations
│   ├── zone_playlists.yml     # Ambient zone playlists
│   └── redirects.yml          # Domain redirects
├── world/
│   ├── factions.yml           # Grid factions
│   ├── zones.yml              # Grid zones
│   ├── rooms.yml              # Grid rooms
│   ├── exits.yml              # Room exits
│   ├── mobs.yml               # NPCs
│   └── items.yml              # Items
├── content/
│   ├── codex.yml              # Codex entries
│   ├── hackr_logs.yml         # Blog posts
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
├── vidz.yml                   # VODs/streams
└── radio_stations.yml         # Radio stations
```

## Import Order

Tasks run in dependency order (the `data:load` master task handles this automatically):

1. **artists** (no deps)
2. **albums** (depends on artists)
3. **tracks** (depends on albums)
4. **hackrs** (no deps)
5. **channels** (no deps)
6. **radio_stations** (no deps)
7. **zone_playlists** (depends on tracks)
8. **factions** (depends on artists)
9. **zones** (depends on factions, zone_playlists)
10. **rooms** (depends on zones)
11. **exits** (depends on rooms)
12. **mobs** (depends on rooms, factions)
13. **items** (depends on rooms)
14. **key_playlists** (depends on hackrs, tracks, radio_stations)
15. **codex** (no deps)
16. **hackr_logs** (depends on hackrs)
17. **wire** (depends on hackrs)
18. **vidz** (depends on artists)
19. **overlays** (no deps)
20. **redirects** (no deps)
21. **livestream_archive** (depends on audio)

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
| `data:catalog` | artists, albums, tracks |
| `data:system` | hackrs, channels, radio_stations, zone_playlists, redirects |
| `data:world` | factions, zones, rooms, exits, mobs, items |
| `data:playlists` | key_playlists (also ensures catalog, hackrs, radio_stations) |
| `data:content` | codex, hackr_logs, wire |
| `data:overlays` | all overlay elements, tickers, lower_thirds, scenes, scene_elements, scene_groups |

### Individual Tasks

Every data type has its own task: `data:artists`, `data:albums`, `data:tracks`, `data:hackrs`, `data:channels`, `data:radio_stations`, `data:zone_playlists`, `data:factions`, `data:zones`, `data:rooms`, `data:exits`, `data:mobs`, `data:items`, `data:key_playlists`, `data:codex`, `data:hackr_logs`, `data:wire`, `data:vidz`, `data:redirects`, `data:livestream_archive`, `data:audio`.

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

## YAML Schemas

### Artists (`data/artists.yml`)

```yaml
artists:
  - name: "The.CyberPul.se"
    slug: "thecyberpulse"
    genre: "Hackrcore"
    artist_type: "band"        # band (default), ost, or voiceover
```

**Current artists:** THE PULSE GRID, The.CyberPul.se, XERAEN, Injection Vector, Wavelength Zero, Cipher Protocol, System Rot, Temporal Blue Drift, Offline, Apex Overdrive, Voiceprint, Neon Hearts, Ethereality, heartbreak_havoc.sh, BlitzBeam+

### Albums (`data/albums.yml`)

```yaml
albums:
  - artist: "XERAEN"
    title: "XORDIUM"
    slug: "xordium"
    album_type: "ep"           # ep, lp, single
    release_date: "2124-10-17"
    description: ""
    cover_image: "xeraen/images/xordium.jpg"
```

### Tracks (`data/tracks.yml`)

```yaml
- title: "Kernel Panic"
  slug: "kernel-panic"
  artist: "The.CyberPul.se"
  album: "Hackr Nights"
  album_type: "single"
  audio_file: "kernel-panic.ogg"
  track_number: 1
  release_date: "2125-01-01"
  duration: "3:45"
  genre: "Hackrcore"
  featured: false
  streaming_links:
    spotify: "https://..."
    apple_music: "https://..."
  videos:
    music_video: "https://..."
  lyrics: |
    Lyrics here...
```

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

## Legacy Import Tasks

The `import:*` namespace (`lib/tasks/import.rake`) contains older import tasks from a previous Sinatra-based system. These are superseded by the `data:*` namespace and should not be used for new imports.

## Troubleshooting

### Error: "File not found"

Ensure the YAML files exist in the expected locations. The loader checks `data/catalog/` first, then falls back to `data/`.

### Error: "Artist not found" when loading tracks

Run `data:artists` before `data:tracks`, or use `data:catalog` which handles the order automatically.

### Invalid Date Format

Tracks with non-standard release dates (e.g., "TBA") will have `release_date` set to `nil`. This is expected.
