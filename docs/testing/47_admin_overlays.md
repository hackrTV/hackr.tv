---
title: Admin — Overlay Data (HUD)
area: Admin
minutes: 10
---
# Admin — Overlay Data (HUD)

OBS overlays are rendered by the external HUD app. hackr.tv keeps only
the data HUD reads: the now-playing singleton and the alert queue, plus
the read API and `OverlayChannel` pushes. (End-to-end HUD checks live in
article 50.) Every screen here is a `/root` console screen (article 42's
idiom).

## Steps — overlays

1. `/root` → Overlays (Meta → Overlays, or `[OVERLAYS]` from any streams
   screen). → `// NOW PLAYING //` (title / artist / PLAYING or PAUSED, or
   NOTHING PLAYING), `// ALERTS //` with the pending count, and
   `// HUD DATA SURFACE //` rows (now-playing, alerts/pending,
   world_events, OverlayChannel, WorldEventFeedChannel). Type `playing`
   at the prompt. → The now-playing screen.

## Steps — now playing

2. Now Playing: set a CUSTOM TITLE / CUSTOM ARTIST, `[UPDATE &
   BROADCAST]`. → `[OK]`, `// CURRENT //` shows it;
   `GET /api/overlay/now-playing` returns it (`[>] API JSON` opens it).
   `[CLEAR NOW PLAYING]` → confirm. → NOTHING PLAYING; the player
   overwrites on its next track.
3. Pick a catalog TRACK + PAUSED, commit. → JSON shows the track with
   `paused: true` and an absolute `album_cover` URL.

## Steps — alerts

4. Alerts (`[ALERTS]`). → The queue ledger, newest 100, with a TYPE row.
   `[+] SEND ALERT`: a TEST alert with `{"x": 1}` as DATA. → `[OK]`; it
   appears in `GET /api/overlay/alerts/pending` (FIFO, expires after
   10s). Send one with `{bad` as DATA. → `[OK]` plus a `[WARN]` that the
   JSON was dropped.
5. Open an alert (its number at the prompt). → Its readout with
   `// DATA //`; `[DELETE ALERT]` → confirm removes it. `[DEL]` on a
   ledger row does the same.

## Steps — retired surfaces stay gone

6. `/overlays/now-playing`, `/overlays/scenes/<any>`, and
   `GET /api/overlay/tickers` all 404. (The native overlay pages,
   scenes/elements/tickers/lower-thirds, and their read API were removed
   2026-10 — HUD builds scenes from its own SceneDefinitions.)
