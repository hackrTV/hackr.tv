---
title: External Integrations — HUD, relay, synthia
area: Integrations
minutes: 30
---
# External Integrations (staging/prod only — SKIP locally)

The three external consumers of hackr.tv's APIs + cable. Run against
staging or production.

## Steps — HUD (OBS overlay app)

1. Point the HUD app at this environment; open a scene with the
   now-playing/alerts/world-events data hooks in OBS (or a browser).
2. Play a track on hackr.tv. → HUD now-playing widget data updates
   (GET now-playing + OverlayChannel push).
3. Create an overlay alert (admin). → HUD receives/displays it from
   the pending queue.
4. Trigger a world event. → HUD world-event display updates
   (WorldEventFeedChannel).

## Steps — relay (Go chat aggregator)

5. Run relay against this environment with the service-account Bearer
   token.
6. Send a packet in hackr.tv `/uplink`. → Appears in relay's unified
   terminal display (LiveChatChannel initial_packets + new_packet both
   exercised: restart relay to check history load too).
7. Send FROM relay (bridged message). → Appears in `/uplink` live,
   attributed to the service account (`/api/admin/uplink/send_packet`).

## Steps — synthia (streaming bot)

8. With synthia's hackr_tv plugin connected (`wss://…/cable`): send a
   packet in `/uplink`. → Synthia receives it (plugin log/handlers
   fire).
9. Have synthia post (command/event that sends to uplink). → Appears
   in `/uplink` from the service account.

## Steps — soak signals

10. After the integration session, check `/root` → Errors for ANY new
    groups from this window, and analytics web-vitals for regressions.
    → Clean.
