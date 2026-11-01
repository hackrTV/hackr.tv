---
title: Admin — Grid World (Regions, Zones, Rooms, Mobs, Exits, Transit, Map Editor)
area: Admin
minutes: 35
---
# Admin — Grid World Building

World data is live-operational — create TEST records in an out-of-the-way
zone and clean up after.

Every screen here except the map editor is a `/root` console screen
(article 42's idiom): the bar, `[OK]` / `[ERR]` replies under it,
ledgers, `// DESTINATIONS //` (REGIONS ZONES ROOMS EXITS MOBS STARTS
FACTIONS TRANSIT ROUTES JOURNEYS SLIPSTREAM MAP EXPORT + ROOT) and the
`>` prompt, whose commands are those tags plus the ledger's numbers. A
record IS its edit screen: `/root/grid_<thing>/:id` redirects there,
saves stay on it, and `[DELETE …]` lives only on the record (it
confirms first).

## Steps — browse hierarchy

1. `/root` → Regions. → `// REGIONS //` numbered (17 on the seeded
   world), each with its zone count, `[MAP]` `[HISTORY]`. Type a number
   at the prompt. → The region record: NAME / SLUG, `// DESCRIPTION //`,
   `// GOVCORP ROOMS //` (six typed pickers — restorepoint, containment,
   cell block, sally port, the two facility exits), `// ZONES //`
   numbered with faction + DANGER, `[+] NEW ZONE`.
2. Click into a GOVCORP ROOMS picker, type part of a room name. → A
   dropdown grouped `region / zone` lists the region's rooms; arrow keys
   + Enter pick one (the box turns green, "Room selected"). Don't save
   unless the value was already wrong. A rejected save (a room outside
   the region) shows its error in red on that picker's own row.
3. Zones (`[ZONES]`). → 178 rows, a FILTER row (name / slug / region /
   faction / playlist; the count reads `shown / total`). A zone record
   lists its `// ROOMS //` and `[+] NEW ROOM` (prefilled with the zone);
   `[>] <REGION>` in the bar opens the region.
4. Rooms (`[ROOMS]`). → ~2,100 rows numbered `[0001]`…, FILTER by name /
   slug / zone / region / type (typing stays responsive). With a filter
   applied, a hidden row's number at the prompt reads `UNKNOWN COMMAND`
   and `?` lists only the shown rows. A room record
   shows `// EXITS //` (direction, destination, LOCKED / OPEN, `[+] NEW
   EXIT` from this room) and `// MOBS //`, numbered through.
5. `[HISTORY]` on a room. → The HISTORY console renders its versions.

## Steps — rooms + exits

6. Create a TEST room in a quiet zone from that zone's `[+] NEW ROOM`.
   → ZONE is prefilled; the SLUG follows the NAME as you type until you
   edit it by hand. `[CREATE ROOM]` → `[OK]` on the new record; it
   appears in the zone's `// ROOMS //`.
7. From the room's `[+] NEW EXIT`, connect it to a neighbor (FROM is
   prefilled; DIRECTION offers the compass words, and diagonals or named
   ways type in as-is) + the return exit from the neighbor. → In-game:
   walk into the room with the operative, `look` shows your test
   description.
8. Exits (`[EXITS]`). → ~5,900 rows `[NNNN]` from > DIRECTION > to, a
   FILTER row (room / zone / direction / "locked"). An exit record's bar
   reads `from > DIRECTION > to` with `[>] FROM` / `[>] TO`.
9. Edit the room description; `look` again in-game → updated.

## Steps — map editor

10. `[MAP]` (any world screen) → the isometric editor loads for a
    region; zones render as diamond tiles. (Not a console screen — its
    own chrome.)
11. Move the TEST room's coordinates in the editor. → The tactical map
    (player side) shows it at the new position after a command refresh.
12. Verify editor edits persist across reload.

## Steps — mobs

13. Mobs (`[MOBS]`). → FILTER row (name / type / room / zone / faction),
    each row `zone / room` under the name, TYPE, FACTION; `[TEST]` (the
    NPC tester) only while `ADMIN_DEV_TOOLS=true`.
14. `[+] NEW MOB`: a TEST NPC in the test room (ROOM picker) with a small
    dialogue tree — `// DIALOGUE TREE //` GREETING, `[+] ADD TOPIC`, a
    keyword + response, `[+] SUB` for a follow-up topic. `[RAW JSON]`
    shows the tree as JSON; `[STRUCTURED]` rebuilds the rows from it (bad
    JSON reads "Invalid JSON: …" and stays raw; so does `[CREATE MOB]` /
    `[SAVE MOB]` pressed while raw JSON is bad — nothing posts, the edit
    stays in the box). `[CREATE MOB]`. → `[OK]`
    on the record with the tree as built. In-game the NPC appears in the
    room; the tactical NPC panel shows the greeting and topic; `ask TEST
    about <topic>` answers.
15. `[^] UPLOAD AVATAR` (square image) → `[SAVE MOB]`. → The avatar
    shows in the art column and the panel; `[x] REMOVE AVATAR` (confirms)
    purges it.
16. Set TYPE to Vendor and save. → `// SHOP LISTINGS //` + `// ADD
    LISTING //` appear. `// VENDOR CONFIG //` SHOP TYPE Black Market shows
    the ROTATION row. Add a listing (item, base price, stock blank =
    unlimited, clearance). → `[OK]`; the row reads PRICE / SELL (half) /
    STOCK `INF` / ACTIVE; `[x]` removes it (confirms). Vendor handle
    appears in the room; the buy flow works against it.

## Steps — starting rooms, factions, transit

17. Starting rooms (`[STARTS]`). → Spawn points in graduation order (POS,
    LIVE / OFF). A start record's ROOM picker refuses `[SAVE START]`
    while empty ("Select a room first"). Don't change production values.
18. Factions (`[FACTIONS]`). → `// FACTIONS //` + `// REP LINKS //` —
    the whole graph as one form (source · target · weight rows plus three
    blank ones). A faction record reads SHIFTS / SHIFTED BY. Don't save
    the graph unless you mean to (a cleared row deletes its link).
19. Transit types (`[TRANSIT]`), routes (`[ROUTES]`), slipstream
    (`[SLIPSTREAM]`). → A route record holds `// STOPS //` in order with
    `[x]` per stop and `// ADD STOP //` (a picker over the region's
    transit rooms); a slipstream record holds `// LEGS //` with each
    leg's fork options; a type record lists the routes that run it.
20. Journeys (`[JOURNEYS]`). → The newest 100, STATE / TYPE rows (each
    keeps the other). Type a number → the journey readout. With
    `ADMIN_DEV_TOOLS=true` an active journey shows `[ABANDON]` /
    `[FORCE ABANDON]` (confirms; the hackr returns to the origin room).
21. Grid → Impound / Rep Log (`[IMPOUND]` / `[REPLOG]`, systems
    screens). → Read-only ledgers render with data.

## Cleanup

22. Delete the TEST mob (its record's `[DELETE MOB]`), the exits (each
    exit record), then the room. → In-game the room is unreachable
    again; no orphan errors in the zone map. A room with mobs or items, a
    zone with rooms, a region with zones refuse with `[ERR]`.
