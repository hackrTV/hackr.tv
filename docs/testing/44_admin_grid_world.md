---
title: Admin — Grid World (Regions, Zones, Rooms, Mobs, Exits, Map Editor)
area: Admin
minutes: 30
---
# Admin — Grid World Building

World data is live-operational — create TEST records in an out-of-the-way
zone and clean up after.

## Steps — browse hierarchy

1. Grid → Regions / Zones / Rooms. → Hierarchy browsable; counts sane
   (17 regions / 178 zones / 2100+ rooms scale); room detail shows
   exits, mobs, items, ambient playlist.
2. History on a room. → PaperTrail versions render.

## Steps — rooms + exits

3. Create a TEST room in a quiet zone. → Appears in the zone's room
   list.
4. Create an exit connecting it to a neighbor (Grid → Exits or via the
   room form) + the return exit. → In-game: walk into the room with
   the operative (it's reachable), `look` shows your test description.
5. Edit the room description; `look` again in-game → updated.

## Steps — map editor

6. Grid → Map Editor. → Isometric editor loads for a region; zones
   render as diamond tiles.
7. Move the TEST room's coordinates in the editor. → The tactical map
   (player side) shows it at the new position after a command refresh.
8. Verify editor edits persist across reload.

## Steps — mobs

9. Grid → Mobs: create a TEST NPC in the test room with a small
   dialogue tree (greeting + one topic) — no listings. → In-game the
   NPC appears in the room; the tactical NPC panel shows the greeting
   and topic; `ask TEST about <topic>` answers.
10. Attach an avatar image to the mob. → Panel shows it; purge avatar
    works.
11. Add a shop listing to the TEST mob (vendor). → Vendor handle
    appears in the room; buy flow works against it.

## Steps — starting rooms + impound + rep log

12. Grid → Starting Rooms. → Configured spawn points list; edit form
    works (don't change production values).
13. Grid → Impound / Rep Log. → Read-only ledgers render with data.

## Cleanup

14. Delete the TEST mob, exits, then the room. → In-game the room is
    unreachable again; no orphan errors in the zone map.
