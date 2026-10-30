---
title: Admin Access + Dashboard
area: Admin
minutes: 10
---
# Admin Access + Dashboard (/root)

## Steps

1. Logged out: visit `/root`. → Denied (login redirect / 404), never
   admin content.
2. As the OPERATIVE (non-admin): `/root`. → Denied.
3. As admin: `/root`. → Dashboard renders: status overview + links into
   each section. The nav is one thin row (the public menu's height) —
   `/root` + your alias left, the sections right; while data-audit flags
   are open a one-line RED FLAGS strip sits flush under it (no strip at
   zero flags).
4. The admin nav lists every section (Dashboard, Music dropdown, Logs,
   Codex, Handbook dropdown, Streams, PulseWire, Emotes, Uplink, Grid
   dropdown, Hackrs, Meta dropdown — Errors / Red Flags / Analytics /
   Overlays / World Feed / Redirects / Test Guide — and ← Exit). Hover
   each dropdown (the Grid menu fits a 900px-tall window and scrolls
   when it doesn't), then click through each top item once. → Every
   index page renders without error (deep testing follows in later
   articles — this is the reachability sweep).
5. Sortable tables: on any large index, click a column header. →
   Client-side sort works.
6. Dev-tools gate: if DEV TOOLS are enabled in this environment the
   Hackrs link shows the warning state; confirm the expectation matches
   the environment (ON locally, OFF in prod).
