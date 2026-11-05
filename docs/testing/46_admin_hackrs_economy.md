---
title: Admin — Hackr Management + Economy Ops
area: Admin
minutes: 25
---
# Admin — Hackrs + Economy Operations

## Steps — hackr management

1. The Hackrs link (`/root/grid_hackrs`, a console screen; `[HACKRS]`
   from the inspector's destinations). → ON RECORD (hackrs · online ·
   admin), FILTER (alias / role / room, `n / total` count, `[x] CLEAR`),
   `// HACKRS //` numbered: alias over `#id` · ROLE · CLR · XP · HP
   (green over 50, red at or under) · room · NOW (ON only for hackrs
   active in the last 15 minutes and in a room — the grid screen's
   meaning) · `[ITEMS]`. With `ADMIN_DEV_TOOLS=true` the bar reads
   `DEV TOOLS ON` and each row adds `[STATS] [WARP] [SANDBOX] [NPC]
   [PAC]`. Type a hackr's number at the prompt → the inspector.
2. Open the operative (its number, or the alias). → One readout:
   `// IDENTITY //` (alias · #id, email, role, clearance · XP,
   registered, last active, 2FA, LOGIN), `// VITALS //` (val / max ·
   %), `// LOCATION //` (the room opens its record), `// ECONOMY //`
   (CRED, cache · status, DEBT when owed, IMPOUND with `[>] IMPOUND`
   filtered to the hackr), `// BREACH //`, `// LOADOUT //` (13 slots,
   EMPTY or the item · rarity), `// INVENTORY · n / cap //`,
   `// MINING RIG //`, `// REPUTATION //`, `// MISSIONS · n ACTIVE //`
   (a number opens the assignment), `// FEATURES //`. Prompt: `back`,
   `items` (+ `stats warp rig` with dev tools). No inline colours,
   no arrow glyphs.
3. **Feature grants**: on `/root/grid` (step 11) revoke `tactical_grid`
   from the FRESH account, verify `/grid/1337` gates it; re-grant,
   verify access; the inspector's FEATURES row follows.
4. **Disable/enable login**: covered in article 30 — spot-check the
   buttons on `/root/grid` and that the inspector's LOGIN row follows.
5. **Reset TOTP** on the operative (after article 30's 2FA testing): the
   inspector's 2FA row reads ENABLED with `[RESET 2FA]` → confirm (cancel
   → nothing changes) → back on the inspector with `[OK] 2FA disabled
   for …` and 2FA `off`. → Next login is password-only; identity page
   offers fresh setup. With 2FA off there is no button.
6. **Service account toggle**: verify the relay/synthia service
   accounts are marked service accounts on `/root/grid`; toggling shows
   consequence text (don't leave changed).
7. **Items** (`[ITEMS]` / `items`, prod-safe): ON HAND `n / cap slots ·
   n equipped`. `// GRANT //`: type in the ITEM picker (name / type /
   rarity, grouped by type), pick one, QTY 2 → `[GRANT]` → `[OK]
   Granted 2x …`; `[GRANT]` with nothing picked is refused by the
   picker. `// EQUIPPED //` lists worn gear (no remove);
   `// INVENTORY //` `[REMOVE]` on the granted item → confirm → `[OK]`.
8. **Dev tools** (`ADMIN_DEV_TOOLS=true`; the inspector's
   `// DEV TOOLS //` row, each screen badged `DEV TOOLS ON`, and each
   refused to `/root` with the flag off):
   - `[STATS]`: `// STATS //` rows (HEALTH / ENERGY / PSYCHE with their
     max, CLEARANCE, XP, INSPIRATION, BONUS SLOTS, GOVCORP DEBT, ALERT
     LEVEL, CAPTURED) → change XP → `[WRITE STATS]` → confirm → `[OK]`,
     CLEARANCE follows the XP. `// RAW JSON //`: break the JSON →
     `[WRITE RAW JSON]` → `[ERR] Invalid JSON`, the text you typed
     still in the box; `[1]` → `[ERR] … must be a JSON object`; an
     empty box → `[ERR] Invalid JSON`. On an uncaptured hackr, set ALERT
     LEVEL → `[WRITE STATS]` → it sticks; on a captured one, uncheck
     CAPTURED → containment and ALERT LEVEL clear.
   - `[WARP]`: `// NOW //` shows the room (and BREACH / CAPTURED rows
     when they apply); pick a ROOM (region / zone / room) → `[WARP]` →
     confirm → the inspector with `[OK] … warped to …`. A hackr in a
     BREACH → `[ERR]`, not moved.
   - `[RIG]` (only when the hackr has a rig): `// RIG //` state /
     functional / rate / last tick / PROBLEM rows, `[FORCE ACTIVATE]` /
     `[DEACTIVATE]` (each confirms — they never did before);
     `// SLOTS //` (MOTHERBOARD reads INF); `// FORCE INSTALL //` a
     loose component → `[OK]`, it moves to `// COMPONENTS //`;
     `[UNINSTALL]` → confirm → back in the inventory.
9. **Testers** (`ADMIN_DEV_TOOLS=true`; `[SANDBOX] [NPC] [PAC]` from
   the inspector — prefilled with the hackr — or from any hackrs
   screen's destinations, which open on an empty HACKR picker):
   - `[SANDBOX]`: HACKR (with its DECK row; none / FRIED reads red) +
     TEMPLATE pickers (grouped by tier, drafts tagged) → `[START
     SANDBOX]` → confirm → the terminal: HACKR / VS rows, `[ABORT]`,
     `// TERMINAL //` opening on the full breach render, the screen's
     own `>` input (`[EXECUTE]`, up / down for history; no page
     prompt). Run `status`, then `abort`: the input gives way to
     `[END] SANDBOX BREACH ENDED` with `[<] INSPECTOR` / `[+] NEW
     SANDBOX`, and `[ABORT]` goes. No HACKR → `[ERR] Hackr is
     required.`; no DECK → `[ERR] …: No DECK equipped.` with the
     TEMPLATE still picked. `?hackr_id=` of an unknown hackr 404s (all
     three testers).
   - `[NPC]` (also the mobs ledger's `[TEST]`, prefilled with the mob):
     HACKR + MOB pickers → `[START DIALOGUE TEST]` → confirm → the
     terminal (TALKING TO row, `[SEND]`); `talk` / `ask` reply in the
     pane; `[END SESSION]` → confirm → the inspector with `[OK]`, the
     hackr back in the original room.
   - `[PAC]`: HACKR picker (CAPTURED / IN BREACH tagged in the
     options), the hackr's ROOM, OPTIONS IMPOUND → `[CAPTURE INTO
     PAC]` → confirm → the terminal (`[EXECUTE]`); escape the facility
     and the bar lights `ESCAPED`; `[END TEST]` → confirm → `[OK]`,
     restored. A region without a PAC facility → `[ERR] No PAC
     facility …`.

## Steps — grid dashboard + broadcast

10. `/root/grid` (a console screen; `[GRID]` from any moderation
   screen): `// BROADCAST //`, type a TEST line, `[BROADCAST]` →
   confirm. → `[OK]`; both grid sessions (terminal + tactical) see the
   system line live, and `// RECENT MESSAGES //` ends on it as
   `[SYSTEM]`. An empty broadcast → `[ERR]`.
11. `// ONLINE //` lists who is active in a room right now; `// HACKRS //`
   lists every account with ROLE / CLR / XP / GRID / LOGIN / NOW (NOW
   is ON only for the ONLINE ledger's hackrs — active in the last 15
   minutes and in a room; an idle hackr with a room reads OFF). On the
   FRESH account: `[GRANT]` → confirm → `[OK]`, GRID reads GRANTED and
   the button turns `[REVOKE]`; revoke it again. `[DISABLE]` /
   `[ENABLE]` and `[SVC]` / `[x] SVC` confirm first (don't leave them
   changed); your own row has no `[DISABLE]`. A hackr's number at the
   prompt opens the inspector (step 2).

## Steps — economy

12. `/root/grid_economy` (a console screen; `[ECONOMY]` from any
    systems screen). → `// SUPPLY //` tiles: TOTAL SUPPLY, HALVING,
    MINING POOL and GAMEPLAY POOL (each over `OF <its total>`), MINED,
    AWARDED, BURNED, REDEEMED. `// ABUSE FLAGS //` appears only when one
    registration IP is behind more than one active rig. `// CACHES //`
    lists every cache (system caches read `[SYSTEM]`, balance right-
    aligned); `// MINING RIGS //` the active rigs (rate, multiplier,
    parts, last tick, registration IP); `// TRANSACTIONS · NEWEST 100 //`
    ends on `[>] EVERY TRANSACTION`.
13. `[TRANSACTIONS]` (or the bar's `[>] TRANSACTIONS`). → Newest first,
    100 a page; FROM / TO read the hackr's alias over the cache address
    (`[GENESIS]` / `[BURN]` … for system caches). `// FILTER //`: click
    a TYPE (it lights; the other filters stay), type your alias in HACKR,
    set FROM / TO to today, a memo word in MEMO → `[FILTER]`. → Only
    matching rows, ON RECORD says "filtered"; find your article-38
    transfer by its hash. An unknown alias reads `NO HACKR NAMED '…'`;
    `[x] CLEAR` resets. Past 100 rows, `[<] PREV · n–m of t · [>] NEXT`
    pages and keeps the filters.
14. **External debit round-trip**: with an admin Bearer token, run
    `curl -X POST /api/grid/debit` with `hackr_alias`, `amount`, memo.
    → 200 with tx_hash + remaining balance; the debit shows in the
    ledger and the operative's CRED tab. (Insufficient balance → clean
    422 error.)
15. `[IMPOUND]` (`/root/grid_impound_records`). → Newest 200 records:
    `#id` · hackr (opens the inspector) · breach · STATUS (IMPOUNDED red
    / RECOVERED / FORFEITED) · bribe · items · created. HACKR filter +
    STATUS links (each keeps the other). With `ADMIN_DEV_TOOLS=true` the
    bar reads `DEV TOOLS ON` and an impounded row carries `[RECOVER]` /
    `[FORFEIT]`: each asks first (cancel → nothing changes); accept
    `[RECOVER]` on a TEST record → `[OK]`, STATUS RECOVERED, the items
    back in the hackr's inventory, no CRED charged. Without dev tools
    neither button shows.
