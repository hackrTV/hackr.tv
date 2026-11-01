---
title: Admin — Hackr Management + Economy Ops
area: Admin
minutes: 20
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

10. Grid → Economy. → Dashboard renders: money supply, cache totals,
    mint/burn stats.
11. Grid → Transactions. → Filterable ledger; find your article-38
    transfer by hash; genesis/mint/redemption types labeled.
12. **External debit round-trip**: with an admin Bearer token, run
    `curl -X POST /api/grid/debit` with `hackr_alias`, `amount`, memo.
    → 200 with tx_hash + remaining balance; the debit shows in the
    ledger and the operative's CRED tab. (Insufficient balance → clean
    422 error.)
