---
title: Grid Terminal (/grid)
area: The Grid
minutes: 20
---
# Grid Terminal (/grid)

The classic terminal surface. Operative account, tutorial completed.

## Steps — gate + basics

1. Visit `/grid` WITHOUT the `pulse_grid` grant (fresh account). →
   Coming-soon gate, not the game.
2. As the operative: `/grid`. → Welcome block + current room description
   (inline look) + command input with focus.
3. `help` → command list renders. `look` → room re-described.
4. Movement: `north` / `n` etc. toward a known adjacent room, and `go
   <exit>`. → Room description updates via stream swap (no full
   reload); blocked directions give a clear error.
5. `say hello grid` with the second browser's operative... (use admin's
   hackr or a second account in the same room). → Both see the line;
   the OTHER session sees the speaker attribution; moving away/in
   produces arrive/depart lines with correct perspective ("X arrives
   from the south").
6. `take <item>` / `drop <item>` on a room item. → Inventory changes
   (`inventory` / `i` confirms); room contents update for BOTH
   sessions.
7. `examine <item>` / `inspect`. → Detail text.
8. `who` → online hackrs. `stat`/`stats` → vitals/XP block.

## Steps — terminal chrome

9. Command history: press ↑/↓. → Cycles previous commands; persists
   across a page reload (sessionStorage).
10. `clear` → output clears client-side (no server round-trip error).
11. Type an unknown command `frobnicate`. → Graceful "unknown command"
    line, echoed input.
12. Navigate away to `/vault` and back. → Terminal reloads cleanly;
    player never stopped (invariant).

## Steps — achievements inline

13. Trigger any achievement via gameplay (or admin-award while in
    `/grid`). → Toast appears AND the terminal output shows the inline
    ACHIEVEMENT UNLOCKED block on your next command where applicable.
