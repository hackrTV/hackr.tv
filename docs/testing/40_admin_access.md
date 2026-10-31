---
title: Admin Access + Dashboard
area: Admin
minutes: 12
---
# Admin Access + Dashboard (/root)

## Steps

1. Logged out: visit `/root`. → Denied (login redirect / 404), never
   admin content.
2. As the OPERATIVE (non-admin): `/root`. → Denied.
3. As admin: `/root`. → The dashboard is a console screen (the music
   screens' idiom): a `ROOT · ADMIN · /root · @alias` bar with
   `[>] SITE`, `// SYSTEM //` stat tiles (ONLINE lit green when anyone
   is on the grid, ARTISTS / TRACKS / LOGS / CODEX, the three MAIL
   counts), one `// SECTION //` rule per admin section (MUSIC, CONTENT,
   STREAMS, MODERATION, WORLD, SYSTEMS, HACKRS, META) of aligned
   `[TAG] Name  description` rows, then `// RECENT TRACKS //`,
   `// RECENT LOGS //` and `// ONLINE HACKRS //` ledgers numbered
   through, `// END OF LINE //` and the `>` prompt. No TuiCss window,
   table or button anywhere on it. The nav is one thin row (the public
   menu's height) — `/root` + your alias left, the sections right,
   Dashboard lit (tab tint + cyan bar); while data-audit flags are open
   a one-line `[!] RED FLAGS: n open | [>] VIEW ALL` strip sits flush
   under it (no strip at zero flags). Scroll the dashboard. → Nav +
   strip stay pinned at the top on desktop; under 768px they scroll
   away with the page.
4. The prompt: type `artists` + Enter. → `CONNECTING /root/artists ...`
   then a full load of the artists ledger. Back on `/root`, type `?`. →
   Every `[TAG]` on screen is listed, lowercase. Type the number of a
   recent track (`01`). → Its record screen opens. Type `nope`. →
   `UNKNOWN COMMAND`.
5. The admin nav lists every section (Dashboard, Music/, Logs, Codex,
   Handbook/, Streams, PulseWire, Emotes, Uplink, Grid/, Hackrs, Meta/ —
   Errors / Red Flags / Analytics / Overlays / World Feed / Redirects /
   Test Guide — and `[<] EXIT`; no arrow glyphs anywhere in the chrome).
   Hover each dropdown (the Grid menu fits a 900px-tall window and
   scrolls when it doesn't; Meta opens inward), then click through each
   top item once. → Every index page renders without error, and the
   section you are in is lit — inside a dropdown the current entry is
   barred too (Music/ → Artists on `/root/artists`); Hackrs lights
   Hackrs, not Grid/ (deep testing follows in later articles — this is
   the reachability sweep).
6. History: on `/root/artists` open an artist's `[HISTORY]` (or any
   versioned record's). → A console screen: the record's name in the
   bar with `[<] BACK` / `[EDIT]`, a VERSIONS readout, the
   `// VERSIONS //` ledger with a dim column-key row then
   `[NN] · CREATE / UPDATE / DESTROY · SOURCE · BY · WHEN · CHANGES`
   (each changed key as `key: old > new`, old struck red, new green;
   `+N more` past eight). Edit the record, save, come back. → A new
   `[01]` UPDATE row on top naming you under BY. A mission's history
   folds its objectives / rewards in as cyan `SOURCE` rows and the
   readout counts the child changes. Type `back` at the prompt. → The
   ledger.
7. Sortable tables: on any legacy TuiCss index (one not yet on the
   console — zones, mobs …), click a column header. → Client-side sort
   works.
8. Dev-tools gate: if DEV TOOLS are enabled in this environment the
   Hackrs link shows the warning state, the dashboard bar carries a
   `DEV TOOLS ON` badge and `// HACKRS //` lists `[SANDBOX] [NPC] [PAC]`;
   with the gate off none of the three appear and opening
   `/root/grid_breach_sandbox/new` bounces to `/root` with an `[ERR] DEV
   TOOLS DISABLED` reply under the bar. Confirm the expectation matches
   the environment (ON locally, OFF in prod).
