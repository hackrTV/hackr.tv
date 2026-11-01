---
title: Admin — Hackr Management + Economy Ops
area: Admin
minutes: 25
---
# Admin — Hackrs + Economy Operations

## Steps — hackr management

1. Grid → Hackrs (or the top-level Hackrs link). → Account list with
   roles, activity, disabled state.
2. Open the operative. → Detail: stats, feature grants, caches,
   sessions/security.
3. **Feature grants**: revoke `tactical_grid` from the FRESH account,
   verify `/grid/1337` gates it; re-grant, verify access.
4. **Disable/enable login**: covered in article 30 — spot-check the
   buttons exist and history logs the actions.
5. **Reset TOTP** on the operative (after article 30's 2FA testing). →
   Next login is password-only; identity page offers fresh setup.
6. **Service account toggle**: verify the relay/synthia service
   accounts are marked service accounts; toggling shows consequence
   text (don't leave changed).
7. Dev tools (if enabled locally): the dev command panel on a hackr
   (xp/cred/item grants) works and logs.

## Steps — grid dashboard + broadcast

8. `/root/grid` (a console screen; `[GRID]` from any moderation
   screen): `// BROADCAST //`, type a TEST line, `[BROADCAST]` →
   confirm. → `[OK]`; both grid sessions (terminal + tactical) see the
   system line live, and `// RECENT MESSAGES //` ends on it as
   `[SYSTEM]`. An empty broadcast → `[ERR]`.
9. `// ONLINE //` lists who is active in a room right now; `// HACKRS //`
   lists every account with ROLE / CLR / XP / GRID / LOGIN / NOW (NOW
   is ON only for the ONLINE ledger's hackrs — active in the last 15
   minutes and in a room; an idle hackr with a room reads OFF). On the
   FRESH account: `[GRANT]` → confirm → `[OK]`, GRID reads GRANTED and
   the button turns `[REVOKE]`; revoke it again. `[DISABLE]` /
   `[ENABLE]` and `[SVC]` / `[x] SVC` confirm first (don't leave them
   changed); your own row has no `[DISABLE]`. A hackr's number at the
   prompt opens the inspector (step 2).

## Steps — economy

10. `/root/grid_economy` (a console screen; `[ECONOMY]` from any
    systems screen). → `// SUPPLY //` tiles: TOTAL SUPPLY, HALVING,
    MINING POOL and GAMEPLAY POOL (each over `OF <its total>`), MINED,
    AWARDED, BURNED, REDEEMED. `// ABUSE FLAGS //` appears only when one
    registration IP is behind more than one active rig. `// CACHES //`
    lists every cache (system caches read `[SYSTEM]`, balance right-
    aligned); `// MINING RIGS //` the active rigs (rate, multiplier,
    parts, last tick, registration IP); `// TRANSACTIONS · NEWEST 100 //`
    ends on `[>] EVERY TRANSACTION`.
11. `[TRANSACTIONS]` (or the bar's `[>] TRANSACTIONS`). → Newest first,
    100 a page; FROM / TO read the hackr's alias over the cache address
    (`[GENESIS]` / `[BURN]` … for system caches). `// FILTER //`: click
    a TYPE (it lights; the other filters stay), type your alias in HACKR,
    set FROM / TO to today, a memo word in MEMO → `[FILTER]`. → Only
    matching rows, ON RECORD says "filtered"; find your article-38
    transfer by its hash. An unknown alias reads `NO HACKR NAMED '…'`;
    `[x] CLEAR` resets. Past 100 rows, `[<] PREV · n–m of t · [>] NEXT`
    pages and keeps the filters.
12. **External debit round-trip**: with an admin Bearer token, run
    `curl -X POST /api/grid/debit` with `hackr_alias`, `amount`, memo.
    → 200 with tx_hash + remaining balance; the debit shows in the
    ledger and the operative's CRED tab. (Insufficient balance → clean
    422 error.)
13. `[IMPOUND]` (`/root/grid_impound_records`). → Newest 200 records:
    `#id` · hackr (opens the inspector) · breach · STATUS (IMPOUNDED red
    / RECOVERED / FORFEITED) · bribe · items · created. HACKR filter +
    STATUS links (each keeps the other). With `ADMIN_DEV_TOOLS=true` the
    bar reads `DEV TOOLS ON` and an impounded row carries `[RECOVER]` /
    `[FORFEIT]`: each asks first (cancel → nothing changes); accept
    `[RECOVER]` on a TEST record → `[OK]`, STATUS RECOVERED, the items
    back in the hackr's inventory, no CRED charged. Without dev tools
    neither button shows.
