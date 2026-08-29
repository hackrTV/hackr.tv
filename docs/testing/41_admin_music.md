---
title: Admin — Music Catalog
area: Admin
minutes: 20
---
# Admin — Artists, Releases, Tracks, Radio

Most catalog data is YAML-seeded (`data/` + `rails data:load`) with
admin read/edit on top. Test what the UI offers; note read-only areas.

## Steps — artists

1. `/root` → Artists. → Index with types (band/ost). Open one. →
   Detail with releases/tracks.
2. Edit a non-critical field (e.g. genre) and save. → Persists; history
   (PaperTrail) records the change where a History view exists.

## Steps — releases + tracks

3. Releases index → open a release. → Cover present, tracks ordered;
   coming_soon flag visible.
4. Tracks index → open a track. → Audio attachment state, vault
   visibility (`show_in_pulse_vault`), duration, slug.
5. Toggle a track's vault visibility, verify on `/vault` (appears/
   disappears), then RESTORE the original value.

## Steps — radio

6. Radio (stations) index. → Stations with playlists. Edit a station's
   playlist assignment; verify `/fm/radio` reflects it; restore.
7. Redirects (nav → Redirects): create a test redirect, hit the source
   path in the public site → lands on the target; delete the test
   redirect.

## Cleanup

Restore anything you changed; note irreversible edits in the run notes.
