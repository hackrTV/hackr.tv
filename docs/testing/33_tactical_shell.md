---
title: Tactical Shell + Status Tabs
area: The Grid
minutes: 20
---
# Tactical Grid Shell (/grid/1337)

Operative with `tactical_grid`. This is the primary play surface.

## Steps — gate + shell

1. Without `tactical_grid` (fresh account): `/grid/1337`. → Coming-soon
   gate.
2. As operative: `/grid/1337`. → Fixed-grid layout: top bar (clearance
   CL badge + compact vitals), zone map, room/output log, command
   input, status-tab rail, room-flags strip (context handles for
   vendor/NPC/rest/transit when present in the room).
3. The top-bar ADMIN link (admin account only) goes to `/root` as a
   full load (cross-layout).

## Steps — status tabs (8)

4. Open each tab once: DECK, STATS, LOADOUT, INVENTORY, REP, CRED,
   MISSIONS, SCHEMATICS. → Each lazy-loads its frame on first open
   (network tab shows the fetch only when opened); content matches the
   operative's actual state:
   - DECK: equipped deck + components, or the no-deck empty state.
   - STATS: vitals, XP/clearance, counters.
   - LOADOUT: 13 slots, equipped items, empty slots marked.
   - INVENTORY: grouped by type in fixed order (GEAR, CONSUMABLES,
     TOOLS, SOFTWARE, MODULES, FIRMWARE, MATERIALS, DATA, RIG
     COMPONENTS, FIXTURES, COLLECTIBLES, FACTION), capacity bar,
     per-item action buttons (equip/use/drop/salvage per type;
     unicorns never salvageable).
   - REP: faction standings with tiers.
   - CRED: balance + recent transactions.
   - MISSIONS: active with objective progress; available nearby.
   - SCHEMATICS: known schematics with READY state counts.
5. **Refresh bus**: with INVENTORY open, run `take`/`drop` in the
   command input. → The visible tab refreshes itself after the command
   (no manual reload); switch to CRED, `buy` something → CRED tab
   refreshes.

## Steps — command input parity

6. Terminal input works identically here: history ↑/↓, `clear`, echo,
   unknown-command handling.
7. Inventory item buttons post the real commands: click EQUIP on a gear
   item. → Output line confirms; LOADOUT tab reflects it.
