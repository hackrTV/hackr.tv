---
title: Grid Meta Pages
area: The Grid
minutes: 20
---
# Grid Meta Pages (site-chrome grid views)

Six read-only pages over the same data as the tactical tabs; mutations
stay terminal commands.

## Steps

1. `/achievements` → Summary (Earned: N/M), category tabs filter
   client-side; earned achievements show awarded dates; hidden ones
   only appear if earned; cumulative triggers show live progress.
2. `/missions` → Three tabs: ACTIVE (objective progress, READY FOR
   TURN-IN badge, turn-in hint), AVAILABLE (gate warnings when unmet,
   accept hint with the giver context), COMPLETED (turn-in counts ×N
   for repeatables, completion dates). Counts in tab labels match
   content.
3. `/schematics` → Status tabs incl. READY (N); known schematics with
   material requirements.
4. `/loadout` → 13 slots with equipped items + "-- empty --" slots;
   vitals block; matches the tactical LOADOUT tab exactly.
5. `/deck` → Deck status or the "No DECK equipped." empty state;
   installed components when present.
6. `/transit` → Three browser tabs: LOCAL TRANSIT, SLIPSTREAM, REGION
   NETWORK; corridor heat indicator renders.
7. **Live refresh**: leave `/missions` open; in another tab complete a
   mission turn-in (or accept one). → The completion toast fires AND
   the missions page content refreshes itself (frame reload on the
   mission signal) — the new state appears without a manual reload.
8. All six pages require login (logged-out browser → redirect) and the
   `pulse_grid` grant (fresh account pre-grant → "will open soon").
9. Player invariant: audio keeps playing across all six.
