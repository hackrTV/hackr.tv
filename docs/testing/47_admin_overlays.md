---
title: Admin — Overlay Data (HUD)
area: Admin
minutes: 10
---
# Admin — Overlay Data (HUD)

OBS overlays are rendered by the external HUD app. hackr.tv keeps only
the data HUD reads: the now-playing singleton and the alert queue, plus
the read API and `OverlayChannel` pushes. (End-to-end HUD checks live in
article 50.)

## Steps — dashboard

1. `/root` → Overlays. → Status hub: Now Playing + Alerts cards, nav to
   both, and the HUD data-surface table (now-playing, alerts/pending,
   world_events, OverlayChannel, WorldEventFeedChannel).

## Steps — now playing

2. Now Playing: set a custom title/artist from admin. →
   `GET /api/overlay/now-playing` returns it ("API JSON ↗" button opens
   it); clearing restores player-driven state (the player overwrites on
   next track).
3. Pick a catalog track + Paused, save. → JSON shows the track with
   `paused: true` and an absolute `album_cover` URL.

## Steps — alerts

4. Alerts: create a TEST alert. → It appears in
   `GET /api/overlay/alerts/pending` (FIFO, expires after 10s); the
   queue index in admin shows/destroys it.

## Steps — retired surfaces stay gone

5. `/overlays/now-playing`, `/overlays/scenes/<any>`, and
   `GET /api/overlay/tickers` all 404. (The native overlay pages,
   scenes/elements/tickers/lower-thirds, and their read API were removed
   2026-10 — HUD builds scenes from its own SceneDefinitions.)
