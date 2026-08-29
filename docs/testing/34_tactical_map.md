---
title: Tactical Zone Map
area: The Grid
minutes: 15
---
# Tactical Zone Map

## Steps

1. On `/grid/1337`, locate the isometric zone map. → Current room
   highlighted; visited rooms rendered; unvisited areas fogged
   (fog-of-war from room visits).
2. **Click-to-move**: click an adjacent visited room. → Movement
   command fires; room + map update; the clicked room becomes current.
3. **Pan + zoom**: drag to pan, wheel/buttons to zoom, then run any
   command. → The map fragment refresh PRESERVES your pan/zoom (no
   snap-back).
4. **Phantom rooms**: at a zone edge, neighboring-zone rooms render as
   ghosts (dimmed, with zone name). Click a phantom adjacent to your
   room. → You cross zones; the map re-centers on the new zone.
   Non-adjacent phantoms are not clickable.
5. **Presence badges**: with the second account in the same zone, its
   room shows a presence badge; move it (other browser) → the badge
   moves live (ZoneChannel) without a full map reload.
6. Room names/labels never block clicks (labels are click-through).
7. Diagonals: if the zone has NE/SW-style exits, click-move works on
   them too.
8. After moving several rooms, `look` output, map position, and the
   room-flags strip all agree about where you are.
