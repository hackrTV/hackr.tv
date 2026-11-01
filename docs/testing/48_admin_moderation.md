---
title: Admin — PulseWire + Uplink Moderation
area: Admin
minutes: 20
---
# Admin — Social Moderation

Every screen here is a `/root` console screen (article 42's idiom): the
bar, `[OK]` / `[ERR]` replies under it, `// FILTER //` rows, ledgers,
`// DESTINATIONS //` (WIRE DROPS UPLINK PACKETS PUNISH MODLOG GRID +
ROOT) and the `>` prompt, whose commands are those tags.

## Steps — PulseWire admin

1. `/root` → PulseWire (or `[WIRE]` from any moderation screen). → ON
   RECORD (count, dropped), `// FILTER //` (STATUS ALL / ACTIVE /
   DROPPED, HACKR, SEARCH, FROM / TO), `// PULSES //` numbered newest
   first: content over `@alias` (SPLICE, DROPPED + when), echo / splice
   counts, pulsed time, `[>] VIEW` `[DROP]` / `[RESTORE]` `[DEL]`. Type a
   pulse number at the prompt. → The pulse on the public WIRE.
2. Filter by HACKR + a STATUS, then click another STATUS. → The HACKR /
   SEARCH / dates stay; `[FILTER]` keeps the STATUS; `[x] CLEAR` resets.
3. Drop a TEST pulse (post one as the operative first): `[DROP]` →
   confirm. → `[OK]`; public `/wire` shows it dropped/hidden per rules,
   live.
4. `[RESTORE]` it. → `[OK]`; back publicly.
5. Bulk: tick two pulses (or SELECT ALL — the count updates, the bulk
   buttons enable). `[DROP SELECTED]` → confirm. → `[OK]` "Pulse-dropped
   2 pulses." `[DELETE SELECTED]` is permanent — try it on throwaway
   pulses only.
6. Drops (`[DROPS]`). → `// DROPPED //` with when each was dropped,
   `[RESTORE]` and `[DEL]` (both confirm).
7. Admin-authored pulse via API: `POST /api/admin/pulses` (Bearer). →
   Appears on `/wire` attributed correctly. Splice (thread) endpoint if
   used: spot-check per current workflow.

## Steps — uplink moderation

8. `/root` → Uplink. → Channels grouped as the `/uplink` sidebar draws
   them (one `// <CATEGORY> · N CHANNELS //` rule per group, numbered
   through), then `// IN FORCE //` (active punishments with `[LIFT]`),
   `// RECENT PACKETS //` (last 20) and `// RECENT ACTIVITY //` (last 10
   log entries). Channel controls: article 22.
9. The squelch/blackout/lift round-trips were exercised in article 22
   steps 9–10 — Moderation log (`[MODLOG]`): verify the log recorded
   those actions with issuer attribution. Filter by ACTION + ACTOR /
   TARGET; `[x] CLEAR` resets.
10. Punishments (`[PUNISH]`): `// ISSUE //` takes HACKR (alias, `@`
    optional), MINUTES (blank = permanent) and REASON; `[SQUELCH]` /
    `[BLACKOUT]` issue that type, each after its own confirm (cancel
    one: nothing is issued). → `[OK]` and the row under
    `// PUNISHMENTS //`. An unknown alias → `[ERR]` "User '…' not
    found." STATUS and TYPE rows combine (ACTIVE + BLACKOUT). `[LIFT]`
    on an active row ends it.
11. Packets (`[PACKETS]`): filter by CHANNEL / STATUS / HACKR / SEARCH.
    `[DROP]` a packet → confirm. → `[OK]`; it drops live in `/uplink`
    and the log gains a DROP PACKET entry. `[RESTORE]` brings it back;
    `[DEL]` deletes for good.

## Steps — grid dashboard

12. Grid (`[GRID]`) — broadcast, online hackrs, grid access: article 46
    steps 8–9.
