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
   each section; the RED FLAGS banner strip renders (empty or with
   current flags).
4. The admin nav lists every section (Music, Logs, Codex, Handbook,
   Streams, PulseWire, Uplink, Grid dropdown, Hackrs, Ops dropdown,
   Overlays, World Feed, Redirects). Click through each top item once.
   → Every index page renders without error (deep testing follows in
   later articles — this is the reachability sweep).
5. Sortable tables: on any large index, click a column header. →
   Client-side sort works.
6. Dev-tools gate: if DEV TOOLS are enabled in this environment the
   Hackrs link shows the warning state; confirm the expectation matches
   the environment (ON locally, OFF in prod).
