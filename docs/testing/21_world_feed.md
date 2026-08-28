---
title: World Event Feed
area: Social & Comms
minutes: 5
---
# World Event Feed (/feed)

## Steps

1. Check the visibility flag first: `/root` → World Feed settings. If
   the feed is hidden, `/feed` should show its hidden/closed state to
   the public — verify, then enable it for the rest.
2. Visit `/feed`. → Event stream renders (population simulator output +
   real events), newest first, styled lines.
3. Leave it open; in the grid terminal (other browser) unlock an
   achievement or trigger a public event (level up, mission complete).
   → The event line appends LIVE without a reload.
4. Admin push: `/root` → World Feed → create a manual event (or
   `POST /api/admin/world_events` with the Bearer token). → Appears
   live in the open `/feed`.
5. The OBS overlay variant `/overlays/world-feed` renders the same
   stream (chrome-less, overlay layout) and also appends live.
6. `GET /api/world_events` returns recent events as JSON (feeds the
   HUD app).
