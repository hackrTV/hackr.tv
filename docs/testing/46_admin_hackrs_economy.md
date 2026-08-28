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

## Steps — broadcast

8. Grid dashboard → system broadcast: send a TEST broadcast. → Both
   grid sessions (terminal + tactical) see the system line live.

## Steps — economy

9. Grid → Economy. → Dashboard renders: money supply, cache totals,
   mint/burn stats.
10. Grid → Transactions. → Filterable ledger; find your article-38
    transfer by hash; genesis/mint/redemption types labeled.
11. **External debit round-trip**: with an admin Bearer token, run
    `curl -X POST /api/grid/debit` with `hackr_alias`, `amount`, memo.
    → 200 with tx_hash + remaining balance; the debit shows in the
    ledger and the operative's CRED tab. (Insufficient balance → clean
    422 error.)
