# Data Import Guide

This document explains how to import data from the Sinatra app (`~/dev/hackr.tv`) into the Rails database.

## Prerequisites

- Ensure the Sinatra app is located at `~/dev/hackr.tv`
- Database must be created and migrated (`bin/rails db:create db:migrate`)

## Available Import Tasks

### Import Everything (Recommended)

```bash
bin/rails import:all
```

This runs all three import tasks in order: artists → tracks → redirects

### Import Artists Only

```bash
bin/rails import:artists
```

Imports the two artists:
- The.CyberPul.se (slug: `thecyberpulse`)
- XERAEN (slug: `xeraen`)

### Import Tracks Only

```bash
bin/rails import:tracks
```

Imports all track YAML files from:
- `~/dev/hackr.tv/data/thecyberpulse/trackz/*.yml`
- `~/dev/hackr.tv/data/xeraen/trackz/*.yml`

**Note:** Run `import:artists` first, or tracks will be skipped.

### Import Redirects Only

```bash
bin/rails import:redirects
```

Imports domain-based path redirects for:
- ashlinn.net redirects
- xeraen.com/xeraen.net/rockerboy.net redirects
- sectorx.media redirects

### Clear All Data (DANGEROUS)

```bash
bin/rails import:clear
```

Deletes ALL artists, tracks, and redirects from the database. Requires confirmation.

## Idempotency

All import tasks are **idempotent**, meaning:

✓ Safe to run multiple times
✓ Won't create duplicates
✓ Updates existing records if data changed
✓ Skips unchanged records

### Example Output

```
--- Importing Artists ---

  ✓ Created artist: The.CyberPul.se (thecyberpulse)
  ✓ Created artist: XERAEN (xeraen)

Artist import summary:
  Created: 2
  Updated: 0
  Total:   2

--- Importing Tracks from YAML ---

  Processing artist: The.CyberPul.se (thecyberpulse)
    ✓ Created: Kernel Panic
    ✓ Created: Hackr Nights
    ...

  Processing artist: XERAEN (xeraen)
    ✓ Created: XORDIUM
    ...

Track import summary:
  Created: 11
  Updated: 0
  Skipped: 0 (no changes)
  Errors:  0
  Total:   11

--- Importing Redirects ---

  ✓ Created: ashlinn.net/ → https://youtube.com/AshlinnSnow
  ✓ Created: xeraen.com/ → /xeraen
  ✓ Created: xeraen.com/git → https://github.com/xeraen
  ...

Redirect import summary:
  Created: 31
  Updated: 0
  Skipped: 0 (no changes)
  Total:   31
```

## Re-running Imports

If you re-run the import tasks:

```bash
bin/rails import:all
```

Output will show what already exists:

```
--- Importing Artists ---

  ✓ Artist exists: The.CyberPul.se (thecyberpulse)
  ✓ Artist exists: XERAEN (xeraen)

Artist import summary:
  Created: 0
  Updated: 0
  Total:   2
```

## Troubleshooting

### Error: "Source directory not found"

Ensure the Sinatra app is at the correct location:
```bash
ls ~/dev/hackr.tv/data
# Should show: thecyberpulse  xeraen
```

### Error: "Artist not found"

Run the artists import first:
```bash
bin/rails import:artists
```

### Invalid Date Format

Tracks with non-standard release dates (e.g., "TBA Release") will have `release_date` set to `nil`. This is expected behavior.

## Data Mappings

### Artist Names

| Slug          | Display Name      |
|---------------|-------------------|
| thecyberpulse | The.CyberPul.se   |
| xeraen        | XERAEN            |

### Track YAML Fields

| YAML Field       | Database Column   | Type    | Notes                          |
|------------------|-------------------|---------|--------------------------------|
| title            | title             | string  | Required                       |
| artist           | (from artist)     | -       | Determined by directory        |
| album            | album             | string  | Optional                       |
| album_type       | album_type        | string  | ep, lp, single, etc.           |
| release_date     | release_date      | date    | Parsed, nil if invalid         |
| duration         | duration          | string  | Format: M:SS                   |
| cover_image      | cover_image       | string  | Filename only                  |
| featured         | featured          | boolean | Default: false                 |
| streaming_links  | streaming_links   | json    | Hash of platform → URL         |
| videos           | videos            | json    | Hash of type → URL             |
| lyrics           | lyrics            | text    | Multiline string               |

### Redirect Domains

| Domain              | Paths                                    |
|---------------------|------------------------------------------|
| ashlinn.net         | / → YouTube                              |
| xeraen.com          | /, /git, /github, /twitter, /x, /youtube |
| xeraen.net          | (same as xeraen.com)                     |
| rockerboy.net       | (same as xeraen.com)                     |
| rockerboy.stream    | (same as xeraen.com)                     |
| sectorx.media       | / → /sector/x                            |

## Next Steps

After importing data:

1. **Verify the import**:
   ```bash
   bin/rails console
   > Artist.count  # Should be 2
   > Track.count   # Should be 11
   > Redirect.count # Should be ~31
   ```

2. **Start the server**:
   ```bash
   bin/rails server
   ```

3. **Visit the tracks pages**:
   - http://localhost:3000/trackz
   - http://localhost:3000/xeraen/trackz
