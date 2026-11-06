---
title: Admin — Observability (Errors, Red Flags, Analytics, World Feed)
area: Admin
minutes: 15
---
# Admin — Observability + Ops

Every screen here is a console screen (the music screens' idiom): a
bar, `[OK]` / `[ERR]` replies under it, `// RULES //`, ledgers,
`// DESTINATIONS //` and the `>` prompt. Steps 1–7 are META screens
(`ROOT · META` in the bar, `[ERRORS] [FLAGS] [ANALYTICS] [GUIDE]
[RUNS] [ROOT]` minus the screen's own); step 8's world feed is a
STREAMS screen with the streams destinations. No TuiCss window, table
or button anywhere.

## Steps — error tracking

1. `/root` → Errors (or `errors` at the prompt). → The ERRORS ledger:
   ON RECORD (count · last seen first · 50 a page), `// FILTER //`
   rows — STATUS / COMPONENT / SEVERITY as link rows (the lit one is
   the current choice, `ALL` by default; each keeps the others), a
   SEARCH box, `[FILTER]` / `[x] CLEAR` — then `// ERROR GROUPS //`
   with a dim column-key row and `[NN] · STATUS (until … under an
   ignored one) · title · COMPONENT · COUNT · 24H · FIRST SEEN · LAST
   SEEN · [RESOLVE] [IGNORE 24H]` (or `[REOPEN]` on a resolved /
   ignored group). Pick `FRONTEND` then `IGNORED`. → Both stay lit, the
   ledger narrows, the ON RECORD row says `filtered`. `[x] CLEAR` resets.
   Past 50 groups a `[<] PREV · n–m of t · [>] NEXT` pager sits under
   the ledger.
2. Generate a FRONTEND error: in a public page's console, run
   `throw new Error("test-guide probe")` inside a timeout
   (`setTimeout(() => { throw new Error("test-guide probe") })`). →
   The error reporter posts it; a new group appears (may take a
   moment).
3. Type its number at the prompt (or click the title). → The group's
   readout: the title in the bar with `ERROR #id`, `[<] ERRORS`
   (`back` at the prompt); STATUS / COMPONENT / SEVERITY /
   OCCURRENCES / FIRST SEEN / LAST SEEN / TITLE / FINGERPRINT rows;
   `// ACTIONS //` with `[RESOLVE] [IGNORE 1H] [IGNORE 24H] [IGNORE
   7D] [IGNORE FOREVER]`; `// OCCURRENCES · n //` newest first, each
   as a request line (time · @alias · ip · METHOD url) over the
   exception and message, with BACKTRACE / METADATA / PARAMS folded
   under click-to-open summaries (50 a page, pager under them).
4. `[IGNORE 1H]` on the readout. → `[OK] Error group ignored until …`
   on the SAME screen, STATUS reads `IGNORED · until …`, the actions
   row shows `[REOPEN]` and RESOLVED BY stays empty. `[REOPEN]`, then
   `[RESOLVE]`. → `[OK]` each time, RESOLVED BY names you. Back on the
   ledger, `[RESOLVE]` / `[IGNORE 24H]` on a row land back on the
   ledger with the filters you had. Clean up the probe group per
   workflow.

## Steps — RED FLAGS (data audit)

5. `/root` → Red Flags (`flags`). → The RED FLAGS screen: an `n OPEN`
   (red) or `ALL CLEAR` (green) badge in the bar, `// OPEN //` tiles
   (CRITICAL / WARNING / INFO, then GRID / MUSIC — open flags only),
   LAST SCAN (the recurring scan's time, `NEVER` on a fresh DB;
   "every 6 hours") and a `[!] RESCAN` button, `// FILTER //` (STATUS
   / SEVERITY / DOMAIN link rows, a CHECK select, SEARCH, `[FILTER]`
   / `[x] CLEAR`), then `// RED FLAGS · n //` — unnumbered rows:
   STATUS (until … or forever under an acknowledged one) · SEVERITY ·
   title over `check_name · first <when>` · DOMAIN · SUBJECT (`[>]
   EDIT` opening the flagged record's screen, or `Type#id` when it has
   none) · LAST SEEN · `[ACK 24H] [ACK 7D] [ACK FOREVER]` (or
   `[REOPEN]`). The admin nav's `[!] RED FLAGS: n open` strip matches
   the badge.
6. `[!] RESCAN`. → `[OK] Audit scan enqueued …`; LAST SCAN updates once
   the job runs (dev: a few seconds with the queue up). `[ACK 7D]` a
   flag. → `[OK] Flag acknowledged until …`, the row reads
   ACKNOWLEDGED with the date, the tiles and the nav strip drop by
   one. `[REOPEN]` it. Pick a SEVERITY and a DOMAIN. → Both stay lit
   and the count rule narrows; `[>] EDIT` on a grid flag opens the
   room / zone / mob record it names.

## Steps — analytics

7. `/root` → Analytics (`analytics`). → The ANALYTICS readout: a RANGE
   row (`7D 30D 90D ALL`, the chosen one lit — feature usage and
   sessions read it; the tutorial funnel is all-time), `// USERS //` tiles (DAU / WAU / MAU
   / TOTAL / NEW 30D / RETURNING 30D), `// REGISTRATIONS · n DAYS ·
   PEAK n //` and `// DAILY ACTIVE … //` as bar charts (one green /
   cyan column a day, the date range under each, hover a column for
   its date and count), `// TOP ROOMS //` and `// TOP TRACKS //`
   ranked, `// FEATURES //` tiles (breach attempts and success rate,
   shop buys / sells, missions accepted and the completion rate),
   `// TUTORIAL FUNNEL //` (STARTED / COMPLETED / BIGGEST DROP-OFF
   tiles over a step chart, the drop-off step red), `// SESSIONS //`
   tiles and `// TELEMETRY //` rows (perf metrics on record, web
   vitals in 24h, slow zone-map renders in 7d, frontend events
   collected). Your own session's activity from this run counts in
   DAU and DAILY ACTIVE. Click `90D`. → The page reloads with `90D`
   lit and the charts spanning 90 columns; `?range=nope` reads as 30D.

## Steps — world feed admin + settings

8. `/root` → World Feed. → A console screen: SIMULATOR ON / OFF (and
   HIDDEN while invisible) badges in the bar, `// STATUS //` tiles
   (organic rate, target, totals, simulants), `// SETTINGS //` (the
   visibility flag article 21 toggled), `// MANUAL PUBLISH //` (already
   exercised) and `// RECENT EVENTS //` (time · type · message over the
   alias · SIM / ORG) all render.

## Steps — email tracking

9. Sent-email tracking (if surfaced in admin): the auth emails from
   article 30 are recorded (SentEmail + observer). If no UI exists,
   verify via console/logs and note it.
