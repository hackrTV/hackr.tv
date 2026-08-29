---
title: Admin — Overlay System
area: Admin
minutes: 25
---
# Admin — Overlays (OBS system)

Overlay CRUD in `/root` → Overlays + the public overlay pages under
`/overlays/*` + the read API consumed by the HUD app.

## Steps — dashboard + scenes

1. `/root` → Overlays. → Status hub with links (scenes, elements,
   groups, tickers, lower-thirds, alerts, now-playing).
2. Scenes index → open a scene. → Element composition with x/y/size/z;
   scene groups list membership.
3. Open the scene's public page (`/overlays/scenes/<slug>` or per its
   URL scheme). → Renders chrome-less on the overlay layout.
4. Create a TEST scene with one element placed; view it publicly; then
   delete it.

## Steps — elements + tickers + lower thirds

5. Elements index → settings JSON editor renders; a bad JSON edit
   flashes a warning instead of silently saving.
6. Tickers: edit a ticker's content (static) → its overlay page
   updates. For a dynamic ticker, push content via
   `POST /api/admin/overlay/ticker_feed` (Bearer) → content updates.
7. Lower thirds: update one → its overlay page reflects it live
   (auto-broadcast on update).

## Steps — now playing + alerts

8. Now Playing singleton: set a custom title/artist from admin. →
   `GET /api/overlay/now-playing` returns it; clearing restores
   player-driven state (the player overwrites on next track).
9. Alerts: create a TEST alert. → It appears in
   `GET /api/overlay/alerts/pending`; the alert overlay page consumes
   it (FIFO); the queue index in admin shows/destroys it.

## Steps — world feed overlay

10. `/overlays/world-feed` renders and appends live events (article 21
    step 5 — re-verify quickly here in overlay context).

## Note

The scene/element/ticker/lower-third READ API endpoints are slated for
removal once the external HUD app fully replaces native overlays —
if they're gone when you read this, steps 6's push + 8/9's reads still
apply via the admin UI + overlay pages.
