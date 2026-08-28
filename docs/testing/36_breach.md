---
title: BREACH
area: The Grid
minutes: 25
---
# BREACH (tactical combat)

Needs: operative with a ready deck + breach-capable software, in a room
with a breachable target (article 01 recon; encounter dialogs appear via
the room-flags strip).

## Steps — entering

1. In a room with a breach encounter, the flags strip shows the
   encounter with a start dialog. Confirm start (`breach <target>` also
   works). → The tactical view swaps to the BREACH overlay: template
   name + tier, protocol list, detection meter, PNR threshold, actions
   remaining, round number.
2. Protocol numbering is 1-based everywhere player-facing (first
   protocol = 1, and the HIGHEST-numbered protocol must be targetable —
   the historical off-by-one).

## Steps — the loop

3. **Target menus**: click a software/action button. → An anchored menu
   opens listing protocols by number/name; picking one submits the full
   command (e.g. `exec Icebreaker 3`).
4. `analyze <n>` an unrevealed protocol. → Type label reveals (???
   before analyze at level 0).
5. `exec`/attack a protocol. → Damage/state output appends to the
   BREACH log (breach output goes to the breach log, not the main
   room log); protocol state updates; actions-remaining decrements;
   round advances when spent.
6. Detection: watch the detection meter rise on noisy actions; crossing
   thresholds produces consequences per template. Puzzle-gate protocol
   types (if present in this template) demand their specific
   interaction — follow the on-screen affordances.
7. Command echo while in-breach lands in the breach log (not the main
   log).

## Steps — exits

8. Win: clear the required protocols. → Victory output, rewards
   (XP/CRED/salvage per template), overlay closes back to the normal
   tactical view, map/flags refresh.
9. Start another breach and **JACKOUT** (confirm dialog; past-PNR
   jackout has costs). → Exit applies the appropriate penalty; state
   returns to normal; vitals/CRED reflect any cost.
10. After any breach ends, the refresh bus updates bar vitals + open
    tab; `stat` agrees.
11. Reload mid-breach (browser refresh while in-breach). → Re-enters
    the breach overlay with correct state (server-side breach
    persists).
