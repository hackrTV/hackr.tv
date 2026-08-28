---
title: Admin — Observability (Errors, Red Flags, Analytics, World Feed)
area: Admin
minutes: 15
---
# Admin — Observability + Ops

## Steps — error tracking

1. `/root` → Errors (error groups). → Grouped errors with counts,
   first/last seen, environment. Open a group → occurrences with
   backtrace.
2. Generate a FRONTEND error: in a public page's console, run
   `throw new Error("test-guide probe")` inside a timeout
   (`setTimeout(() => { throw new Error("test-guide probe") })`). →
   The error reporter posts it; a new group appears (may take a
   moment). Resolve/ignore controls work; clean up the test group per
   workflow.

## Steps — RED FLAGS (data audit)

3. `/root` → Red Flags. → Integrity flags dashboard; the recurring scan
   timestamp is recent (6h cadence); the admin nav banner matches the
   open-flag state.
4. Trigger a manual scan if the UI offers it (or note last-run time). →
   Completes; flags list refreshes.

## Steps — analytics

5. `/root` → Analytics. → Dashboard renders: frontend events (your
   session's page views from this run should be visible in recent
   data), web-vitals numbers populated (LCP/INP/CLS present for
   recent traffic).

## Steps — world feed admin + settings

6. `/root` → World Feed. → Event admin: simulator population state,
   visibility setting (the flag article 21 toggled), manual event
   creation (already exercised); event list renders.

## Steps — email tracking

7. Sent-email tracking (if surfaced in admin): the auth emails from
   article 30 are recorded (SentEmail + observer). If no UI exists,
   verify via console/logs and note it.
