---
title: Using This Guide
area: Setup
minutes: 5
---
# Using This Guide

## What this is

A manual regression pass over the whole application. Each article covers
one feature area: what to set up, what to click/type, and what you must
see. The articles are ordered so a full run flows naturally — setup →
public site → THE PULSE GRID → admin → integrations.

## Statuses

Record one status per article when run through the wizard:

- **PASS** — every step behaved as written.
- **FAIL** — at least one step deviated. Write WHAT deviated in the notes
  (the step number and what you saw). A failed article does not block the
  run; keep going unless the failure cascades.
- **BLOCKED** — you couldn't execute the steps (missing data, env broken,
  depends on a failed area). Note the blocker.
- **SKIP** — intentionally out of scope for this run (e.g. staging-only
  integration articles during a local run).

## Ground rules

1. Test in an environment that resembles production: `bin/dev` locally or
   the staging deploy. Note which one in the run label.
2. Keep the browser console open — any red console error during a step is
   a FAIL-worthy observation even if the UI looked fine.
3. When an article says "two browsers", use a second browser or a private
   window so the sessions are truly separate.
4. The audio player is a cross-cutting invariant: if music ever STOPS
   because you navigated, that's a FAIL on `02_cross_cutting_invariants`
   no matter which article you were in.

## Steps

1. Open `/root/test_guide` as an admin. → The article ledgers render,
   one `// AREA //` per area, numbered through, with this article `[01]`.
2. Start a run (label it, e.g. "post-deploy 2026-08-28 staging") with
   `[START TEST RUN]`. → The wizard opens article 00 with `[OK] Run "…"
   started.` under the bar and a `// RECORD //` section — `// NOTES //`
   and `[PASS] [FAIL] [BLOCKED] [SKIP]` — under the article.
3. Tick a step checkbox, reload the page. → The tick persists (per-run,
   per-browser).
4. Mark this article PASS. → The wizard advances to the next article
   with `[OK] … PASS recorded.`; back on `/root/test_guide` the
   `// ACTIVE RUN //` PROGRESS row counts it and `[01]` reads PASS.
