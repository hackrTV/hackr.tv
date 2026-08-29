---
title: Admin — PulseWire + Uplink Moderation
area: Admin
minutes: 15
---
# Admin — Social Moderation

## Steps — PulseWire admin

1. `/root` → PulseWire. → Pulse moderation index (recent pulses,
   authors, drop state).
2. Drop a TEST pulse (post one as the operative first). → Public
   `/wire` shows it dropped/hidden per rules, live.
3. Restore it. → Back publicly.
4. Signal-drops view: the signal-drop queue/log renders.
5. Admin-authored pulse via API: `POST /api/admin/pulses` (Bearer). →
   Appears on `/wire` attributed correctly. Splice (thread) endpoint if
   used: spot-check per current workflow.

## Steps — uplink moderation

6. `/root` → Uplink. → Moderation surface: recent packets, punishments
   list (squelches/blackouts with issuer + expiry), moderation log.
7. The squelch/blackout/lift round-trips were exercised in article 22
   steps 9–10 — verify the moderation LOG recorded those actions with
   issuer attribution.
8. Punishments page user lookup (alias → account) works for finding a
   target quickly.
9. Drop a packet from the admin surface (vs in-chat). → Drops live in
   `/uplink`.
